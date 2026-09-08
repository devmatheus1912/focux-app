import 'package:flutter/material.dart';

import '../../../core/widgets/fx_form_sheet.dart';

/// Copy “tier gold” do studio — 5 ajudas no máximo.
abstract final class LandingStudioGuidance {
  LandingStudioGuidance._();

  static const heroTitle = 'Foto de capa';
  static const heroBody =
      'Use uma foto SUA, nítida, de meio corpo ou ambiente de treino. '
      'Essa é a primeira impressão do lead.\n\n'
      'Evite: foto de outra pessoa, print do Instagram, imagem genérica de academia.\n'
      'Bom: você treinando ou em pose profissional, luz boa, resolução alta.';

  static const bioPhotoTitle = 'Foto sua na prova';
  static const bioPhotoBody =
      'Se for mostrar foto aqui, precisa estar nítida (lado maior ≥ 800px). '
      'Avatar pequeno do Google fica pixelado e amador.\n\n'
      'Evite: foto de perfil 96px / thumb do Google.\n'
      'Bom: retrato ou foto de treino em boa resolução.';

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

  static const publishTitle = 'Antes de publicar';

  static const needsProofBanner =
      'Sua página está ok, mas fica mais forte com prova real ou foto boa.';

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

  static bool isProfessionalReady({
    required String? heroImageUrl,
    required String ofertaPreco,
    required bool needsProof,
    required String provaTexto,
    required String? bioImageUrl,
    required String heroTitle,
    required String primaryCta,
    required String whatsapp,
  }) {
    final hasHero = (heroImageUrl ?? '').trim().isNotEmpty;
    final hasPrice = ofertaPreco.trim().isNotEmpty;
    final proofOk = provaSocialOk(
      needsProof: needsProof,
      provaTexto: provaTexto,
      bioImageUrl: bioImageUrl,
    );
    final copyOk =
        heroTitle.trim().isNotEmpty && primaryCta.trim().isNotEmpty;
    final waOk = whatsapp.trim().isNotEmpty;
    return hasHero && hasPrice && proofOk && copyOk && waOk;
  }

  static List<String> missingForPublish({
    required String? heroImageUrl,
    required String ofertaPreco,
    required bool needsProof,
    required String provaTexto,
    required String? bioImageUrl,
    required String heroTitle,
    required String primaryCta,
    required String whatsapp,
    required bool podePublicar,
  }) {
    final missing = <String>[];
    if ((heroImageUrl ?? '').trim().isEmpty) {
      missing.add('Falta foto de capa (hero).');
    }
    if (ofertaPreco.trim().isEmpty) {
      missing.add('Falta preço na oferta.');
    }
    if (needsProof &&
        !provaSocialOk(
          needsProof: needsProof,
          provaTexto: provaTexto,
          bioImageUrl: bioImageUrl,
        )) {
      missing.add('Prova fraca: CREF sozinho. Melhor subir depoimento ou foto.');
    }
    if (heroTitle.trim().isEmpty || primaryCta.trim().isEmpty) {
      missing.add('Falta título ou CTA gerados.');
    }
    if (whatsapp.trim().isEmpty) {
      missing.add('Falta WhatsApp na entrevista.');
    }
    if (!podePublicar) {
      missing.add('Publicação bloqueada pelo servidor — revise os campos obrigatórios.');
    }
    return missing;
  }

  static String publishHelpBody({
    required List<String> missing,
    required bool podePublicar,
  }) {
    if (missing.isEmpty && podePublicar) {
      return 'Tudo certo pra publicar.';
    }
    return missing.join('\n');
  }

  static String readinessLabel({required bool ready}) =>
      ready ? 'Pronto pra vender' : 'Quase lá';

  static String readinessCaption({required bool ready}) =>
      ready
          ? 'Página profissional: capa, preço e prova em ordem.'
          : 'Complete capa, preço e prova real para parecer site caro.';
}
