import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../media_viewers/pdf_viewer_screen.dart';
import 'previous_question_upload_screen.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../ai_assistant/draggable_ai_fab.dart';

// English Comment: Screen dedicated ONLY for Previous Year Questions with modern Draggable AI FAB and fixed Upload Button.
class PreviousYearQuestionsScreen extends StatefulWidget {
  const PreviousYearQuestionsScreen({super.key});

  @override
  State<PreviousYearQuestionsScreen> createState() => _PreviousYearQuestionsScreenState();
}

class _PreviousYearQuestionsScreenState extends State<PreviousYearQuestionsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _fetchPreviousQuestions();
  }

  Future<void> _fetchPreviousQuestions() async {
    try {
      final response = await _supabase
          .from('previous_questions')
          .select()
          .order('id', ascending: false);

      setState(() {
        _questions = List<Map<String, dynamic>>.from(response as List);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading questions: $e')),
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
        title: const Text('Previous Year Questions'),
        backgroundColor: const Color(0xFFDCD2F9),
        elevation: 0,
      ),
      // Upload Question button fixed at bottom-right
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'upload_question_fab_prev_q',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PreviousQuestionUploadScreen()),
          ).then((_) => _fetchPreviousQuestions());
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
              : _questions.isEmpty
                  ? const Center(child: Text('No previous year questions uploaded yet.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        final q = _questions[index];
                        final String? pdfUrl = q['file_url'];

                        return Card(
                          elevation: 0,
                          color: const Color(0xFFF3EEFC),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            title: Text(
                              q['title'] ?? 'Untitled Question',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Category: ${q['category']} | Year: ${q['exam_year'] ?? 'N/A'}'),
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
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