class CheckinPersonalItem {
  const CheckinPersonalItem({
    required this.id,
    required this.alunoId,
    required this.alunoNome,
    required this.treinoNome,
    this.fotoUrl,
    this.iniciadoEm,
  });

  final int id;
  final int alunoId;
  final String alunoNome;
  final String treinoNome;
  final String? fotoUrl;
  final DateTime? iniciadoEm;

  factory CheckinPersonalItem.fromJson(Map<String, dynamic> json) {
    return CheckinPersonalItem(
      id: (json['id'] as num).toInt(),
      alunoId: (json['alunoId'] as num).toInt(),
      alunoNome: json['alunoNome'] as String? ?? '',
      treinoNome: json['treinoNome'] as String? ?? '',
      fotoUrl: json['fotoUrl'] as String?,
      iniciadoEm: DateTime.tryParse(json['iniciadoEm']?.toString() ?? ''),
    );
  }
}

class CheckinPersonalHomeBundle {
  const CheckinPersonalHomeBundle({
    required this.checkinsHoje,
    required this.hoje,
    required this.semana,
  });

  final int checkinsHoje;
  final List<CheckinPersonalItem> hoje;
  final List<CheckinPersonalItem> semana;

  factory CheckinPersonalHomeBundle.fromJson(Map<String, dynamic> json) {
    List<CheckinPersonalItem> parse(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((row) => CheckinPersonalItem.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    }

    return CheckinPersonalHomeBundle(
      checkinsHoje: (json['checkinsHoje'] as num?)?.toInt() ?? 0,
      hoje: parse('hoje'),
      semana: parse('semana'),
    );
  }
}
