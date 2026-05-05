enum Modalidade { musculacao, mobilidade, cardio }

enum PadraoMovimento {
  pushHorizontal,
  pushVertical,
  pullHorizontal,
  pullVertical,
  hinge,
  squat,
  lunge,
  carry,
  coreAntiExtensao,
  coreAntiRotacao,
  locomocao,
  isometricoGeral,
  mobilidadeDinamica,
  mobilidadeEstatica,
  smr,
  cardioEsteira,
  cardioBike,
  cardioEliptico,
  cardioHiit,
  cardioOutdoor,
  cardioStep,
}

enum GrupoMuscular {
  peito,
  costasLatissimo,
  costasRetangulares,
  ombroAnterior,
  ombroLateral,
  ombroPosterior,
  biceps,
  triceps,
  antebraco,
  quadriceps,
  posteriorCoxa,
  gluteo,
  panturrilha,
  adutor,
  abdutor,
  abdomen,
  obliquo,
  lombar,
  trapezio,
  fullBody,
}

enum Equipamento {
  barra,
  halter,
  kettlebell,
  maquina,
  polia,
  pesoCorporal,
  banda,
  smith,
  banco,
  trx,
  corda,
  bolaSuica,
  caixa,
  outros,
}

enum Espaco {
  academiaCompleta,
  academiaBasica,
  casaEquipada,
  casaSemEquipo,
  outdoor,
}

enum Dificuldade { iniciante, intermediario, avancado }

extension EnumBackendName on Enum {
  String get backendName {
    final value = name;
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
      if (i > 0 && isUpper) buffer.write('_');
      buffer.write(char.toUpperCase());
    }
    return buffer.toString();
  }
}

T? tryParseEnum<T extends Enum>(List<T> values, String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final normalized = raw.trim().toUpperCase();
  for (final value in values) {
    if (value.backendName == normalized) return value;
  }
  return null;
}

List<T> parseEnumCsv<T extends Enum>(List<T> values, Object? raw) {
  if (raw == null) return const [];
  if (raw is Iterable) {
    return raw
        .map((e) => tryParseEnum(values, e.toString()))
        .whereType<T>()
        .toList();
  }
  return raw
      .toString()
      .split(',')
      .map((e) => tryParseEnum(values, e))
      .whereType<T>()
      .toList();
}
