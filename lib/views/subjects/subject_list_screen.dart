import 'package:flutter/material.dart';
import '../../core/constants/folder_structure.dart';
import '../previous_questions/previous_year_questions_screen.dart';
import 'lecture_list_screen.dart';
import 'sub_folder_list_screen.dart';

// English Comment: Main Folder Screen listing all subjects.
class SubjectListScreen extends StatelessWidget {
  const SubjectListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> mainFolders = folderStructure.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView.builder(
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
      ),
    );
  }
}