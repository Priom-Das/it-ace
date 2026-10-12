// English Comment: Countdown timer for one study topic. It counts from a fixed end time, so the remaining time stays
// correct even if the screen was off for a while. The timer only runs while the app is open.
import 'dart:async';

import 'package:flutter/material.dart';

class StudyTimerSheet extends StatefulWidget {
  final String topic;
  final int minutes;
  final ValueChanged<int> onMinutesChanged;
  final VoidCallback onMarkDone;

  const StudyTimerSheet({
    super.key,
    required this.topic,
    required this.minutes,
    required this.onMinutesChanged,
    required this.onMarkDone,
  });

  @override
  State<StudyTimerSheet> createState() => _StudyTimerSheetState();
}

class _StudyTimerSheetState extends State<StudyTimerSheet> {
  late int _minutes;
  late int _remaining; // seconds left
  DateTime? _endAt; // set while running
  Timer? _ticker;

  bool get _running => _endAt != null;
  bool get _finished => _remaining <= 0;

  @override
  void initState() {
    super.initState();
    _minutes = widget.minutes;
    _remaining = _minutes * 60;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    if (_finished) _remaining = _minutes * 60;
    _endAt = DateTime.now().add(Duration(seconds: _remaining));
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) => _tick());
    setState(() {});
  }

  void _tick() {
    final end = _endAt;
    if (end == null) return;
    final left = end.difference(DateTime.now()).inSeconds + 1;
    if (left <= 0) {
      _ticker?.cancel();
      setState(() {
        _remaining = 0;
        _endAt = null;
      });
    } else if (left != _remaining) {
      setState(() => _remaining = left);
    }
  }

  void _pause() {
    _ticker?.cancel();
    setState(() => _endAt = null); // _remaining already holds the time left
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _endAt = null;
      _remaining = _minutes * 60;
    });
  }

  void _changeMinutes(int delta) {
    final next = (_minutes + delta).clamp(5, 240);
    setState(() {
      _minutes = next;
      _remaining = next * 60;
    });
    widget.onMinutesChanged(next);
  }

  String get _clock {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.topic, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(
              _finished ? "Time's up!" : _clock,
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w300,
                color: _finished ? Colors.green : const Color(0xFF6B4EE6),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _running ? null : () => _changeMinutes(-5),
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: '5 minutes less',
                ),
                Text('$_minutes min'),
                IconButton(
                  onPressed: _running ? null : () => _changeMinutes(5),
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: '5 minutes more',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (_running)
                  FilledButton.icon(onPressed: _pause, icon: const Icon(Icons.pause), label: const Text('Pause'))
                else
                  FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(_finished ? 'Start again' : (_remaining < _minutes * 60 ? 'Resume' : 'Start')),
                  ),
                OutlinedButton.icon(onPressed: _reset, icon: const Icon(Icons.restart_alt), label: const Text('Reset')),
                if (_finished)
                  FilledButton.tonalIcon(
                    onPressed: () {
                      widget.onMarkDone();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Mark topic done'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}