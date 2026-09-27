import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/aluno_home_insight.dart';

typedef AlunoInsightTexto = ({String titulo, String detalhe});

/// Texto do insight no idioma do app; chave ou param inválido → texto pt do servidor.
AlunoInsightTexto alunoInsightTexto(S s, AlunoHomeInsight insight) {
  final local = _localizado(s, insight);
  if (local != null) return (titulo: local.$1, detalhe: local.$2);
  return (titulo: insight.titulo, detalhe: insight.mensagem);
}

IconData alunoInsightIcone(AlunoInsightTipo tipo) => switch (tipo) {
  AlunoInsightTipo.volumeSubindo => Icons.trending_up_rounded,
  AlunoInsightTipo.ritmoCaiu => Icons.trending_down_rounded,
};

(String, String)? _localizado(S s, AlunoHomeInsight insight) {
  String? numero(String k) {
    final raw = insight.params[k];
    if (raw == null || double.tryParse(raw) == null) return null;
    return s.localeName.startsWith('en') ? raw : raw.replaceAll('.', ',');
  }

  switch (insight.chave) {
    case 'insightVolumeSubindo':
      final pct = numero('pct');
      if (pct == null) return null;
      return (s.insightVolumeSubindoTitulo, s.insightVolumeSubindoDetalhe(pct));
    case 'insightRitmoCaiu':
      final media = numero('media');
      if (media == null) return null;
      return (s.insightRitmoCaiuTitulo, s.insightRitmoCaiuDetalhe(media));
  }
  return null;
}
