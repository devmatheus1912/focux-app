import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/landing/models/public_personal_data.dart';
import 'package:focux_app/features/landing/widgets/landing_design_helpers.dart';
import 'package:focux_app/features/perfil/data/perfil_repository.dart';

void main() {
  test('public landing parses FAQ tracking and legacy hero fields', () {
    final data = PublicPersonalData.fromJson({
      'nomePersonal': 'Matheus',
      'totalAlunos': 42,
      'anoCriacao': 2024,
      'plano': 'ENTERPRISE',
      'trackingId': 'campanha-instagram-abril',
      'heroPrompt': 'studio premium functional training',
      'heroImageUrl': 'https://cdn.focux.app/landing/matheus.png',
      'bioImageUrl': 'https://cdn.focux.app/landing/bio-matheus.png',
      'generatedHeroImageUrl': 'https://image.pollinations.ai/prompt/studio',
      'heroImageStatus': 'MANUAL',
      'heroImageBrief': 'studio premium functional training',
      'heroTitle': 'Treino forte sem perder rotina',
      'heroSubtitle': 'Acompanhamento claro para evoluir com criterio.',
      'primaryCta': 'Quero minha avaliacao',
      'sectionOrder': ['ofertas', 'prova', 'sobre'],
      'hiddenSections': ['galeria'],
      'featuredPackageIndex': 1,
      'featuredTestimonialIndex': 2,
      'featuredPhotoIndex': 3,
      'offerCta': 'Quero esse plano',
      'finalCta': 'Comecar avaliacao',
      'contactCta': 'Copiar Instagram',
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
    expect(data.bioImageUrl, endsWith('bio-matheus.png'));
    expect(data.generatedHeroImageUrl, contains('pollinations'));
    expect(data.heroImageStatus, 'MANUAL');
    expect(data.heroImageBrief, contains('studio premium'));
    expect(data.heroTitle, 'Treino forte sem perder rotina');
    expect(data.heroSubtitle, contains('Acompanhamento claro'));
    expect(data.primaryCta, 'Quero minha avaliacao');
    expect(data.sectionOrder.first, 'ofertas');
    expect(data.hiddenSections.single, 'galeria');
    expect(data.featuredPackageIndex, 1);
    expect(data.featuredTestimonialIndex, 2);
    expect(data.featuredPhotoIndex, 3);
    expect(data.offerCta, 'Quero esse plano');
    expect(data.finalCta, 'Comecar avaliacao');
    expect(data.contactCta, 'Copiar Instagram');
    expect(data.faq.single.pergunta, contains('treinar'));
  });

  test('profile landing config parses editable FAQ and legacy hero fields', () {
    final perfil = PerfilPersonal.fromJson({
      'id': 1,
      'nome': 'Matheus',
      'email': 'm@focux.app',
      'plano': 'ENTERPRISE',
      'trackingId': 'utm-live',
      'heroPrompt': 'unique hero image',
      'heroImageUrl': 'https://cdn.focux.app/hero.png',
      'bioImageUrl': 'https://cdn.focux.app/bio.png',
      'generatedHeroImageUrl': 'https://image.pollinations.ai/prompt/unique',
      'heroImageStatus': 'AI_GENERATED_URL',
      'heroImageBrief': 'unique hero image',
      'heroTitle': 'Metodo para treinar melhor',
      'heroSubtitle': 'Mais clareza para cada fase.',
      'primaryCta': 'Entrar no plano',
      'sectionOrder': ['metodo', 'ofertas'],
      'hiddenSections': ['faq'],
      'featuredPackageIndex': 2,
      'featuredTestimonialIndex': 1,
      'featuredPhotoIndex': 4,
      'offerCta': 'Entrar no acompanhamento',
      'finalCta': 'Agendar avaliacao',
      'contactCta': 'Copiar contato',
      'faq': [
        {'pergunta': 'Como funciona?', 'resposta': 'Com acompanhamento.'},
      ],
    });

    expect(perfil.trackingId, 'utm-live');
    expect(perfil.heroPrompt, 'unique hero image');
    expect(perfil.heroImageUrl, contains('hero.png'));
    expect(perfil.bioImageUrl, contains('bio.png'));
    expect(perfil.generatedHeroImageUrl, contains('pollinations'));
    expect(perfil.heroImageStatus, 'AI_GENERATED_URL');
    expect(perfil.heroImageBrief, 'unique hero image');
    expect(perfil.heroTitle, 'Metodo para treinar melhor');
    expect(perfil.heroSubtitle, 'Mais clareza para cada fase.');
    expect(perfil.primaryCta, 'Entrar no plano');
    expect(perfil.sectionOrder, ['metodo', 'ofertas']);
    expect(perfil.hiddenSections, ['faq']);
    expect(perfil.featuredPackageIndex, 2);
    expect(perfil.featuredTestimonialIndex, 1);
    expect(perfil.featuredPhotoIndex, 4);
    expect(perfil.offerCta, 'Entrar no acompanhamento');
    expect(perfil.finalCta, 'Agendar avaliacao');
    expect(perfil.contactCta, 'Copiar contato');
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
    final designHelpers =
        File(
          'lib/features/landing/widgets/landing_design_helpers.dart',
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
    expect(landing, contains('_orderedSections'));
    expect(landing, contains('hiddenSections'));
    expect(landing, contains("eventType: 'landing_view'"));
    expect(hero, contains('LandingDesign.firstImageUrl'));
    expect(hero, contains('LandingDesign.heroPills'));
    expect(hero, contains('LandingDesign.heroCta'));
    expect(hero, contains('BoxFit.cover'));
    expect(hero, isNot(contains('data.generatedHeroImageUrl')));
    expect(hero, contains('_LandingBrandCanvas'));
    expect(hero, contains('_LandingSignature'));
    expect(hero, contains('_isAiGeneratedHeroUrl'));
    expect(hero, contains('_SignatureBadge'));
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
    expect(ofertas, contains('LandingDesign.formatPrice'));
    expect(ofertas, contains('LandingDesign.services'));
    expect(ofertas, contains('LandingDesign.packages'));
    expect(metodo, contains('METODO PREMIUM'));
    expect(metodo, contains('_MetodoCard'));
    expect(cta, contains("source: 'landing_cta'"));
    expect(cta, contains('LandingDesign.formatPrice'));
    expect(designHelpers, contains('showStudentCount'));
    expect(designHelpers, contains('yearsExperience'));
    expect(designHelpers, contains('hasValidCref'));
    expect(designHelpers, contains('123456'));
    expect(designHelpers, contains('Vagas'));
    expect(designHelpers, contains('static String? bioImageUrl'));
    expect(designHelpers, contains('static List<PublicLandingFaqItem> faq'));
    expect(tracking, contains(r'/api/public/personal/$slug/eventos'));
    expect(tracking, contains('landingRegisterPath'));
    expect(tracking, contains('eventType'));
    expect(identidade, isNot(contains('Imagem IA unica')));
    expect(identidade, isNot(contains('_GeneratedHeroAssetCard')));
    expect(identidade, isNot(contains('_buildGeneratedHeroUrl')));
    expect(identidade, isNot(contains('_applyHeroAsBackground')));
    expect(identidade, isNot(contains('Briefing para IA')));
    expect(identidade, isNot(contains("'URL manual de imagem'")));
    expect(identidade, contains('Foto principal da galeria'));
    expect(identidade, contains('Foto do personal na landing'));
    expect(identidade, contains('_pickBioPhoto'));
    expect(identidade, contains("folder: 'landing/bio'"));
    expect(identidade, contains('_BioPhotoPreview'));
    expect(identidade, contains('_LandingPremiumPlanner'));
    expect(identidade, contains('_LandingEditorialControls'));
    expect(identidade, contains('_LandingConversionHighlights'));
    expect(identidade, contains("'heroTitle': _heroTitleCtrl.text.trim()"));
    expect(identidade, contains("'sectionOrder': _sectionOrder"));
    expect(identidade, contains("'hiddenSections': _hiddenSections.toList()"));
    expect(
      identidade,
      contains("'featuredPackageIndex': _featuredPackageIndex"),
    );
    expect(identidade, contains("'offerCta': _offerCtaCtrl.text.trim()"));
    expect(identidade, contains('_PremiumLandingPreviewCard'));
    expect(identidade, contains('_PremiumHeroPreviewCanvas'));
    expect(identidade, isNot(contains('webHtmlElementStrategy')));
    expect(identidade, isNot(contains('WebHtmlElementStrategy.prefer')));
    expect(identidade, contains("body['heroImageUrl']"));
    expect(identidade, contains("body['bioImageUrl']"));
    expect(identidade, contains('A landing usa um palco 3D no hero'));
    expect(identidade, contains('Subir foto da bio'));
    expect(identidade, contains('Trocar foto da bio'));
    expect(identidade, contains('_LandingMediaStatusCard'));
  });

  test('premium landing design hides weak proof and formats offers', () {
    final data = PublicPersonalData.fromJson({
      'nomePersonal': 'Matheus Focux',
      'totalAlunos': 2,
      'anoCriacao': DateTime.now().year,
      'cref': '123456-G/SP',
      'especialidades': 'Hipertrofia',
      'heroImageUrl': 'https://cdn.focux.app/hero.jpg',
      'bioImageUrl': 'https://cdn.focux.app/bio.jpg',
      'slogan': 'Transformando vida através de movimento',
      'pacotes': [
        {
          'nome': 'Plano Mensal',
          'preco': '250',
          'descricao': 'Treino personalizado ajustes semanais.',
        },
      ],
      'faq': [
        {'pergunta': 'Preciso treinar todos dias?', 'resposta': 'Nao.'},
      ],
    });

    expect(LandingDesign.showStudentCount(data), isFalse);
    expect(LandingDesign.yearsExperience(data), 0);
    expect(LandingDesign.hasValidCref(data), isFalse);
    expect(
      LandingDesign.heroHeadline(data),
      'Plano de Hipertrofia com acompanhamento profissional.',
    );
    expect(LandingDesign.heroPills(data).first.value, 'Vagas');
    expect(LandingDesign.firstImageUrl(data), endsWith('hero.jpg'));
    expect(LandingDesign.bioImageUrl(data), endsWith('bio.jpg'));
    expect(LandingDesign.formatPrice(data.pacotes.single.preco), 'R\$ 250/mes');
    expect(LandingDesign.faq(data).length, greaterThanOrEqualTo(3));
  });

  test('landing conversion helpers prioritize offer proof and CTA copy', () {
    final data = PublicPersonalData.fromJson({
      'nomePersonal': 'Matheus Focux',
      'totalAlunos': 12,
      'anoCriacao': 2021,
      'plano': 'ENTERPRISE',
      'offerCta': 'Quero entrar',
      'finalCta': 'Agendar agora',
      'contactCta': 'Copiar perfil',
      'featuredPackageIndex': 10,
      'pacotes': [
        {'nome': 'Base', 'preco': '200'},
        {'nome': 'Premium', 'preco': '400'},
      ],
    });

    expect(LandingDesign.offerCta(data, data.pacotes.first), 'Quero entrar');
    expect(LandingDesign.finalCta(data), 'Agendar agora');
    expect(LandingDesign.contactCta(data), 'Copiar perfil');
    expect(LandingDesign.featuredIndex(data.featuredPackageIndex, 2), 1);
    expect(LandingDesign.prioritize(['a', 'b', 'c'], 2), ['c', 'a', 'b']);
  });
}
