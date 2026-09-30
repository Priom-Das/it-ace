// English Comment: Main assistant screen featuring robust text cleaning for LaTeX wrapper tags and proper markdown rendering.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:share_plus/share_plus.dart';

import 'ai_config.dart';
import 'chat_session.dart';

class AiAssistantScreen extends StatefulWidget {
  final bool isEmbedded;

  const AiAssistantScreen({super.key, this.isEmbedded = false});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatSession> _sessions = [];
  int _currentSessionIndex = 0;
  bool _isLoading = false;
  XFile? _selectedImage;

  final ImagePicker _picker = ImagePicker();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadSessionsFromPrefs();
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

  Future<void> _loadSessionsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataString = prefs.getString('ai_chat_sessions');
    if (dataString != null) {
      try {
        final List decoded = jsonDecode(dataString);
        setState(() {
          _sessions = decoded.map((item) => ChatSession.fromJson(item)).toList();
          if (_sessions.isEmpty) {
            _createNewChatInternal();
          } else {
            _currentSessionIndex = 0;
          }
        });
        _scrollToBottom();
        return;
      } catch (_) {}
    }
    _createNewChatInternal();
  }

  Future<void> _saveSessionsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_sessions.map((s) => s.toJson()).toList());
      await prefs.setString('ai_chat_sessions', encoded);
    } catch (_) {}
  }

  void _createNewChatInternal() {
    final newSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Chat',
      messages: [],
    );
    _sessions.insert(0, newSession);
    _currentSessionIndex = 0;
    _selectedImage = null;
    _saveSessionsToPrefs();
  }

  void _createNewChat() {
    setState(() {
      _createNewChatInternal();
    });
    _scrollToBottom();
  }

  void _deleteChat(int index) {
    setState(() {
      _sessions.removeAt(index);
      if (_sessions.isEmpty) {
        _createNewChatInternal();
      } else {
        if (_currentSessionIndex >= _sessions.length) {
          _currentSessionIndex = _sessions.length - 1;
        }
      }
    });
    _saveSessionsToPrefs();
    _scrollToBottom();
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
              setState(() {
                _sessions.clear();
                _createNewChatInternal();
              });
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
        });
      }
    } catch (_) {}
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

  Future<void> _sendMessage({String? customQuery, XFile? customImage}) async {
    final text = customQuery ?? _messageController.text.trim();
    final XFile? imageToSend = customImage ?? _selectedImage;

    if ((text.isEmpty && imageToSend == null) || _sessions.isEmpty) return;

    final currentSession = _sessions[_currentSessionIndex];

    if (customQuery == null) {
      setState(() {
        currentSession.messages.add({
          'sender': 'user',
          'text': text,
          'image': imageToSend,
          'isError': false,
        });

        if (currentSession.title == 'New Chat') {
          currentSession.title = text.isNotEmpty
              ? (text.length > 25 ? '${text.substring(0, 25)}...' : text)
              : 'Image Query';
        }

        _isLoading = true;
        _selectedImage = null;
      });
      _messageController.clear();
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    _saveSessionsToPrefs();
    _scrollToBottom();

    String? responseText;
    bool hasError = false;
    List<Map<String, dynamic>> contentParts = [];

    contentParts.add({
      'text': 'System Directive: ${AiConfig.systemPrompt}\n\nUser Question: ${text.isEmpty ? "Please analyze this image and explain in detail." : text}'
    });

    if (imageToSend != null) {
      try {
        final bytes = await imageToSend.readAsBytes();
        final base64Image = base64Encode(bytes);
        contentParts.add({
          'inline_data': {
            'mime_type': 'image/jpeg',
            'data': base64Image,
          }
        });
      } catch (e) {
        debugPrint('Image encoding error: $e');
      }
    }

    for (int i = 0; i < AiConfig.apiKeys.length; i++) {
      final apiKey = AiConfig.apiKeys[i];
      if (apiKey.isEmpty || apiKey.startsWith('YOUR_GEMINI_API_KEY')) continue;

      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=$apiKey',
        );

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': contentParts,
              }
            ],
            'generationConfig': {
              'maxOutputTokens': 8192,
              'temperature': 0.7,
            }
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          responseText = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (responseText != null && responseText.isNotEmpty) {
            hasError = false;
            break;
          }
        } else {
          debugPrint('API Error Status: ${response.statusCode}, Body: ${response.body}');
          hasError = true;
        }
      } catch (e) {
        debugPrint('HTTP Exception: $e');
        hasError = true;
      }
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
      });
      _isLoading = false;
    });
    _saveSessionsToPrefs();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final currentSession = _sessions.isNotEmpty ? _sessions[_currentSessionIndex] : null;

    final Widget mainContent = Scaffold(
      appBar: AppBar(
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
      drawer: widget.isEmbedded ? null : Drawer(
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
                                                    setState(() {
                                                      currentSession.messages.removeAt(index);
                                                    });
                                                    _sendMessage(customQuery: prevQuery, customImage: prevImage);
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
                  icon: const Icon(Icons.image_outlined),
                  tooltip: 'Attach Image',
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