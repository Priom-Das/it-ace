// English Comment: Bottom sheet to see and edit the weekly study plan: pick a ready-made plan for a target exam,
// add or remove topics on any day (your own topics too), and leave a day empty for a rest day.
import 'package:flutter/material.dart';

import '../../core/constants/study_plan.dart';
import 'study_state.dart';

class StudyPlanEditor extends StatefulWidget {
  final StudyState state;
  final VoidCallback onChanged; // called after every edit so the card can save

  const StudyPlanEditor({super.key, required this.state, required this.onChanged});

  @override
  State<StudyPlanEditor> createState() => _StudyPlanEditorState();
}

class _StudyPlanEditorState extends State<StudyPlanEditor> {
  StudyState get _s => widget.state;

  void _touch() {
    _s.planAt = DateTime.now().millisecondsSinceEpoch;
    setState(() {});
    widget.onChanged();
  }

  Future<void> _choosePreset(String id) async {
    if (id == _s.presetId) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Use this plan?'),
        content: Text('Your current weekly plan will be replaced by "${presetById(id).name}". Your progress is kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Use plan')),
        ],
      ),
    );
    if (ok != true) return;
    _s.presetId = id;
    _s.plan = StudyState.copyPlan(presetById(id).days);
    _touch();
  }

  Future<void> _addTopic(int weekday) async {
    final existing = (_s.plan[weekday] ?? const <String>[]).toSet();
    final topic = await _pickTopic(existing);
    if (topic == null || existing.contains(topic)) return;
    _s.plan.putIfAbsent(weekday, () => <String>[]).add(topic);
    _s.presetId = customPresetId;
    _touch();
  }

  void _removeTopic(int weekday, String topic) {
    _s.plan[weekday]?.remove(topic);
    _s.presetId = customPresetId;
    _touch();
  }

  Future<String?> _pickTopic(Set<String> exclude) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add topic'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'Your own topic', hintText: 'e.g. SQL joins'),
                  onSubmitted: (v) {
                    final t = v.trim();
                    if (t.isNotEmpty) Navigator.pop(ctx, t);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Or pick one'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final t in topicResources.keys)
                      if (!exclude.contains(t))
                        ActionChip(
                          label: Text(t, style: const TextStyle(fontSize: 12)),
                          onPressed: () => Navigator.pop(ctx, t),
                        ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final t = controller.text.trim();
              if (t.isNotEmpty) Navigator.pop(ctx, t);
            },
            child: const Text('Add my topic'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    final items = <DropdownMenuItem<String>>[
      for (final p in studyPresets) DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis)),
      if (_s.presetId == customPresetId)
        const DropdownMenuItem(value: customPresetId, child: Text('My own plan')),
    ];
    final description =
        _s.presetId == customPresetId ? 'You changed the plan. Pick a ready-made plan to start over.' : presetById(_s.presetId).description;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Weekly Study Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Target exam', style: TextStyle(fontWeight: FontWeight.w600)),
          DropdownButton<String>(
            isExpanded: true,
            value: _s.presetId,
            items: items,
            onChanged: (v) {
              if (v != null && v != customPresetId) _choosePreset(v);
            },
          ),
          Text(description, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          const SizedBox(height: 12),
          for (final wd in weekOrder)
            Card(
              elevation: 0,
              color: wd == today ? const Color(0xFFE5DCFB) : const Color(0xFFF3EEFC),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            wd == today ? '${weekdayNames[wd]} (today)' : weekdayNames[wd]!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: 'Add topic',
                          onPressed: () => _addTopic(wd),
                        ),
                      ],
                    ),
                    if ((_s.plan[wd] ?? const <String>[]).isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('Rest day', style: TextStyle(color: Colors.grey[700])),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        children: [
                          for (final t in _s.plan[wd]!)
                            InputChip(
                              label: Text(t, style: const TextStyle(fontSize: 12)),
                              backgroundColor: Colors.white,
                              onDeleted: () => _removeTopic(wd, t),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}