import 'package:flutter/material.dart';

import '../../../core/widgets/fx_form_sheet.dart';
import '../../../l10n/app_localizations.dart';

enum LandingSecao {
  capa,
  sobre,
  metodo,
  inclui,
  planos,
  depoimentos,
  perguntas,
  contato,
}

/// Texto da IA existe nestas seções; as outras são dados do personal.
bool landingSecaoAceitaIa(LandingSecao secao) => switch (secao) {
  LandingSecao.planos || LandingSecao.depoimentos => false,
  _ => true,
};

String landingSecaoTitulo(S s, LandingSecao secao) => switch (secao) {
  LandingSecao.capa => s.landingSecaoCapa,
  LandingSecao.sobre => s.landingSecaoSobre,
  LandingSecao.metodo => s.landingSecaoMetodo,
  LandingSecao.inclui => s.landingSecaoInclui,
  LandingSecao.planos => s.landingSecaoPlanos,
  LandingSecao.depoimentos => s.landingSecaoDepoimentos,
  LandingSecao.perguntas => s.landingSecaoPerguntas,
  LandingSecao.contato => s.landingSecaoContato,
};

typedef LandingPendencia = ({String texto, LandingSecao secao});

/// O que falta, cada item levando à seção onde se resolve.
List<LandingPendencia> landingPendencias(
  S s, {
  required String? heroImageUrl,
  required String ofertaPreco,
  required bool needsProof,
  required String provaTexto,
  required String? bioImageUrl,
  required String heroTitle,
  required String primaryCta,
  required String whatsapp,
}) => [
  if ((heroImageUrl ?? '').trim().isEmpty)
    (texto: s.landingFaltaCapa, secao: LandingSecao.capa),
  if (heroTitle.trim().isEmpty || primaryCta.trim().isEmpty)
    (texto: s.landingFaltaTitulo, secao: LandingSecao.capa),
  if (ofertaPreco.trim().isEmpty)
    (texto: s.landingFaltaPreco, secao: LandingSecao.planos),
  if (!LandingStudioGuidance.provaSocialOk(
    needsProof: needsProof,
    provaTexto: provaTexto,
    bioImageUrl: bioImageUrl,
  ))
    (texto: s.landingFaltaProva, secao: LandingSecao.depoimentos),
  if (whatsapp.trim().isEmpty)
    (texto: s.landingFaltaWhatsapp, secao: LandingSecao.contato),
];

/// Ajudas curtas do editor.
abstract final class LandingStudioGuidance {
  LandingStudioGuidance._();

  static const provaTitle = 'Prova que convence';
  static const provaBody =
      'Escreva um resultado real, depoimento ou histórico curto. '
      'CREF sozinho não conta como prova social.\n\n'
      'Evite: só “CREF 01561-G”.\n'
      'Bom: “Acompanhamento contínuo com alunos de hipertrofia há X anos” '
      'ou um depoimento curto real.';

  static const ofertaTitle = 'Oferta clara';
  static const ofertaBody =
      'Nome da oferta + o que inclui + preço. Sem preço a página parece incompleta.\n\n'
      'Evite: só “Consultoria personalizada” sem valor.\n'
      'Bom: “Consultoria online — treino no app e ajustes semanais — R\$ 350/mês.”';

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return showFxNoticeSheet(
      context,
      title: title,
      message: body,
      actionLabel: 'Entendi',
    );
  }

  static bool isCrefOnly(String prova) {
    final t = prova.trim();
    if (t.isEmpty) return true;
    final compact = t.replaceAll(RegExp(r'\s+'), ' ');
    return RegExp(
      r'^CREF[\s:-]*[\w./-]+$',
      caseSensitive: false,
    ).hasMatch(compact);
  }

  static bool provaSocialOk({
    required bool needsProof,
    required String provaTexto,
    required String? bioImageUrl,
  }) {
    if (!needsProof) return true;
    if ((bioImageUrl ?? '').trim().isNotEmpty) return true;
    final p = provaTexto.trim();
    return p.length > 20 && !isCrefOnly(p);
  }
}
