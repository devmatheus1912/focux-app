import '../../../core/utils/pt_br_display.dart';
import '../../../l10n/app_localizations.dart';
import 'historico_detalhe_view.dart';

/// "Concluído · qua, 24 de set." ou "Em andamento".
String? historicoDetalheSubtitulo(S s, HistoricoDetalheView v) {
  if (!v.concluida) return s.historicoDetalheEmAndamento;
  final quando = v.concluidoEm;
  return quando == null ? null : s.historicoDetalheConcluidoEm(quando);
}

String historicoDetalheStatus(S s, HistoricoDetalheView v) {
  if (!v.concluida) return s.historicoDetalheEmAndamento;
  return v.semSeries
      ? s.historicoDetalheConcluidoSemSeries
      : s.historicoDetalheConcluido;
}

String? historicoComparacaoTexto(S s, HistoricoComparacao? c) => switch (c) {
  HistoricoComparacao.melhorou => s.historicoComparacaoMelhorou,
  HistoricoComparacao.caiu => s.historicoComparacaoCaiu,
  HistoricoComparacao.manteve => s.historicoComparacaoManteve,
  HistoricoComparacao.primeira => s.historicoComparacaoPrimeira,
  null => null,
};

String? historicoDestaqueTexto(S s, HistoricoDetalheView v) => switch (v
    .destaque) {
  final d? => s.historicoDestaqueCarga(
    d.exercicio,
    historicoDeltaKg(s, d.deltaKg),
  ),
  null => null,
};

/// "N de M"; sem plano conhecido, só "N".
String historicoNDeMTexto(S s, int feitos, int total) =>
    total > 0 ? s.historicoNDeM(feitos, total) : '$feitos';

String historicoKgTexto(S s, double kg) {
  if (kg >= 1000) {
    final mil = kg / 1000;
    return s.historicoMilKg(mil >= 10 ? mil.toStringAsFixed(0) : _decimal(mil));
  }
  return s.historicoKg(_decimal(kg));
}

/// "+2,5 kg" / "-5 kg".
String historicoDeltaKg(S s, double delta) {
  final sinal = delta > 0 ? '+' : '';
  return '$sinal${s.historicoKg(_decimal(delta))}';
}

/// "20 kg · 3 de 4 séries · RPE 8 · Dor · +2,5 kg vs anterior".
String historicoExercicioDetalhe(S s, HistoricoExercicioLinha l) {
  final planejadas = l.seriesPlanejadas;
  final delta = l.deltaCargaKg;
  return [
    if (l.cargaKg case final c?) historicoKgTexto(s, c),
    if (l.seriesFeitas == 0)
      s.historicoSemSeries
    else if (planejadas != null)
      s.historicoSeriesNDeM(l.seriesFeitas, planejadas)
    else
      s.historicoSeriesFeitas(l.seriesFeitas),
    if (l.rpe case final rpe?) s.historicoRpe(rpe),
    if (l.dor) s.historicoDor,
    if (delta != null)
      delta.abs() < 0.05
          ? s.historicoCargaIgual
          : s.historicoCargaDelta(historicoDeltaKg(s, delta)),
  ].join(' · ');
}

String historicoRecordeDetalhe(S s, HistoricoRecordeLinha r) {
  if (r.mensagem.isNotEmpty) return r.mensagem;
  final carga = r.cargaKg;
  return carga == null ? s.historicoRecorde : historicoKgTexto(s, carga);
}

String _decimal(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : formatBrDecimal(v);
