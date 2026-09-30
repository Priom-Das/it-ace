import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../media_viewers/pdf_viewer_screen.dart';
import '../media_viewers/video_player_screen.dart';
import 'lecture_list_screen.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../ai_assistant/draggable_ai_fab.dart';

// English Comment: SubFolder List Screen for navigating nested subtopics with modern Draggable AI FAB and internal PDF viewing.
class SubFolderListScreen extends StatefulWidget {
  final String parentFolder;
  final List<String> subFolders;

  const SubFolderListScreen({
    super.key,
    required this.parentFolder,
    required this.subFolders,
  });

  @override
  State<SubFolderListScreen> createState() => _SubFolderListScreenState();
}

class _SubFolderListScreenState extends State<SubFolderListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _directLectures = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDirectLectures();
  }

  Future<void> _fetchDirectLectures() async {
    try {
      final response = await _supabase
          .from('lecture_materials')
          .select()
          .ilike('subject', widget.parentFolder)
          .order('id', ascending: true);

      setState(() {
        _directLectures = List<Map<String, dynamic>>.from(response as List);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
        title: Text(widget.parentFolder),
        backgroundColor: const Color(0xFFDCD2F9),
        elevation: 0,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    ...widget.subFolders.map((subFolder) {
                      return Card(
                        elevation: 0,
                        color: const Color(0xFFF3EEFC),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B4EE6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.folder_open, color: Colors.white, size: 18),
                          ),
                          title: Text(
                            subFolder,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LectureListScreen(
                                  subjectName: subFolder,
                                  subTopic: subFolder,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                    if (_directLectures.isNotEmpty) ...[
                      ..._directLectures.map((lecture) {
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
                                  lecture['title'] ?? '${widget.parentFolder} Document',
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
                      }),
                    ],
                  ],
                ),
          
          // Draggable AI Floating Button
          DraggableAiFab(
            onPressed: () => _openAiAssistantSheet(context),
          ),
        ],
      ),
    );
  }
}