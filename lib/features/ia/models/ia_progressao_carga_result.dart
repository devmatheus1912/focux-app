import '../utils/ia_progressao_carga_delta.dart';
import '../utils/ia_progressao_result_parser.dart';

class IaProgressaoCargaResult {
  const IaProgressaoCargaResult({
    required this.resposta,
    this.intro,
    this.exercises = const [],
    this.footer,
    this.sugestoesRegistradas = 0,
  });

  final String resposta;
  final String? intro;
  final List<IaProgressaoExerciseRow> exercises;
  final String? footer;
  final int sugestoesRegistradas;

  factory IaProgressaoCargaResult.fromApi(Map<String, dynamic> json) {
    final resposta = (json['resposta'] as String?) ?? '';
    final intro = json['intro'] as String?;
    final footer = json['footer'] as String?;
    final registradas = switch (json['sugestoesRegistradas']) {
      final int value => value,
      final num value => value.toInt(),
      final String value => int.tryParse(value) ?? 0,
      _ => 0,
    };
    final rawExercises = json['exercicios'];

    if (rawExercises is List && rawExercises.isNotEmpty) {
      final exercises = rawExercises
          .whereType<Map>()
          .map((row) {
            final atual = row['cargaAtual']?.toString() ?? '';
            final sugerida = row['cargaSugerida']?.toString() ?? '';
            final deltaRaw = row['deltaKg'];
            final deltaLabel =
                deltaRaw != null
                    ? _deltaFromApi(deltaRaw)
                    : computeProgressaoDeltaLabel(atual, sugerida);
            return IaProgressaoExerciseRow(
              exercicio: row['exercicio']?.toString() ?? '',
              cargaAtual: atual,
              cargaSugerida: sugerida,
              justificativa: row['justificativa']?.toString() ?? '',
              deltaLabel: deltaLabel,
            );
          })
          .where((row) => row.exercicio.isNotEmpty)
          .toList(growable: false);

      if (exercises.isNotEmpty) {
        return IaProgressaoCargaResult(
          resposta: resposta,
          intro: intro,
          exercises: exercises,
          footer: footer,
          sugestoesRegistradas: registradas,
        );
      }
    }

    final parsed = parseIaProgressaoMarkdown(resposta);
    return IaProgressaoCargaResult(
      resposta: resposta,
      intro: parsed.intro ?? intro,
      exercises: parsed.exercises,
      footer: parsed.footer ?? footer,
      sugestoesRegistradas: registradas,
    );
  }

  IaProgressaoParsedResult toParsed() => IaProgressaoParsedResult(
    rawMarkdown: resposta,
    intro: intro,
    exercises: exercises,
    footer: footer,
  );

  static String? _deltaFromApi(Object raw) {
    final value = switch (raw) {
      final num n => n.toDouble(),
      final String s => double.tryParse(s.replaceAll(',', '.')),
      _ => null,
    };
    if (value == null || value.abs() < 0.01) return null;
    final sign = value > 0 ? '+' : '';
    final abs = value.abs();
    final formatted =
        abs == abs.roundToDouble()
            ? abs.toStringAsFixed(0)
            : abs.toStringAsFixed(1).replaceAll('.', ',');
    return '$sign$formatted kg';
  }
}
