import 'package:flutter/material.dart';
import '../media_viewers/pdf_viewer_screen.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../ai_assistant/draggable_ai_fab.dart';
import 'previous_question_upload_screen.dart';
import 'previous_year_questions_screen.dart';

// English Comment: The question papers of ONE folder (General or IT). Uploading from here pre-selects this folder.
class PreviousQuestionListScreen extends StatefulWidget {
  final String folder; // 'General' or 'IT'

  const PreviousQuestionListScreen({super.key, required this.folder});

  @override
  State<PreviousQuestionListScreen> createState() => _PreviousQuestionListScreenState();
}

class _PreviousQuestionListScreenState extends State<PreviousQuestionListScreen> {
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<Map<String, dynamic>> _inFolder(List<Map<String, dynamic>> all) =>
      all.where((q) => PreviousQuestionsRepo.folderOf(q) == widget.folder).toList();

  Future<void> _load() async {
    // Cached list first so the folder opens instantly and works offline.
    final cached = await PreviousQuestionsRepo.loadCached();
    if (mounted && cached.isNotEmpty) {
      setState(() {
        _questions = _inFolder(cached);
        _isLoading = false;
      });
    }
    try {
      final fresh = await PreviousQuestionsRepo.fetch();
      if (!mounted) return;
      setState(() {
        _questions = _inFolder(fresh);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (_questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline mode: unable to sync the latest questions.')),
        );
      }
    }
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
        title: Text('Previous Year Questions · ${widget.folder}'),
        backgroundColor: const Color(0xFFDCD2F9),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'upload_question_fab_prev_q_list',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PreviousQuestionUploadScreen(initialCategory: widget.folder),
            ),
          ).then((_) => _load());
        },
        icon: const Icon(Icons.upload_file),
        label: Text('Upload to ${widget.folder}'),
        backgroundColor: const Color(0xFF6B4EE6),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _questions.isEmpty
                  ? Center(child: Text('No ${widget.folder} question papers uploaded yet.'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        final q = _questions[index];
                        final String? pdfUrl = q['file_url'];

                        return Card(
                          elevation: 0,
                          color: const Color(0xFFF3EEFC),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            title: Text(
                              q['title'] ?? 'Untitled Question',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              [
                                if ((q['exam_name'] ?? '').toString().isNotEmpty) q['exam_name'],
                                'Year: ${q['exam_year'] ?? 'N/A'}',
                              ].join(' | '),
                            ),
                            trailing: OutlinedButton.icon(
                              onPressed: () {
                                if (pdfUrl != null && pdfUrl.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PdfViewerScreen(
                                        title: q['title'] ?? 'Question Paper',
                                        pdfUrl: pdfUrl,
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.picture_as_pdf, size: 18, color: Colors.grey),
                              label: const Text('PDF', style: TextStyle(color: Colors.grey)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ),
                        );
                      },
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
