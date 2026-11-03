import '../data/retencao_repository.dart';

/// "Sem treino há 12 dias · +1": o principal motivo e quantos mais há.
String? retencaoMotivoCurto(RetencaoAlunoScore score) {
  final motivos = score.motivos;
  if (motivos.isEmpty) return null;
  return motivos.length == 1
      ? motivos.first
      : '${motivos.first} · +${motivos.length - 1}';
}

/// Comparação com a semana passada; nula sem histórico ou sem mudança.
String? retencaoVariacaoSemanal(RetencaoHome home) {
  final antes = home.altoSemanaAnterior;
  if (antes == null) return null;
  final diferenca = home.alto - antes;
  if (diferenca == 0) return null;
  return diferenca > 0
      ? '$diferenca a mais que na semana passada'
      : '${-diferenca} a menos que na semana passada';
}
