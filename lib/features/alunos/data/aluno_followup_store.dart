import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local follow-up / snooze state per aluno (personal-side productivity).
class AlunoFollowUpEntry {
  final DateTime? snoozedUntil;
  final DateTime? followUpDate;

  const AlunoFollowUpEntry({this.snoozedUntil, this.followUpDate});

  AlunoFollowUpEntry copyWith({
    DateTime? snoozedUntil,
    DateTime? followUpDate,
    bool clearSnooze = false,
    bool clearFollowUp = false,
  }) {
    return AlunoFollowUpEntry(
      snoozedUntil: clearSnooze ? null : (snoozedUntil ?? this.snoozedUntil),
      followUpDate:
          clearFollowUp ? null : (followUpDate ?? this.followUpDate),
    );
  }

  Map<String, dynamic> toJson() => {
    if (snoozedUntil != null) 'snoozedUntil': snoozedUntil!.toIso8601String(),
    if (followUpDate != null)
      'followUpDate':
          '${followUpDate!.year.toString().padLeft(4, '0')}-'
          '${followUpDate!.month.toString().padLeft(2, '0')}-'
          '${followUpDate!.day.toString().padLeft(2, '0')}',
  };

  factory AlunoFollowUpEntry.fromJson(Map<String, dynamic> json) {
    DateTime? parseSnooze(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    DateTime? parseDate(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) return null;
      return DateTime(parsed.year, parsed.month, parsed.day);
    }

    return AlunoFollowUpEntry(
      snoozedUntil: parseSnooze(json['snoozedUntil'] as String?),
      followUpDate: parseDate(json['followUpDate'] as String?),
    );
  }
}

class AlunoFollowUpStore {
  static const _storageKey = 'aluno_followup_map_v1';

  /// Days without training before surfacing in "Contato hoje".
  static const int diasSemTreinoLimite = 3;

  static Future<Map<int, AlunoFollowUpEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(
          int.parse(key),
          AlunoFollowUpEntry.fromJson(value as Map<String, dynamic>),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveAll(Map<int, AlunoFollowUpEntry> map) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      map.map((key, value) => MapEntry('$key', value.toJson())),
    );
    await prefs.setString(_storageKey, encoded);
  }

  static Future<Map<int, AlunoFollowUpEntry>> _upsert(
    int alunoId,
    AlunoFollowUpEntry Function(AlunoFollowUpEntry? current) update,
  ) async {
    final all = await loadAll();
    final current = all[alunoId];
    all[alunoId] = update(current);
    await _saveAll(all);
    return all;
  }

  static Future<Map<int, AlunoFollowUpEntry>> snooze(
    int alunoId, {
    Duration duration = const Duration(hours: 24),
  }) {
    final until = DateTime.now().add(duration);
    return _upsert(
      alunoId,
      (current) => (current ?? const AlunoFollowUpEntry()).copyWith(
        snoozedUntil: until,
      ),
    );
  }

  static Future<Map<int, AlunoFollowUpEntry>> clearSnooze(int alunoId) {
    return _upsert(
      alunoId,
      (current) => (current ?? const AlunoFollowUpEntry()).copyWith(
        clearSnooze: true,
      ),
    );
  }

  static Future<Map<int, AlunoFollowUpEntry>> setFollowUpDate(
    int alunoId,
    DateTime date,
  ) {
    final normalized = DateTime(date.year, date.month, date.day);
    return _upsert(
      alunoId,
      (current) => (current ?? const AlunoFollowUpEntry()).copyWith(
        followUpDate: normalized,
        clearSnooze: true,
      ),
    );
  }

  static Future<Map<int, AlunoFollowUpEntry>> clearFollowUp(int alunoId) {
    return _upsert(
      alunoId,
      (current) => (current ?? const AlunoFollowUpEntry()).copyWith(
        clearFollowUp: true,
      ),
    );
  }
}
