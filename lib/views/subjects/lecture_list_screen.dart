import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../media_viewers/pdf_viewer_screen.dart';
import '../media_viewers/video_player_screen.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../ai_assistant/draggable_ai_fab.dart';

// English Comment: Screen for displaying lecture materials with modern Draggable AI FAB and internal PDF viewing for all platforms.
class LectureListScreen extends StatefulWidget {
  final String subjectName;
  final String? subTopic;

  const LectureListScreen({
    super.key,
    required this.subjectName,
    this.subTopic,
  });

  @override
  State<LectureListScreen> createState() => _LectureListScreenState();
}

class _LectureListScreenState extends State<LectureListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _lectures = [];

  @override
  void initState() {
    super.initState();
    _fetchLectures();
  }

  Future<void> _fetchLectures() async {
    try {
      final response = await _supabase
          .from('lecture_materials')
          .select()
          .ilike('subject', widget.subjectName)
          .order('id', ascending: true);

      setState(() {
        _lectures = List<Map<String, dynamic>>.from(response as List);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading content: $e')),
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
        title: Text(widget.subjectName),
        backgroundColor: const Color(0xFFDCD2F9),
        elevation: 0,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _lectures.isEmpty
                  ? const Center(
                      child: Text(
                        'No lecture files uploaded for this topic yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      itemCount: _lectures.length,
                      itemBuilder: (context, index) {
                        final lecture = _lectures[index];
                        final String? youtubeVideoId = lecture['youtube_video_id'];
                        final String? pdfUrl = lecture['pdf_url'];

                        return Card(
                          elevation: 0,
                          color: const Color(0xFFF3EEFC),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lecture['title'] ?? '${widget.subjectName}_Lecture ${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (youtubeVideoId != null && youtubeVideoId.isNotEmpty)
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => VideoPlayerScreen(
                                                title: lecture['title'] ?? 'Lecture Video',
                                                youtubeVideoId: youtubeVideoId,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.play_circle_fill, size: 18),
                                        label: const Text('Watch Video'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF6B4EE6),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                      )
                                    else
                                      const SizedBox.shrink(),
                                    if (pdfUrl != null && pdfUrl.isNotEmpty)
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PdfViewerScreen(
                                                title: lecture['title'] ?? 'PDF Document',
                                                pdfUrl: pdfUrl,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.picture_as_pdf, size: 18, color: Colors.grey),
                                        label: const Text(
                                          'PDF',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.grey),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                      )
                                    else
                                      const SizedBox.shrink(),
                                  ],
                                ),
                              ],
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