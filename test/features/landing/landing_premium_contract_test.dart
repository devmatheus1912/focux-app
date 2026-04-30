import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/landing/models/public_personal_data.dart';
import 'package:focux_app/features/perfil/data/perfil_repository.dart';

void main() {
  test('public landing parses FAQ tracking and AI hero fields', () {
    final data = PublicPersonalData.fromJson({
      'nomePersonal': 'Matheus',
      'totalAlunos': 42,
      'anoCriacao': 2024,
      'plano': 'ENTERPRISE',
      'trackingId': 'campanha-instagram-abril',
      'heroPrompt': 'studio premium functional training',
      'heroImageUrl': 'https://cdn.focux.app/landing/matheus.png',
      'generatedHeroImageUrl': 'https://image.pollinations.ai/prompt/studio',
      'heroImageStatus': 'MANUAL',
      'heroImageBrief': 'studio premium functional training',
      'faq': [
        {
          'pergunta': 'Preciso treinar todos os dias?',
          'resposta': 'Nao. O plano respeita sua rotina.',
        },
      ],
    });

    expect(data.trackingId, 'campanha-instagram-abril');
    expect(data.heroPrompt, 'studio premium functional training');
    expect(data.heroImageUrl, endsWith('matheus.png'));
    expect(data.generatedHeroImageUrl, contains('pollinations'));
    expect(data.heroImageStatus, 'MANUAL');
    expect(data.heroImageBrief, contains('studio premium'));
    expect(data.faq.single.pergunta, contains('treinar'));
  });

  test('profile landing config parses editable FAQ and AI hero fields', () {
    final perfil = PerfilPersonal.fromJson({
      'id': 1,
      'nome': 'Matheus',
      'email': 'm@focux.app',
      'plano': 'ENTERPRISE',
      'trackingId': 'utm-live',
      'heroPrompt': 'unique hero image',
      'heroImageUrl': 'https://cdn.focux.app/hero.png',
      'generatedHeroImageUrl': 'https://image.pollinations.ai/prompt/unique',
      'heroImageStatus': 'AI_GENERATED_URL',
      'heroImageBrief': 'unique hero image',
      'faq': [
        {'pergunta': 'Como funciona?', 'resposta': 'Com acompanhamento.'},
      ],
    });

    expect(perfil.trackingId, 'utm-live');
    expect(perfil.heroPrompt, 'unique hero image');
    expect(perfil.heroImageUrl, contains('hero.png'));
    expect(perfil.generatedHeroImageUrl, contains('pollinations'));
    expect(perfil.heroImageStatus, 'AI_GENERATED_URL');
    expect(perfil.heroImageBrief, 'unique hero image');
    expect(perfil.faq.single.resposta, 'Com acompanhamento.');
  });

  test('landing public surface exposes FAQ and tracked CTA contracts', () {
    final landing =
        File(
          'lib/features/landing/screens/personal_public_landing_screen.dart',
        ).readAsStringSync();
    final hero =
        File(
          'lib/features/landing/widgets/hero_section.dart',
        ).readAsStringSync();
    final ofertas =
        File(
          'lib/features/landing/widgets/ofertas_section.dart',
        ).readAsStringSync();
    final metodo =
        File(
          'lib/features/landing/widgets/metodo_section.dart',
        ).readAsStringSync();
    final cta =
        File(
          'lib/features/landing/widgets/cta_final_section.dart',
        ).readAsStringSync();
    final tracking =
        File(
          'lib/features/landing/data/landing_tracking.dart',
        ).readAsStringSync();
    final identidade =
        File(
          'lib/features/perfil/screens/identidade_visual_screen.dart',
        ).readAsStringSync();

    expect(landing, contains('FaqSection(data: data'));
    expect(landing, contains("eventType: 'landing_view'"));
    expect(hero, contains('data.heroImageUrl'));
    expect(hero, contains('data.generatedHeroImageUrl'));
    expect(hero, contains('_LandingBrandCanvas'));
    expect(hero, contains('_LandingSignature'));
    expect(hero, contains('_isAiGeneratedHeroUrl'));
    expect(hero, contains('Assinatura'));
    expect(hero, isNot(contains('webHtmlElementStrategy')));
    expect(hero, isNot(contains('WebHtmlElementStrategy.prefer')));
    expect(hero, isNot(contains('Ver apresentacao')));
    expect(hero, contains('VideoPlayerController.networkUrl'));
    expect(hero, contains('_PresentationVideoCard'));
    expect(hero, contains('_isDirectVideoUrl'));
    expect(hero, contains("source: 'landing'"));
    expect(ofertas, contains("source: 'landing_offer'"));
    expect(ofertas, contains('_ServiceTile'));
    expect(ofertas, contains('_PackageTile'));
    expect(ofertas, contains('MAIS PROCURADO'));
    expect(metodo, contains('METODO PREMIUM'));
    expect(metodo, contains('_MetodoCard'));
    expect(cta, contains("source: 'landing_cta'"));
    expect(tracking, contains(r'/api/public/personal/$slug/eventos'));
    expect(tracking, contains('landingRegisterPath'));
    expect(tracking, contains('eventType'));
    expect(identidade, contains('generatedHeroImageUrl'));
    expect(identidade, contains('_GeneratedHeroAssetCard'));
    expect(identidade, contains('_PremiumHeroPreviewCanvas'));
    expect(identidade, contains('Aplicar como fundo premium'));
    expect(identidade, contains('sem depender de imagem externa'));
    expect(identidade, isNot(contains('webHtmlElementStrategy')));
    expect(identidade, isNot(contains('WebHtmlElementStrategy.prefer')));
    expect(identidade, contains('_buildGeneratedHeroUrl'));
    expect(identidade, contains('_applyHeroAsBackground'));
    expect(identidade, contains("_heroImageCtrl.clear()"));
    expect(identidade, contains("body['heroImageUrl']"));
    expect(identidade, contains("'URL manual de imagem'"));
    expect(identidade, contains('Video de apresentacao enviado e salvo'));
    expect(identidade, contains('_pickPresentationVideo'));
    expect(identidade, contains("resourceType: 'video'"));
    expect(identidade, contains('Subir video de apresentacao'));
    expect(identidade, contains('Trocar video de apresentacao'));
    expect(identidade, contains('_LandingMediaStatusCard'));
  });
}
