import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'previous_question_list_screen.dart';
import 'previous_question_upload_screen.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../ai_assistant/draggable_ai_fab.dart';

// English Comment: Loads previous year questions (cache first, then server) and tells which folder a row belongs to.
class PreviousQuestionsRepo {
  static const String cacheKey = 'cached_previous_questions';
  static const List<String> folders = ['General', 'IT'];

  static Future<List<Map<String, dynamic>>> loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(cacheKey);
      if (cached == null) return [];
      return List<Map<String, dynamic>>.from(jsonDecode(cached) as List);
    } catch (_) {
      return [];
    }
  }

  // Throws when offline, so the caller can keep showing the cached list.
  static Future<List<Map<String, dynamic>>> fetch() async {
    final response = await Supabase.instance.client
        .from('previous_questions')
        .select()
        .order('id', ascending: false);
    final list = List<Map<String, dynamic>>.from(response as List);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, jsonEncode(list));
    } catch (_) {}
    return list;
  }

  // The "category" column decides the folder. Older rows without a category are sorted by their title / job
  // category, so nothing is lost: IT-looking papers go to IT, the rest to General.
  static String folderOf(Map<String, dynamic> row) {
    final category = (row['category'] ?? '').toString().trim().toLowerCase();
    if (category == 'it') return 'IT';
    if (category == 'general') return 'General';
    final hint = '${row['title'] ?? ''} ${row['job_category'] ?? ''} ${row['exam_name'] ?? ''}'.toLowerCase();
    final looksIt = RegExp(
      r'\b(it|ict)\b|programmer|software|network|engineer|database|developer|system analyst|computer',
    ).hasMatch(hint);
    return looksIt ? 'IT' : 'General';
  }
}

// English Comment: Previous Year Questions is split into two folders, General and IT.
class PreviousYearQuestionsScreen extends StatefulWidget {
  const PreviousYearQuestionsScreen({super.key});

  @override
  State<PreviousYearQuestionsScreen> createState() => _PreviousYearQuestionsScreenState();
}

class _PreviousYearQuestionsScreenState extends State<PreviousYearQuestionsScreen> {
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cached = await PreviousQuestionsRepo.loadCached();
    if (mounted && cached.isNotEmpty) {
      setState(() {
        _questions = cached;
        _isLoading = false;
      });
    }
    try {
      final fresh = await PreviousQuestionsRepo.fetch();
      if (!mounted) return;
      setState(() {
        _questions = fresh;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false); // offline: keep the cached numbers
    }
  }

  int _count(String folder) => _questions.where((q) => PreviousQuestionsRepo.folderOf(q) == folder).length;

  void _openFolder(String folder) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PreviousQuestionListScreen(folder: folder)),
    ).then((_) => _load());
  }

  void _openAiAssistantSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const AiAssistantScreen(isEmbedded: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Previous Year Questions'),
        backgroundColor: const Color(0xFFDCD2F9),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'upload_question_fab_prev_q',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PreviousQuestionUploadScreen()),
          ).then((_) => _load());
        },
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload Question'),
        backgroundColor: const Color(0xFF6B4EE6),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final folder in PreviousQuestionsRepo.folders)
                      Card(
                        elevation: 0,
                        color: const Color(0xFFF3EEFC),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B4EE6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.folder_outlined, color: Colors.white),
                          ),
                          title: Text(folder, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${_count(folder)} question paper${_count(folder) == 1 ? '' : 's'}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openFolder(folder),
                        ),
                      ),
                  ],
                ),

          // Messenger Chat Head Style Draggable AI Floating Button
          DraggableAiFab(
            onPressed: () => _openAiAssistantSheet(context),
          ),
        ],
      ),
    );
  }
}
