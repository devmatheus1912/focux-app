import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/aluno_home_insight.dart';

typedef AlunoInsightTexto = ({String titulo, String detalhe, String? cta});

/// Texto do insight no idioma do app; chave ou param inválido → texto pt do servidor.
AlunoInsightTexto alunoInsightTexto(S s, AlunoHomeInsight insight) {
  final cta = _cta(s, insight.acao);
  final local = _localizado(s, insight);
  if (local != null) {
    return (titulo: local.$1, detalhe: local.$2, cta: cta);
  }
  final evidencia = insight.evidencia;
  return (
    titulo: insight.titulo,
    detalhe:
        evidencia == null ? insight.mensagem : '${insight.mensagem} · $evidencia',
    cta: cta,
  );
}

IconData alunoInsightIcone(AlunoInsightTipo tipo) => switch (tipo) {
  AlunoInsightTipo.pr => Icons.emoji_events_outlined,
  AlunoInsightTipo.forcaSubindo ||
  AlunoInsightTipo.volumeSubindo => Icons.trending_up_rounded,
  AlunoInsightTipo.recuperacao => Icons.bedtime_outlined,
  AlunoInsightTipo.metaAtingida => Icons.check_circle_outline_rounded,
  AlunoInsightTipo.ritmoCaiu => Icons.trending_down_rounded,
  _ => Icons.insights_rounded,
};

(String, String)? _localizado(S s, AlunoHomeInsight insight) {
  final p = insight.params;
  int? inteiro(String k) => int.tryParse(p[k] ?? '');
  String? numero(String k) {
    final raw = p[k];
    if (raw == null || double.tryParse(raw) == null) return null;
    return s.localeName.startsWith('en') ? raw : raw.replaceAll('.', ',');
  }

  switch (insight.chave) {
    case 'insightNovo':
      return (s.insightNovoTitulo, s.insightNovoDetalhe);
    case 'insightRecuperacao':
      final score = inteiro('score');
      if (score == null) return null;
      return (s.insightRecuperacaoTitulo, s.insightRecuperacaoDetalhe(score));
    case 'insightPr':
      final exercicio = p['exercicio'];
      final carga = numero('cargaKg');
      final dias = inteiro('dias');
      if (exercicio == null || carga == null || dias == null) return null;
      return (s.insightPrTitulo, s.insightPrDetalhe(exercicio, carga, dias));
    case 'insightRetorno':
      final dias = inteiro('dias');
      if (dias == null) return null;
      return (s.insightRetornoTitulo, s.insightRetornoDetalhe(dias));
    case 'insightMetaAtingida':
      final feitos = inteiro('feitos');
      final meta = inteiro('meta');
      if (feitos == null || meta == null) return null;
      return (
        s.insightMetaAtingidaTitulo,
        s.insightMetaAtingidaDetalhe(feitos, meta),
      );
    case 'insightForcaSubindo':
      final pct = numero('pct');
      final n = inteiro('n');
      if (pct == null || n == null) return null;
      return (s.insightForcaSubindoTitulo, s.insightForcaSubindoDetalhe(pct, n));
    case 'insightVolumeSubindo':
      final pct = numero('pct');
      if (pct == null) return null;
      return (s.insightVolumeSubindoTitulo, s.insightVolumeSubindoDetalhe(pct));
    case 'insightConsistente':
      final feitos = inteiro('feitos');
      if (feitos == null) return null;
      return (s.insightConsistenteTitulo, s.insightTreinos7dDetalhe(feitos));
    case 'insightSequencia':
      final semanas = inteiro('semanas');
      if (semanas == null) return null;
      return (s.insightConsistenteTitulo, s.insightSequenciaDetalhe(semanas));
    case 'insightRitmoCaiu':
      final feitos = inteiro('feitos');
      if (feitos == null) return null;
      return (s.insightRitmoCaiuTitulo, s.insightTreinos7dDetalhe(feitos));
    case 'insightDadosInsuficientes':
      return (
        s.insightDadosInsuficientesTitulo,
        s.insightDadosInsuficientesDetalhe,
      );
  }
  return null;
}

String? _cta(S s, AlunoInsightAcao? acao) {
  if (acao == null) return null;
  return switch (acao.rota) {
    '/checkin/treinos' => s.insightCtaTreinos,
    '/checkin/historico' => s.insightCtaHistorico,
    '/saude' => s.insightCtaSaude,
    _ => acao.cta,
  };
}
