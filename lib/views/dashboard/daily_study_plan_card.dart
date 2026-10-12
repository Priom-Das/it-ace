// English Comment: Dashboard card with today's study plan: topics with practice links, done-tracking, a timer per
// topic, a streak, an editable weekly plan (target exam presets) and sync across devices.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/study_plan.dart';
import '../../core/utils/open_link.dart';
import 'study_plan_editor.dart';
import 'study_state.dart';
import 'study_timer_sheet.dart';

class DailyStudyPlanCard extends StatefulWidget {
  const DailyStudyPlanCard({super.key});

  @override
  State<DailyStudyPlanCard> createState() => _DailyStudyPlanCardState();
}

class _DailyStudyPlanCardState extends State<DailyStudyPlanCard> {
  static const Color _purple = Color(0xFF6B4EE6);

  late final DateTime _today;
  StudyState? _s;
  final Set<String> _expanded = {}; // topics whose full link list is open
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _init();
  }

  Future<void> _init() async {
    final local = await StudyStore.loadLocal();
    if (!mounted) return;
    setState(() => _s = local);
    unawaited(_sync());
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<String> get _todayTopics => _s?.plan[_today.weekday] ?? const <String>[];

  Set<String> get _todayDone => _s?.done[_dateKey(_today)]?.topics ?? <String>{};

  // Days in a row with at least one finished topic. A today that has not started yet keeps yesterday's streak alive.
  int get _streak {
    final s = _s;
    if (s == null) return 0;
    bool active(DateTime d) => s.done[_dateKey(d)]?.topics.isNotEmpty ?? false;
    var day = active(_today) ? _today : DateTime(_today.year, _today.month, _today.day - 1);
    var count = 0;
    while (active(day)) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  // Saves on the device, then syncs with the cloud. Edits made while syncing are kept (newer change wins).
  Future<void> _sync() async {
    final s = _s;
    if (s == null || _syncing) return;
    _syncing = true;
    try {
      await StudyStore.saveLocal(s);
      final merged = await StudyStore.sync(s);
      if (merged != null && mounted && _s != null) {
        final next = StudyState.merge(_s!, merged);
        setState(() => _s = next);
        await StudyStore.saveLocal(next);
      }
    } finally {
      _syncing = false;
    }
  }

  void _changed() {
    setState(() {});
    final s = _s;
    if (s != null) {
      StudyStore.saveLocal(s);
      unawaited(_sync());
    }
  }

  DoneDay _todayEntry() => _s!.done.putIfAbsent(_dateKey(_today), () => DoneDay(<String>{}, 0));

  void _setDone(String topic, bool done) {
    final day = _todayEntry();
    if (done) {
      day.topics.add(topic);
    } else {
      day.topics.remove(topic);
    }
    day.at = DateTime.now().millisecondsSinceEpoch;
    _changed();
  }

  void _markWholeDay(bool done) {
    final day = _todayEntry();
    if (done) {
      day.topics.addAll(_todayTopics);
    } else {
      day.topics.removeAll(_todayTopics);
    }
    day.at = DateTime.now().millisecondsSinceEpoch;
    _changed();
  }

  void _openTimer(String topic) {
    final s = _s;
    if (s == null) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => StudyTimerSheet(
        topic: topic,
        minutes: s.minutesFor(topic),
        onMinutesChanged: (m) {
          s.minutes[topic] = m;
          s.planAt = DateTime.now().millisecondsSinceEpoch; // so the new minutes win when syncing
          _changed();
        },
        onMarkDone: () => _setDone(topic, true),
      ),
    );
  }

  void _openEditor() {
    final s = _s;
    if (s == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StudyPlanEditor(state: s, onChanged: _changed),
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
                onTap: r.url == null ? null : () => openLink(context, r.url!),
              ),
          ],
        ),
      ),
    );
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
      onPressed: () => openLink(context, link.url),
    );
  }

  Widget _topicTile(String topic, StudyState s) {
    final done = _todayDone.contains(topic);
    final resources = resourcesForTopic(topic);
    // Every other exam link is always visible. SATT Academy is always the LAST option and stays hidden
    // until "+N more" is tapped.
    bool isSatt(String k) => k == 'sattacademy' || k == 'satt_bb_ict';
    final ordered = [
      ...resources.where((k) => !isSatt(k)),
      ...resources.where(isSatt),
    ];
    final open = _expanded.contains(topic);
    final primary = ordered.where((k) => !isSatt(k)).toList();
    final shown = open ? ordered : primary;
    final hidden = ordered.length - shown.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: done,
                activeColor: _purple,
                onChanged: (v) => _setDone(topic, v ?? false),
              ),
              Expanded(
                child: Text(
                  topic,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done ? Colors.grey[600] : null,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _openTimer(topic),
                icon: const Icon(Icons.timer_outlined, size: 18),
                label: Text('${s.minutesFor(topic)} min'),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 0,
              children: [
                for (final key in shown) _resourceChip(topic, key),
                if (hidden > 0)
                  ActionChip(
                    label: Text('+$hidden more', style: const TextStyle(fontSize: 13)),
                    onPressed: () => setState(() => _expanded.add(topic)),
                  ),
                if (open && ordered.length > primary.length)
                  ActionChip(
                    label: const Text('Less', style: TextStyle(fontSize: 13)),
                    onPressed: () => setState(() => _expanded.remove(topic)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final topics = _todayTopics;
    final doneToday = _todayDone;
    final doneCount = topics.where(doneToday.contains).length;
    final allDone = topics.isNotEmpty && doneCount == topics.length;
    final progress = topics.isEmpty ? 0.0 : doneCount / topics.length;
    final streak = _streak;

    return Card(
      elevation: 0,
      color: const Color(0xFFF3EEFC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: s == null
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
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
                  InkWell(
                    onTap: _openEditor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        s.presetId == customPresetId ? 'My own plan · tap to change' : '${presetById(s.presetId).name} · tap to change',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12, decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (topics.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('Rest day. No topics planned today.', style: TextStyle(color: Colors.grey[700])),
                    )
                  else ...[
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
                    Text(
                      '$doneCount / ${topics.length} topics done',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    for (final topic in topics) _topicTile(topic, s),
                  ],
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 4,
                    children: [
                      if (topics.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _markWholeDay(!allDone),
                          icon: Icon(allDone ? Icons.undo : Icons.done_all, size: 18),
                          label: Text(allDone ? 'Undo day' : 'Mark day done'),
                        ),
                      TextButton.icon(
                        onPressed: _openEditor,
                        icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                        label: const Text('Edit plan'),
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