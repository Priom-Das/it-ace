import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../media_viewers/pdf_viewer_screen.dart';
import '../media_viewers/video_player_screen.dart';

// English Comment: Screen for displaying lecture materials without filtering by sub_topic to match table columns.
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

  Future<void> _openPdfDirectly(String pdfUrl) async {
    final Uri url = Uri.parse(pdfUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open PDF URL')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
        backgroundColor: const Color(0xFFDCD2F9),
        elevation: 0,
      ),
      body: _isLoading
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
                                      if (kIsWeb) {
                                        _openPdfDirectly(pdfUrl);
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PdfViewerScreen(
                                              title: lecture['title'] ?? 'PDF Document',
                                              pdfUrl: pdfUrl,
                                            ),
                                          ),
                                        );
                                      }
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
    );
  }
}