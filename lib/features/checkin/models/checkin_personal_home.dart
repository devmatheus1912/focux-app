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

class CheckinPersonalPendente {
  const CheckinPersonalPendente({
    required this.alunoId,
    required this.alunoNome,
    required this.treinoId,
    required this.treinoNome,
  });

  final int alunoId;
  final String alunoNome;
  final int treinoId;
  final String treinoNome;

  factory CheckinPersonalPendente.fromJson(Map<String, dynamic> json) {
    return CheckinPersonalPendente(
      alunoId: (json['alunoId'] as num).toInt(),
      alunoNome: json['alunoNome'] as String? ?? '',
      treinoId: (json['treinoId'] as num).toInt(),
      treinoNome: json['treinoNome'] as String? ?? '',
    );
  }
}

class CheckinPersonalHomeBundle {
  const CheckinPersonalHomeBundle({
    required this.checkinsHoje,
    required this.hoje,
    required this.semana,
    this.itens = const [],
    this.page = 0,
    this.totalItens = 0,
    this.hasNext = false,
    this.pendentes = const [],
  });

  final int checkinsHoje;
  final List<CheckinPersonalItem> hoje;
  final List<CheckinPersonalItem> semana;
  final List<CheckinPersonalItem> itens;
  final int page;
  final int totalItens;
  final bool hasNext;
  final List<CheckinPersonalPendente> pendentes;

  factory CheckinPersonalHomeBundle.fromJson(Map<String, dynamic> json) {
    List<CheckinPersonalItem> parse(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map(
            (row) =>
                CheckinPersonalItem.fromJson(Map<String, dynamic>.from(row)),
          )
          .toList();
    }

    final itens = parse('itens');
    final hoje = parse('hoje');
    final semana = parse('semana');
    final pendentesRaw = json['pendentes'];
    final pendentes = <CheckinPersonalPendente>[];
    if (pendentesRaw is List) {
      for (final row in pendentesRaw.whereType<Map>()) {
        pendentes.add(
          CheckinPersonalPendente.fromJson(Map<String, dynamic>.from(row)),
        );
      }
    }
    return CheckinPersonalHomeBundle(
      checkinsHoje: (json['checkinsHoje'] as num?)?.toInt() ?? 0,
      hoje: hoje,
      semana: semana,
      itens: itens.isEmpty ? [...hoje, ...semana] : itens,
      page: (json['page'] as num?)?.toInt() ?? 0,
      totalItens:
          (json['totalItens'] as num?)?.toInt() ??
          (itens.isEmpty ? hoje.length + semana.length : itens.length),
      hasNext: json['hasNext'] == true,
      pendentes: pendentes,
    );
  }
}
