import '../utils/ia_progressao_carga_delta.dart';

int? _asInt(Object? raw) => switch (raw) {
  final int value => value,
  final num value => value.toInt(),
  final String value => int.tryParse(value),
  _ => null,
};

String? _blankToNull(Object? raw) {
  final text = raw?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

class IaProgressaoExerciseRow {
  const IaProgressaoExerciseRow({
    required this.exercicio,
    required this.cargaAtual,
    required this.cargaSugerida,
    required this.justificativa,
    this.deltaLabel,
    this.treinoExercicioId,
  });

  final String exercicio;
  final String cargaAtual;
  final String cargaSugerida;
  final String justificativa;
  final String? deltaLabel;
  final int? treinoExercicioId;
}

/// Resultado de uma geração; a tela, o "Copiar" e o PDF leem o mesmo objeto.
class IaProgressaoCargaResult {
  const IaProgressaoCargaResult({
    required this.resposta,
    this.intro,
    this.exercises = const [],
    this.footer,
    this.sugestoesRegistradas = 0,
    this.geradoEm,
  });

  final String resposta;
  final String? intro;
  final List<IaProgressaoExerciseRow> exercises;
  final String? footer;
  final int sugestoesRegistradas;
  final DateTime? geradoEm;

  factory IaProgressaoCargaResult.fromApi(
    Map<String, dynamic> json, {
    DateTime? geradoEm,
  }) {
    final rawExercises = json['exercicios'];
    final exercises =
        rawExercises is List
            ? rawExercises
                .whereType<Map>()
                .map((row) {
                  final atual = row['cargaAtual']?.toString() ?? '';
                  final sugerida = row['cargaSugerida']?.toString() ?? '';
                  final deltaRaw = row['deltaKg'];
                  return IaProgressaoExerciseRow(
                    exercicio: row['exercicio']?.toString() ?? '',
                    cargaAtual: atual,
                    cargaSugerida: sugerida,
                    justificativa: row['justificativa']?.toString() ?? '',
                    deltaLabel:
                        deltaRaw != null
                            ? formatProgressaoDeltaKg(deltaRaw)
                            : computeProgressaoDeltaLabel(atual, sugerida),
                    treinoExercicioId: _asInt(row['treinoExercicioId']),
                  );
                })
                .where((row) => row.exercicio.isNotEmpty)
                .toList(growable: false)
            : const <IaProgressaoExerciseRow>[];

    return IaProgressaoCargaResult(
      resposta: (json['resposta'] as String?) ?? '',
      intro: _blankToNull(json['intro']),
      exercises: exercises,
      footer: _blankToNull(json['footer']),
      sugestoesRegistradas: _asInt(json['sugestoesRegistradas']) ?? 0,
      geradoEm: geradoEm,
    );
  }

  String toPlainText({String? alunoNome, String? geradoLabel}) {
    final buf = StringBuffer();
    final nome = alunoNome?.trim() ?? '';
    buf.writeln(
      nome.isEmpty ? 'Progressão de carga' : 'Progressão de carga · $nome',
    );
    if (geradoLabel != null) buf.writeln(geradoLabel);
    buf.writeln();
    if (intro != null) {
      buf.writeln(intro);
      buf.writeln();
    }
    if (exercises.isEmpty) {
      buf.writeln(resposta.trim());
    }
    for (final e in exercises) {
      final delta = e.deltaLabel == null ? '' : ' (${e.deltaLabel})';
      buf.writeln('• ${e.exercicio}');
      buf.writeln('  ${e.cargaAtual} → ${e.cargaSugerida}$delta');
      if (e.justificativa.isNotEmpty) buf.writeln('  ${e.justificativa}');
    }
    if (footer != null) {
      buf.writeln();
      buf.writeln(footer);
    }
    return buf.toString().trim();
  }
}
