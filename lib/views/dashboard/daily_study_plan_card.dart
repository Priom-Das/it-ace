// English Comment: Dashboard card with today's topic-wise study plan, resource links, done-tracking and streak.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/study_plan.dart';

class DailyStudyPlanCard extends StatefulWidget {
  const DailyStudyPlanCard({super.key});

  @override
  State<DailyStudyPlanCard> createState() => _DailyStudyPlanCardState();
}

class _DailyStudyPlanCardState extends State<DailyStudyPlanCard> {
  static const String _doneKeyPrefix = 'plan_done_';
  static const String _activeDaysKey = 'plan_active_days';
  static const Color _purple = Color(0xFF6B4EE6);

  late final DateTime _today;
  Set<String> _doneTopics = {};
  Set<String> _activeDays = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _load();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<String> get _todayTopics => weeklyPlan[_today.weekday] ?? const [];

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _doneTopics = (prefs.getStringList('$_doneKeyPrefix${_dateKey(_today)}') ?? []).toSet();
        _activeDays = (prefs.getStringList(_activeDaysKey) ?? []).toSet();
      });
    } catch (_) {}
  }

  Future<void> _toggle(String topic, bool done) async {
    setState(() {
      if (done) {
        _doneTopics.add(topic);
      } else {
        _doneTopics.remove(topic);
      }
      if (_doneTopics.isNotEmpty) {
        _activeDays.add(_dateKey(_today));
      } else {
        _activeDays.remove(_dateKey(_today));
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('$_doneKeyPrefix${_dateKey(_today)}', _doneTopics.toList());
      await prefs.setStringList(_activeDaysKey, _activeDays.toList());
    } catch (_) {}
  }

  // Days in a row with at least one finished topic. Today not started yet does not break yesterday's streak.
  int get _streak {
    var day = _activeDays.contains(_dateKey(_today))
        ? _today
        : DateTime(_today.year, _today.month, _today.day - 1);
    var count = 0;
    while (_activeDays.contains(_dateKey(day))) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  // Opens inside the app (Custom Tab / Safari view) on Android and iOS. On the web it opens a new browser tab,
  // because browsers do not let a normal page open other sites inside itself.
  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    try {
      var ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      if (!ok) ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) _snack('Could not open the link.');
    } catch (_) {
      if (mounted) _snack('Could not open the link.');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _resourceChip(String topic, String key) {
    final r = studyResources[key];
    if (r == null) return const SizedBox.shrink();
    final link = linkFor(topic, key);
    if (link == null) {
      return Chip(
        avatar: const Icon(Icons.menu_book_outlined, size: 16),
        label: Text(r.name, style: const TextStyle(fontSize: 13)),
        backgroundColor: Colors.white,
      );
    }
    return ActionChip(
      avatar: Icon(link.isSearch ? Icons.search : Icons.open_in_new, size: 18),
      label: Text(r.name, style: const TextStyle(fontSize: 13)),
      tooltip: link.isSearch ? '${r.name}: search "$topic"' : '${r.name}: $topic',
      backgroundColor: Colors.white,
      visualDensity: VisualDensity.standard,
      onPressed: () => _open(link.url),
    );
  }

  void _showWeeklyPlan() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Weekly Study Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final wd in weekOrder)
              Card(
                elevation: 0,
                color: wd == _today.weekday ? const Color(0xFFE5DCFB) : const Color(0xFFF3EEFC),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wd == _today.weekday ? '${weekdayNames[wd]} (today)' : weekdayNames[wd]!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      for (final t in weeklyPlan[wd] ?? const <String>[]) Text('• $t'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAllResources() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Study Resources', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final r in studyResources.values)
              ListTile(
                leading: Icon(r.url == null ? Icons.menu_book_outlined : Icons.public),
                title: Text(r.name),
                subtitle: Text(r.note),
                trailing: r.url == null ? null : const Icon(Icons.open_in_new, size: 18),
                onTap: r.url == null ? null : () => _open(r.url!),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topics = _todayTopics;
    final doneCount = topics.where(_doneTopics.contains).length;
    final progress = topics.isEmpty ? 0.0 : doneCount / topics.length;
    final streak = _streak;

    return Card(
      elevation: 0,
      color: const Color(0xFFF3EEFC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_note, color: _purple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Today's Study Plan · ${weekdayNames[_today.weekday]}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (streak > 0)
                  Chip(
                    avatar: const Icon(Icons.local_fire_department, size: 18, color: Colors.deepOrange),
                    label: Text('$streak day${streak == 1 ? '' : 's'}'),
                    backgroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white,
                color: _purple,
              ),
            ),
            const SizedBox(height: 4),
            Text('$doneCount / ${topics.length} topics done', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
            const SizedBox(height: 6),
            for (final topic in topics)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(left: 8, bottom: 8),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  leading: Checkbox(
                    value: _doneTopics.contains(topic),
                    activeColor: _purple,
                    onChanged: (v) => _toggle(topic, v ?? false),
                  ),
                  title: Text(
                    topic,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: _doneTopics.contains(topic) ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 0,
                      children: [for (final key in topicResources[topic] ?? const <String>[]) _resourceChip(topic, key)],
                    ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _showWeeklyPlan,
                  icon: const Icon(Icons.calendar_view_week, size: 18),
                  label: const Text('Weekly plan'),
                ),
                TextButton.icon(
                  onPressed: _showAllResources,
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('All resources'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}