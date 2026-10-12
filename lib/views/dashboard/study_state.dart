// English Comment: Data and storage of the daily study plan: the chosen plan, minutes per topic and what was done
// on each day. Saved on the device first; when the user is logged in it is also synced with the Supabase table
// `study_progress` (see supabase/study_progress.sql) so another device shows the same plan and streak.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/study_plan.dart';

class DoneDay {
  Set<String> topics;
  int at; // milliseconds since epoch of the last change, used to decide which copy is newer
  DoneDay(this.topics, this.at);
}

class StudyState {
  String presetId;
  Map<int, List<String>> plan; // weekday (Mon=1..Sun=7) -> topics
  int planAt;
  Map<String, int> minutes; // topic -> minutes for the timer
  Map<String, DoneDay> done; // 'YYYY-MM-DD' -> finished topics

  StudyState({
    required this.presetId,
    required this.plan,
    required this.planAt,
    required this.minutes,
    required this.done,
  });

  static const int defaultMinutes = 45;

  int minutesFor(String topic) => minutes[topic] ?? defaultMinutes;

  static Map<int, List<String>> copyPlan(Map<int, List<String>> src) => {
        for (final e in src.entries) e.key: List<String>.of(e.value),
      };

  factory StudyState.fromPreset(String presetId) => StudyState(
        presetId: presetId,
        plan: copyPlan(presetById(presetId).days),
        planAt: 0,
        minutes: {},
        done: {},
      );

  Map<String, dynamic> toJson() => {
        'presetId': presetId,
        'plan': {for (final e in plan.entries) '${e.key}': e.value},
        'planAt': planAt,
        'minutes': minutes,
        'done': {
          for (final e in done.entries) e.key: {'t': e.value.topics.toList(), 'at': e.value.at},
        },
      };

  factory StudyState.fromJson(Map<String, dynamic> j) {
    final plan = <int, List<String>>{};
    final rawPlan = j['plan'];
    if (rawPlan is Map) {
      rawPlan.forEach((k, v) {
        final day = int.tryParse('$k');
        if (day != null && day >= 1 && day <= 7 && v is List) {
          plan[day] = v.map((e) => '$e').toList();
        }
      });
    }
    for (var d = 1; d <= 7; d++) {
      plan.putIfAbsent(d, () => <String>[]);
    }

    final minutes = <String, int>{};
    final rawMinutes = j['minutes'];
    if (rawMinutes is Map) {
      rawMinutes.forEach((k, v) {
        final m = (v as num?)?.toInt();
        if (m != null && m > 0) minutes['$k'] = m;
      });
    }

    final done = <String, DoneDay>{};
    final rawDone = j['done'];
    if (rawDone is Map) {
      rawDone.forEach((k, v) {
        if (v is Map && v['t'] is List) {
          done['$k'] = DoneDay(
            (v['t'] as List).map((e) => '$e').toSet(),
            (v['at'] as num?)?.toInt() ?? 0,
          );
        }
      });
    }

    // An id this app version does not know (for example from a newer app) is treated as the user's own plan.
    final rawPreset = (j['presetId'] as String?) ?? defaultPresetId;
    final knownPreset = rawPreset == customPresetId || studyPresets.any((p) => p.id == rawPreset);

    return StudyState(
      presetId: knownPreset ? rawPreset : customPresetId,
      plan: plan,
      planAt: (j['planAt'] as num?)?.toInt() ?? 0,
      minutes: minutes,
      done: done,
    );
  }

  // The plan and minutes of the copy edited last win. For each day the copy changed last wins.
  static StudyState merge(StudyState a, StudyState b) {
    final newer = a.planAt >= b.planAt ? a : b;
    final done = <String, DoneDay>{};
    for (final src in [a, b]) {
      for (final e in src.done.entries) {
        final cur = done[e.key];
        if (cur == null || e.value.at > cur.at) {
          done[e.key] = DoneDay({...e.value.topics}, e.value.at);
        } else if (e.value.at == cur.at) {
          cur.topics.addAll(e.value.topics);
        }
      }
    }
    return StudyState(
      presetId: newer.presetId,
      plan: copyPlan(newer.plan),
      planAt: newer.planAt,
      minutes: Map<String, int>.of(newer.minutes),
      done: done,
    );
  }
}

class StudyStore {
  static const String _key = 'study_state_v2';
  static const String _table = 'study_progress';
  static const String _oldDonePrefix = 'plan_done_'; // keys written by the first version of the card

  static Future<StudyState> loadLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        return StudyState.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
      }
      // First run of this version: keep what the old card had saved.
      final s = StudyState.fromPreset(defaultPresetId);
      for (final k in prefs.getKeys()) {
        if (k.startsWith(_oldDonePrefix)) {
          final topics = prefs.getStringList(k) ?? const <String>[];
          if (topics.isNotEmpty) s.done[k.substring(_oldDonePrefix.length)] = DoneDay(topics.toSet(), 0);
        }
      }
      return s;
    } catch (_) {
      return StudyState.fromPreset(defaultPresetId);
    }
  }

  static Future<void> saveLocal(StudyState s) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(s.toJson()));
    } catch (_) {}
  }

  static String? get _userId {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  // Best effort. Returns the merged state, or null when logged out / offline / the table does not exist yet.
  static Future<StudyState?> sync(StudyState local) async {
    final uid = _userId;
    if (uid == null) return null;
    try {
      final db = Supabase.instance.client;
      final row = await db.from(_table).select('data').eq('user_id', uid).maybeSingle();
      var merged = local;
      if (row != null && row['data'] is Map) {
        merged = StudyState.merge(local, StudyState.fromJson(Map<String, dynamic>.from(row['data'] as Map)));
      }
      await db.from(_table).upsert(
        {
          'user_id': uid,
          'data': merged.toJson(),
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        onConflict: 'user_id',
      );
      return merged;
    } catch (_) {
      return null;
    }
  }
}