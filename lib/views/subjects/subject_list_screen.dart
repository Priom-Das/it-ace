import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/folder_structure.dart';
import '../media_viewers/pdf_viewer_screen.dart';
import '../media_viewers/video_player_screen.dart';
import '../previous_questions/previous_year_questions_screen.dart';
import 'lecture_list_screen.dart';
import 'sub_folder_list_screen.dart';

// English Comment: Main Folder Screen with enhanced search UI displaying video & PDF action buttons.
class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoadingSearch = false;
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _preloadAndCacheData();
  }

  // English Comment: Preloads and caches lectures and questions locally for offline search support.
  Future<void> _preloadAndCacheData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Fetch lectures and questions from Supabase if online
      final lecturesResponse = await _supabase.from('lecture_materials').select();
      final questionsResponse = await _supabase.from('previous_questions').select();

      // Save to local storage as JSON strings
      await prefs.setString('cached_lectures', jsonEncode(lecturesResponse));
      await prefs.setString('cached_questions', jsonEncode(questionsResponse));
    } catch (e) {
      debugPrint('Offline cache preload error (using existing cache if available): $e');
    }
  }

  // English Comment: Executes global search across static folder structure and database tables with offline fallback.
  Future<void> _performSearch(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoadingSearch = false;
      });
      return;
    }

    setState(() => _isLoadingSearch = true);

    try {
      final List<Map<String, dynamic>> results = [];

      // 1. Search in Folder Structure (Main Folders and Sub-Folders)
      folderStructure.forEach((parentFolder, subFolders) {
        if (parentFolder.toLowerCase().contains(cleanQuery)) {
          results.add({
            'result_type': 'folder',
            'title': parentFolder,
            'subtitle': 'Main Category',
            'parent_folder': parentFolder,
            'sub_folders': subFolders,
          });
        }

        for (var sub in subFolders) {
          if (sub.toLowerCase().contains(cleanQuery)) {
            results.add({
              'result_type': 'sub_folder',
              'title': sub,
              'subtitle': 'Topic under $parentFolder',
              'parent_folder': parentFolder,
              'sub_folder': sub,
            });
          }
        }
      });

      List lecturesList = [];
      List questionsList = [];

      try {
        // Try fetching fresh data from Supabase
        final lecturesResponse = await _supabase
            .from('lecture_materials')
            .select()
            .ilike('title', '%$cleanQuery%');
        lecturesList = lecturesResponse as List;

        final questionsResponse = await _supabase
            .from('previous_questions')
            .select()
            .ilike('title', '%$cleanQuery%');
        questionsList = questionsResponse as List;
      } catch (networkError) {
        // Fallback to local cache when offline
        debugPrint('Network search failed, fetching from local cache: $networkError');
        final prefs = await SharedPreferences.getInstance();
        
        final cachedLecturesStr = prefs.getString('cached_lectures');
        if (cachedLecturesStr != null) {
          final List decodedLectures = jsonDecode(cachedLecturesStr);
          lecturesList = decodedLectures.where((item) {
            final title = (item['title'] ?? '').toString().toLowerCase();
            return title.contains(cleanQuery);
          }).toList();
        }

        final cachedQuestionsStr = prefs.getString('cached_questions');
        if (cachedQuestionsStr != null) {
          final List decodedQuestions = jsonDecode(cachedQuestionsStr);
          questionsList = decodedQuestions.where((item) {
            final title = (item['title'] ?? '').toString().toLowerCase();
            return title.contains(cleanQuery);
          }).toList();
        }
      }

      // 2. Add Lectures to Results
      for (var item in lecturesList) {
        results.add({
          'result_type': 'lecture',
          'title': item['title'] ?? 'Untitled Lecture',
          'subtitle': 'Lecture Material (${item['subject'] ?? 'General'})',
          'pdf_url': item['pdf_url'],
          'youtube_video_id': item['youtube_video_id'],
        });
      }

      // 3. Add Questions to Results
      for (var item in questionsList) {
        results.add({
          'result_type': 'question',
          'title': item['title'] ?? 'Untitled Question',
          'subtitle': 'Previous Question (${item['category'] ?? 'General'})',
          'pdf_url': item['file_url'],
        });
      }

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      setState(() => _isLoadingSearch = false);
    }
  }

  // English Comment: Open PDF inside the app via PdfViewerScreen for both Web and Mobile.
  void _openPdfDirectly(String pdfUrl, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          title: title,
          pdfUrl: pdfUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text(
          'Subjects',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Container(
            width: 180,
            height: 38,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDCD2F9)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: _performSearch,
                  ),
                ),
                if (isSearching)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  )
                else
                  const Icon(Icons.search, size: 18, color: Color(0xFF6B4EE6)),
              ],
            ),
          ),
        ],
      ),
      body: isSearching ? _buildSearchResultsUI() : _buildDefaultSubjectListUI(),
    );
  }

  // English Comment: Renders active search result view with direct media action buttons.
  Widget _buildSearchResultsUI() {
    if (_isLoadingSearch) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          'No matching topics, lectures, or questions found.',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        final String type = item['result_type'];

        // Folder & Sub-Folder UI
        if (type == 'folder' || type == 'sub_folder') {
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
                child: const Icon(Icons.folder, color: Colors.white, size: 18),
              ),
              title: Text(
                item['title'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: Text(
                item['subtitle'] ?? '',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                if (type == 'sub_folder') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LectureListScreen(
                        subjectName: item['sub_folder'],
                        subTopic: item['sub_folder'],
                      ),
                    ),
                  );
                } else {
                  final String parentFolder = item['parent_folder'];
                  if (parentFolder == 'PREVIOUS YEAR QUESTIONS') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PreviousYearQuestionsScreen(),
                      ),
                    );
                  } else {
                    final List<String> subfolders = List<String>.from(item['sub_folders'] ?? []);
                    if (subfolders.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubFolderListScreen(
                            parentFolder: parentFolder,
                            subFolders: subfolders,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LectureListScreen(
                            subjectName: parentFolder,
                            subTopic: null,
                          ),
                        ),
                      );
                    }
                  }
                }
              },
            ),
          );
        }

        // Lecture Material UI with Video and PDF Action Buttons
        final String? youtubeVideoId = item['youtube_video_id'];
        final String? pdfUrl = item['pdf_url'];

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
                  item['title'] ?? 'Untitled Material',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['subtitle'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
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
                                title: item['title'] ?? 'Lecture Video',
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
                          // English Comment: Direct to PdfViewerScreen uniformly across platforms without opening external tabs
                          _openPdfDirectly(pdfUrl, item['title'] ?? 'PDF Document');
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
    );
  }

  // English Comment: Default original Subjects List View.
  Widget _buildDefaultSubjectListUI() {
    final List<String> mainFolders = folderStructure.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: mainFolders.length,
      itemBuilder: (context, index) {
        final folder = mainFolders[index];
        final isPreviousYear = folder == 'PREVIOUS YEAR QUESTIONS';

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
              child: Icon(
                isPreviousYear ? Icons.history_edu : Icons.bookmark,
                color: Colors.white,
                size: 18,
              ),
            ),
            title: Text(
              folder,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              if (isPreviousYear) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PreviousYearQuestionsScreen(),
                  ),
                );
              } else {
                final subfolders = folderStructure[folder] ?? [];
                if (subfolders.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubFolderListScreen(
                        parentFolder: folder,
                        subFolders: subfolders,
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LectureListScreen(
                        subjectName: folder,
                        subTopic: null,
                      ),
                    ),
                  );
                }
              }
            },
          ),
        );
      },
    );
  }
}