// English Comment: Dashboard card for general job-exam practice (not tied to one exam), using SATT Academy.
// Every link is a direct page that was checked on the live site.
import 'package:flutter/material.dart';

import '../../core/utils/open_link.dart';

class _Page {
  final String label;
  final String url;
  final IconData icon;
  const _Page(this.label, this.url, this.icon);
}

const List<_Page> _tools = [
  _Page('Job question bank', 'https://sattacademy.com/question-bank', Icons.folder_open_outlined),
  _Page('Model tests', 'https://sattacademy.com/modeltest-list', Icons.timer_outlined),
  _Page('On-demand test', 'https://sattacademy.com/custom/model-test', Icons.tune),
];

const List<_Page> _subjects = [
  _Page('Bangla', 'https://sattacademy.com/all-mcq/বাংলা', Icons.menu_book_outlined),
  _Page('English', 'https://sattacademy.com/all-mcq/english', Icons.translate),
  _Page('Math', 'https://sattacademy.com/all-mcq/গণিত', Icons.calculate_outlined),
  _Page('GK', 'https://sattacademy.com/all-mcq/সাধারণ-জ্ঞান', Icons.public),
  _Page('Current Affairs', 'https://sattacademy.com/gk', Icons.newspaper),
];

class GeneralPracticeCard extends StatelessWidget {
  const GeneralPracticeCard({super.key});

  static const Color _purple = Color(0xFF6B4EE6);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF3EEFC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.fact_check_outlined, color: _purple),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'General Job Exam Practice',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Past questions with answers and explanations, chapter-wise exams and model tests (SATT Academy).',
              style: TextStyle(color: Colors.grey[800], fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final t in _tools)
                  FilledButton.tonalIcon(
                    onPressed: () => openLink(context, t.url),
                    icon: Icon(t.icon, size: 18),
                    label: Text(t.label),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Practice by subject', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800])),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: [
                for (final s in _subjects)
                  ActionChip(
                    avatar: Icon(s.icon, size: 18),
                    label: Text(s.label, style: const TextStyle(fontSize: 13)),
                    backgroundColor: Colors.white,
                    onPressed: () => openLink(context, s.url),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}