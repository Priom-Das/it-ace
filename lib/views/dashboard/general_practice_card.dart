// English Comment: Dashboard card for general job-exam practice (not tied to one exam). The user picks Live MCQ or SATT Academy and the
// choice is remembered on this device. Only pages that were checked against the live sites are linked directly;
// the subject buttons open a search limited to the chosen site.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class _Provider {
  final String id;
  final String name;
  final String tagline;
  final String domain;
  final List<_Page> pages;
  const _Provider(this.id, this.name, this.tagline, this.domain, this.pages);
}

class _Page {
  final String label;
  final String url;
  final IconData icon;
  const _Page(this.label, this.url, this.icon);
}

const List<_Provider> _providers = [
  _Provider(
    'livemcq',
    'Live MCQ',
    'Live exams, daily quiz, a free weekly model test and a large MCQ archive for all competitive job exams. Check the plan terms before paying.',
    'livemcq.com',
    [
      _Page('Open Live MCQ', 'https://web.livemcq.com/', Icons.quiz_outlined),
    ],
  ),
  _Provider(
    'sattacademy',
    'SATT Academy',
    'Institution-wise past questions (MCQ and written) with answers and explanations, chapter-wise exams and a mistake vault.',
    'sattacademy.com',
    [
      _Page('Job question bank', 'https://sattacademy.com/question-bank', Icons.folder_open_outlined),
    ],
  ),
];

// English Comment: Subjects of the general job exam. Each opens a site-limited search for that subject.
const List<(String label, String query)> _subjects = [
  ('Bangla', 'Bangla'),
  ('English', 'English'),
  ('Math', 'Math'),
  ('GK', 'General Knowledge Bangladesh'),
];

class GeneralPracticeCard extends StatefulWidget {
  const GeneralPracticeCard({super.key});

  @override
  State<GeneralPracticeCard> createState() => _GeneralPracticeCardState();
}

class _GeneralPracticeCardState extends State<GeneralPracticeCard> {
  static const String _prefKey = 'general_practice_provider';
  static const Color _purple = Color(0xFF6B4EE6);

  String _selected = 'sattacademy';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (!mounted || saved == null || !_providers.any((p) => p.id == saved)) return;
      setState(() => _selected = saved);
    } catch (_) {}
  }

  Future<void> _choose(String id) async {
    setState(() => _selected = id);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, id);
    } catch (_) {}
  }

  // Opens inside the app on Android / iOS, in a new browser tab on the web.
  Future<void> _open(String url) async {
    final uri = Uri.parse(url); // non-ASCII characters in the path are percent-encoded by Uri
    try {
      var ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      if (!ok) ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) _snack();
    } catch (_) {
      if (mounted) _snack();
    }
  }

  void _snack() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the link.')));
  }

  String _searchUrl(_Provider p, String query) {
    final q = 'site:${p.domain} $query MCQ';
    return 'https://www.google.com/search?q=${Uri.encodeQueryComponent(q)}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = _providers.firstWhere((p) => p.id == _selected);

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
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  for (final p in _providers) ButtonSegment<String>(value: p.id, label: Text(p.name)),
                ],
                selected: {_selected},
                onSelectionChanged: (s) => _choose(s.first),
              ),
            ),
            const SizedBox(height: 10),
            Text(provider.tagline, style: TextStyle(color: Colors.grey[800], fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final page in provider.pages)
                  FilledButton.tonalIcon(
                    onPressed: () => _open(page.url),
                    icon: Icon(page.icon, size: 18),
                    label: Text(page.label),
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
                    avatar: const Icon(Icons.search, size: 18),
                    label: Text(s.$1, style: const TextStyle(fontSize: 13)),
                    backgroundColor: Colors.white,
                    tooltip: 'Search ${provider.name} for ${s.$1}',
                    onPressed: () => _open(_searchUrl(provider, s.$2)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}