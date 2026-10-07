// English Comment: Main assistant screen featuring robust text cleaning for LaTeX wrapper tags and proper markdown rendering.
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:share_plus/share_plus.dart';

import 'chat_cloud_sync.dart';
import 'chat_session.dart';

class AiAssistantScreen extends StatefulWidget {
  final bool isEmbedded;

  const AiAssistantScreen({super.key, this.isEmbedded = false});

  @override
  State<AiAssistantScreen> createState() => AiAssistantScreenState();
}

class AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatSession> _sessions = [];
  int _currentSessionIndex = 0;
  bool _isLoading = false;
  XFile? _selectedImage;
  // A PDF or text file attached to the next message: {name, mime, bytes}. Kept in memory only.
  Map<String, dynamic>? _attachedFile;
  static const List<String> _fileExtensions = [
    'pdf', 'txt', 'md', 'csv', 'json', 'html', 'xml', 'c', 'cpp', 'h', 'java', 'py', 'js', 'dart', 'sql',
  ];
  static const int _maxFileBytes = 8 * 1024 * 1024; // 8 MB

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ImagePicker _picker = ImagePicker();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    // Gemini style: every time the assistant opens, show a fresh empty chat,
    // and bring the saved conversations into the history drawer.
    _createNewChatInternal();
    _loadSavedHistory().then((_) => _syncWithCloud());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  static const String _prefsKey = 'ai_chat_sessions';
  static const String _pendingDeletesKey = 'ai_chat_pending_deletes';

  // Chat ids this screen changed / removed. Saving merges only these into storage, so the
  // assistant tab and the assistant bottom sheet never overwrite each other's chats.
  final Set<String> _dirtyIds = {}; // changed here: save locally and push to the cloud
  final Set<String> _cachedIds = {}; // pulled from the cloud: save locally only
  final Set<String> _deletedIds = {}; // deleted here
  final Set<String> _removeLocalIds = {}; // deleted on another device
  bool _clearAllRequested = false;
  bool _syncing = false;

  // Called by the bottom tab bar each time the user opens the assistant tab.
  void openFreshChat() {
    setState(() => _createNewChatInternal());
    _refreshHistory();
  }

  void _touch(ChatSession s) {
    s.updatedAt = DateTime.now().millisecondsSinceEpoch;
    _dirtyIds.add(s.id);
  }

  // Reads chats saved on this device. Empty chats are never kept.
  Future<List<ChatSession>> _readStoredSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? dataString = prefs.getString(_prefsKey);
      if (dataString == null) return [];
      final List decoded = jsonDecode(dataString);
      return decoded
          .map((item) => ChatSession.fromJson(item))
          .where((s) => s.messages.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // Adds chats we don't have yet and takes newer copies of ones we have, newest first.
  // The chat that is open stays open.
  void _mergeStored(
    List<ChatSession> incoming, {
    Set<String> cloudDeleted = const {},
    bool cache = false,
  }) {
    final ChatSession? openChat =
        _sessions.isNotEmpty ? _sessions[_currentSessionIndex] : null;

    if (cloudDeleted.isNotEmpty) {
      _sessions.removeWhere((s) => cloudDeleted.contains(s.id) && !_dirtyIds.contains(s.id));
      _removeLocalIds.addAll(cloudDeleted);
    }

    final byId = {for (final s in _sessions) s.id: s};
    for (final s in incoming) {
      if (_deletedIds.contains(s.id) || _removeLocalIds.contains(s.id)) continue;
      final existing = byId[s.id];
      if (existing == null) {
        _sessions.add(s);
        byId[s.id] = s;
        if (cache) _cachedIds.add(s.id);
      } else if (s.updatedAt > existing.updatedAt && !_dirtyIds.contains(s.id)) {
        existing.replaceWith(s);
        if (cache) _cachedIds.add(s.id);
      }
    }
    _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (openChat != null && _sessions.contains(openChat)) {
      _currentSessionIndex = _sessions.indexOf(openChat);
    } else {
      _createNewChatInternal();
    }
  }

  Future<void> _loadSavedHistory() async {
    final stored = await _readStoredSessions();
    if (!mounted) return;
    setState(() => _mergeStored(stored));
  }

  // Called when the history drawer opens: pick up chats saved by other screens / devices.
  Future<void> _refreshHistory() async {
    final stored = await _readStoredSessions();
    if (!mounted) return;
    setState(() => _mergeStored(stored));
    _syncWithCloud();
  }

  Future<void> _saveLocal() async {
    try {
      final stored = _clearAllRequested ? <ChatSession>[] : await _readStoredSessions();
      final Map<String, ChatSession> byId = {for (final s in stored) s.id: s};
      for (final id in _deletedIds) {
        byId.remove(id);
      }
      for (final id in _removeLocalIds) {
        byId.remove(id);
      }
      for (final s in _sessions) {
        final changed = _dirtyIds.contains(s.id) || _cachedIds.contains(s.id);
        if (changed && s.messages.isNotEmpty) {
          byId[s.id] = s;
        }
      }
      final merged = byId.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(merged.map((s) => s.toJson()).toList()));
      _clearAllRequested = false;
    } catch (_) {}
  }

  Future<void> _saveSessionsToPrefs() async {
    await _saveLocal();
    await _pushToCloud();
  }

  // Best effort: when offline this fails quietly and the next sync catches up.
  Future<void> _pushToCloud() async {
    if (ChatCloudSync.userId == null) return;
    try {
      final dirty = _sessions
          .where((s) => _dirtyIds.contains(s.id) && s.messages.isNotEmpty)
          .toList();
      if (dirty.isNotEmpty) await ChatCloudSync.upsert(dirty);
      await _flushPendingDeletes();
    } catch (_) {}
  }

  Future<void> _queueDeletes(Iterable<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_pendingDeletesKey) ?? [];
      await prefs.setStringList(_pendingDeletesKey, {...current, ...ids}.toList());
    } catch (_) {}
  }

  // Throws when offline, so the delete stays queued and is retried at the next sync.
  Future<void> _flushPendingDeletes() async {
    if (ChatCloudSync.userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_pendingDeletesKey) ?? [];
    if (ids.isEmpty) return;
    await ChatCloudSync.markDeleted(ids);
    await prefs.remove(_pendingDeletesKey);
  }

  Future<void> _syncWithCloud() async {
    if (_syncing || ChatCloudSync.userId == null) return;
    _syncing = true;
    try {
      await _flushPendingDeletes();
      final rows = await ChatCloudSync.fetchAll();
      if (!mounted) return;

      final cloudUpdated = <String, int>{};
      final cloudDeleted = <String>{};
      final incoming = <ChatSession>[];
      for (final r in rows) {
        final id = r['id'] as String;
        cloudUpdated[id] = (r['updated_at'] as num?)?.toInt() ?? 0;
        if (r['deleted'] == true) {
          cloudDeleted.add(id);
        } else {
          final s = ChatSession.fromCloudRow(r);
          if (s.messages.isNotEmpty) incoming.add(s);
        }
      }

      // Chats the cloud doesn't have (made offline) or has an older copy of go up.
      final toPush = _sessions.where((s) {
        if (s.messages.isEmpty || cloudDeleted.contains(s.id) || _deletedIds.contains(s.id)) {
          return false;
        }
        final cloudTime = cloudUpdated[s.id];
        return cloudTime == null || s.updatedAt > cloudTime;
      }).toList();
      if (toPush.isNotEmpty) await ChatCloudSync.upsert(toPush);

      setState(() => _mergeStored(incoming, cloudDeleted: cloudDeleted, cache: true));
      await _saveLocal();
    } catch (_) {
      // Offline or not logged in: local history still works.
    } finally {
      _syncing = false;
    }
  }

  void _createNewChatInternal() {
    // Already on an empty chat? Reuse it instead of piling up blank chats.
    final emptyIndex = _sessions.indexWhere((s) => s.messages.isEmpty);
    if (emptyIndex >= 0) {
      _currentSessionIndex = emptyIndex;
      _selectedImage = null;
      _attachedFile = null;
      return;
    }
    final newSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Chat',
      messages: [],
    );
    _sessions.insert(0, newSession);
    _currentSessionIndex = 0;
    _selectedImage = null;
    _attachedFile = null;
  }

  void _createNewChat() {
    setState(() {
      _createNewChatInternal();
    });
    _scrollToBottom();
  }

  void _deleteChat(int index) {
    final removedId = _sessions[index].id;
    setState(() {
      final removed = _sessions.removeAt(index);
      _deletedIds.add(removed.id);
      _dirtyIds.remove(removed.id);
      if (_sessions.isEmpty) {
        _createNewChatInternal();
      } else if (index < _currentSessionIndex) {
        _currentSessionIndex--;
      } else if (index == _currentSessionIndex) {
        _currentSessionIndex = 0;
      }
      if (_currentSessionIndex >= _sessions.length) {
        _currentSessionIndex = _sessions.length - 1;
      }
    });
    _queueDeletes([removedId]).then((_) => _saveSessionsToPrefs());
    _scrollToBottom();
  }

  Future<void> _clearCloudChats() async {
    try {
      await ChatCloudSync.markAllDeleted();
    } catch (_) {}
  }

  void _clearAllChats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Chats'),
        content: const Text('Are you sure you want to delete all chat history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final allIds = _sessions.map((s) => s.id).toList();
              _deletedIds.addAll(allIds);
              _queueDeletes(allIds);
              _clearCloudChats();
              setState(() {
                _sessions.clear();
                _dirtyIds.clear();
                _clearAllRequested = true;
                _createNewChatInternal();
              });
              _saveSessionsToPrefs();
              _scrollToBottom();
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {},
        onError: (val) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _messageController.text = val.recognizedWords;
            _messageController.selection = TextSelection.fromPosition(
              TextPosition(offset: _messageController.text.length),
            );
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
          _attachedFile = null;
        });
      }
    } catch (_) {}
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // English Comment: Attach a PDF or text/code file. The AI reads its content together with your question.
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _fileExtensions,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final Uint8List? bytes = file.bytes;
      if (bytes == null) {
        _showMessage('Could not read this file.');
        return;
      }
      if (bytes.length > _maxFileBytes) {
        _showMessage('This file is too large. The limit is 8 MB.');
        return;
      }
      setState(() {
        _attachedFile = {
          'name': file.name,
          'mime': (file.extension ?? '').toLowerCase() == 'pdf' ? 'application/pdf' : 'text/plain',
          'bytes': bytes,
        };
        _selectedImage = null;
      });
    } catch (e) {
      debugPrint('File pick failed: $e');
      _showMessage('Could not attach this file.');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Attach a file (PDF or text)'),
                subtitle: const Text('PDF, TXT, MD, CSV, code files. Max 8 MB'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(int index) {
    final controller = TextEditingController(text: _sessions[index].title);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Chat'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter new title'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty) {
                  setState(() {
                    _sessions[index].title = newTitle;
                  });
                  _touch(_sessions[index]);
                  _saveSessionsToPrefs();
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
    );
  }

  Widget _buildSafeImage(XFile xFile, {double? height, double? width, BoxFit? fit}) {
    return FutureBuilder<Uint8List>(
      future: xFile.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            height: height,
            width: width,
            fit: fit ?? BoxFit.cover,
          );
        }
        if (snapshot.hasError) {
          // Old chats on web: the picked image file no longer exists after a reload.
          return Container(
            height: height ?? 50,
            width: width ?? 50,
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey)),
          );
        }
        return Container(
          height: height ?? 50,
          width: width ?? 50,
          color: Colors.grey[300],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }

  // English Comment: Sanitizes raw text and formats LaTeX math blocks safely without breaking Bengali characters.
  Widget _buildFormattedMessage(String text) {
    String cleanedText = text.replaceAllMapped(RegExp(r'\\text\{([^}]*)\}'), (match) {
      return match.group(1) ?? '';
    });

    final List<Widget> widgets = [];
    final RegExp regExp = RegExp(r'\$(.*?)\$');
    int lastMatchEnd = 0;

    for (final Match match in regExp.allMatches(cleanedText)) {
      if (match.start > lastMatchEnd) {
        final normalText = cleanedText.substring(lastMatchEnd, match.start);
        if (normalText.trim().isNotEmpty) {
          widgets.add(MarkdownBody(data: normalText));
        }
      }
      final latexCode = match.group(1) ?? '';
      bool containsBangla = RegExp(r'[\u0980-\u09FF]').hasMatch(latexCode);
      if (containsBangla || latexCode.trim().isEmpty) {
        widgets.add(Text(latexCode, style: const TextStyle(fontSize: 15)));
      } else {
        try {
          widgets.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                latexCode,
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ));
        } catch (_) {
          widgets.add(Text('\$${latexCode}\$', style: const TextStyle(fontSize: 15)));
        }
      }
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < cleanedText.length) {
      final remainingText = cleanedText.substring(lastMatchEnd);
      if (remainingText.trim().isNotEmpty) {
        widgets.add(MarkdownBody(data: remainingText));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Future<void> _sendMessage({String? customQuery, XFile? customImage, Map<String, dynamic>? customFile}) async {
    final text = customQuery ?? _messageController.text.trim();
    final XFile? imageToSend = customImage ?? _selectedImage;
    final Map<String, dynamic>? fileToSend = customFile ?? _attachedFile;

    if ((text.isEmpty && imageToSend == null && fileToSend == null) || _sessions.isEmpty) return;

    final currentSession = _sessions[_currentSessionIndex];

    if (customQuery == null) {
      setState(() {
        currentSession.messages.add({
          'sender': 'user',
          'text': text,
          'image': imageToSend,
          'fileName': fileToSend?['name'],
          'isError': false,
        });

        if (currentSession.title == 'New Chat') {
          currentSession.title = text.isNotEmpty
              ? (text.length > 25 ? '${text.substring(0, 25)}...' : text)
              : (fileToSend != null ? 'File Query' : 'Image Query');
        }

        _isLoading = true;
        _selectedImage = null;
        _attachedFile = null;
      });
      _messageController.clear();
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    _touch(currentSession);
    _saveSessionsToPrefs();
    _scrollToBottom();

    String? responseText;
    bool hasError = false;
    // The image (if any) is sent to our own server function, which holds the API key.
    String? imageBase64;
    String imageMime = 'image/jpeg';
    if (imageToSend != null) {
      try {
        final bytes = await imageToSend.readAsBytes();
        imageBase64 = base64Encode(bytes);
        imageMime = imageToSend.mimeType ?? 'image/jpeg';
      } catch (e) {
        debugPrint('Image encoding error: $e');
      }
    }

    Map<String, dynamic>? filePayload;
    if (fileToSend != null) {
      filePayload = {
        'name': fileToSend['name'],
        'mime_type': fileToSend['mime'],
        'data': base64Encode(fileToSend['bytes'] as Uint8List),
      };
    }

    try {
      // The Supabase Edge Function "ai-chat" calls Gemini. No API key lives in this app.
      final response = await Supabase.instance.client.functions.invoke(
        'ai-chat',
        body: {
          'text': text.isEmpty
              ? (filePayload != null
                  ? 'Please read this file and explain what it contains.'
                  : 'Please analyze this image and explain in detail.')
              : text,
          if (imageBase64 != null) 'image': {'mime_type': imageMime, 'data': imageBase64},
          if (filePayload != null) 'file': filePayload,
        },
      ).timeout(const Duration(seconds: 90));

      final data = response.data;
      if (data is Map && data['text'] is String && (data['text'] as String).isNotEmpty) {
        responseText = data['text'] as String;
      } else {
        hasError = true;
      }
    } on FunctionException catch (e) {
      debugPrint('AI function error: status ${e.status}');
      hasError = true;
      if (e.status == 429) {
        responseText = 'Too many requests. Please wait a minute and try again.';
      } else if (e.status == 401) {
        responseText = 'Please log in again to use the AI assistant.';
      }
    } catch (e) {
      debugPrint('AI request failed: $e');
      hasError = true;
    }

    if (responseText == null || responseText.isEmpty) {
      hasError = true;
      responseText = 'Network error or connection failed. Please check your internet connection and try again.';
    }

    setState(() {
      currentSession.messages.add({
        'sender': 'ai',
        'text': responseText!,
        'isError': hasError,
        'originalQuery': text,
        'originalImage': imageToSend,
        'originalFile': fileToSend,
      });
      _isLoading = false;
    });
    _touch(currentSession);
    _saveSessionsToPrefs();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final currentSession = _sessions.isNotEmpty ? _sessions[_currentSessionIndex] : null;

    final Widget mainContent = Scaffold(
      key: _scaffoldKey,
      onDrawerChanged: (isOpen) {
        if (isOpen) _refreshHistory();
      },
      drawerEnableOpenDragGesture: !widget.isEmbedded,
      appBar: AppBar(
        leading: widget.isEmbedded
            ? IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Chat History',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                currentSession?.title ?? 'AI Assistant',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (currentSession != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: 'Rename Title',
                onPressed: () => _showRenameDialog(_currentSessionIndex),
              ),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: !widget.isEmbedded,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Chat',
            onPressed: _createNewChat,
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Chat History',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _clearAllChats,
                      icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.red),
                      label: const Text('Clear All', style: TextStyle(color: Colors.red)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Start New Chat'),
              onTap: () {
                Navigator.pop(context);
                _createNewChat();
              },
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _sessions.length,
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  final isSelected = index == _currentSessionIndex;
                  return ListTile(
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _showRenameDialog(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          onPressed: () => _deleteChat(index),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _currentSessionIndex = index;
                      });
                      Navigator.pop(context);
                      _scrollToBottom();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: (currentSession == null || currentSession.messages.isEmpty)
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Ask anything... Your AI assistant is ready to help!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: currentSession.messages.length,
                    itemBuilder: (context, index) {
                      final message = currentSession.messages[index];
                      final isUser = message['sender'] == 'user';
                      final XFile? msgImage = message['image'];
                      final String messageText = message['text'] ?? '';
                      final bool isError = message['isError'] ?? false;

                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Theme.of(context).colorScheme.primaryContainer
                                : (isError
                                    ? Colors.red.shade50
                                    : Theme.of(context).colorScheme.surfaceContainerHighest),
                            borderRadius: BorderRadius.circular(12),
                            border: isError ? Border.all(color: Colors.red.shade200) : null,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (msgImage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _buildSafeImage(msgImage, height: 200, fit: BoxFit.cover),
                                  ),
                                ),
                              if (message['fileName'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.insert_drive_file_outlined, size: 18),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          message['fileName'].toString(),
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (messageText.isNotEmpty)
                                isUser
                                    ? SelectableText(
                                        messageText,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          isError
                                              ? Row(
                                                  children: [
                                                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        messageText,
                                                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : SelectionArea(
                                                  child: _buildFormattedMessage(messageText),
                                                ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (isError)
                                                TextButton.icon(
                                                  onPressed: () {
                                                    final String prevQuery = message['originalQuery'] ?? '';
                                                    final XFile? prevImage = message['originalImage'];
                                                    final Map<String, dynamic>? prevFile = message['originalFile'];
                                                    setState(() {
                                                      currentSession.messages.removeAt(index);
                                                    });
                                                    _sendMessage(customQuery: prevQuery, customImage: prevImage, customFile: prevFile);
                                                  },
                                                  icon: const Icon(Icons.refresh, size: 16, color: Colors.red),
                                                  label: const Text('Retry', style: TextStyle(color: Colors.red)),
                                                ),
                                              const Spacer(),
                                              if (!isError) ...[
                                                IconButton(
                                                  icon: const Icon(Icons.share, size: 16),
                                                  tooltip: 'Share Response',
                                                  onPressed: () => Share.share(messageText),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.copy, size: 16),
                                                  tooltip: 'Copy Response',
                                                  onPressed: () => _copyToClipboard(messageText),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI is thinking...',
                    style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _buildSafeImage(_selectedImage!, width: 50, height: 50, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  const Text('Image attached'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  )
                ],
              ),
            ),
          if (_attachedFile != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _attachedFile!['name'].toString(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _attachedFile = null;
                      });
                    },
                  )
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  tooltip: 'Attach image or file',
                  onPressed: _showImageSourceDialog,
                ),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.red : null),
                  tooltip: 'Voice Typing',
                  onPressed: _listen,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _isListening ? 'Listening...' : 'Ask anything...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return mainContent;
  }
}