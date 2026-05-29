import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/perfil/data/landing_growth_repository.dart';
import 'package:focux_app/features/perfil/data/perfil_repository.dart';
import 'package:focux_app/features/perfil/screens/landing_editor_checklist.dart';
import 'package:focux_app/features/perfil/screens/landing_editor_quality.dart';
import 'package:focux_app/features/perfil/screens/landing_editor_sections.dart';
import 'package:focux_app/features/perfil/screens/landing_preset_mapper.dart';
import 'package:focux_app/features/perfil/screens/landing_section_templates.dart';

void main() {
  test('normalizeLandingSectionOrder deduplicates legacy keys', () {
    final result = normalizeLandingSectionOrder([
      'prova',
      'metodo',
      'sobre',
      'ofertas',
      'prova',
      'app',
    ]);

    expect(result, contains('depoimentos'));
    expect(result, contains('processo'));
    expect(result, contains('bio'));
    expect(result, contains('pacotes'));
    expect(result.indexOf('depoimentos'), lessThan(result.indexOf('processo')));
  });

  test('landingSectionLabel maps legacy keys to PT-BR', () {
    expect(landingSectionLabel('prova'), 'Depoimentos');
    expect(landingSectionLabel('metodo'), 'Como funciona');
    expect(landingSectionLabel('sobre'), 'Sobre você');
  });

  test('landingChecklistLabel humanizes backend jargon', () {
    expect(landingChecklistLabel('slug', 'Slug público'), 'Link público configurado');
    expect(landingChecklistLabel('cref', 'CREF'), 'CREF informado no perfil');
    expect(landingChecklistLabel('cta', 'CTA principal'), 'Texto do botão principal definido');
    expect(landingChecklistLabel('captura', 'Modo Captura'), 'Formulário rápido disponível');
  });

  test('landingTextLooksLikePlaceholder detects test garbage', () {
    expect(landingTextLooksLikePlaceholder('dadsdad'), isTrue);
    expect(landingTextLooksLikePlaceholder('teste123'), isTrue);
    expect(landingTextLooksLikePlaceholder('Treino personalizado online'), isFalse);
  });

  test('landingContentIssues groups multiple placeholder FAQ items', () {
    final issues = landingContentIssues(
      faq: [
        (pergunta: 'dadsdad', resposta: 'ok'),
        (pergunta: 'teste', resposta: 'abc'),
        (pergunta: 'real?', resposta: 'sim'),
      ],
      primaryCta: 'Agendar avaliação',
      heroTitle: 'Transforme seu corpo',
    );
    expect(issues, hasLength(1));
    expect(issues.first.message, contains('2 perguntas frequentes'));
  });

  test('landingContentIssuesForReview expands grouped FAQ issues', () {
    final issues = landingContentIssuesForReview(
      faq: [
        (pergunta: 'dadsdad', resposta: 'ok'),
        (pergunta: 'teste', resposta: 'abc'),
        (pergunta: 'real?', resposta: 'sim'),
      ],
      primaryCta: 'Agendar avaliação',
      heroTitle: 'Transforme seu corpo',
    );
    expect(issues, hasLength(2));
    expect(issues[0].faqIndex, 0);
    expect(issues[1].faqIndex, 1);
  });

  test('landingCtaAccentSuggestion fixes avaliacao', () {
    expect(
      landingCtaAccentSuggestion('Quero minha avaliacao'),
      'Quero minha avaliação',
    );
  });

  test('landingPolishShortText trims and capitalizes', () {
    expect(landingPolishShortText('  agendar avaliacao  '), 'Agendar avaliacao');
    expect(landingPolishShortText(''), '');
  });

  test('landingPolishPreviewHint suggests save-time polish', () {
    expect(landingPolishPreviewHint('qualquer faixa etaria'), isNotNull);
    expect(landingPolishPreviewHint('Consultoria online'), isNull);
  });

  test('landingReadinessTitle reflects pending content review', () {
    expect(
      landingReadinessTitle(configDone: 7, configTotal: 7, contentIssueCount: 2),
      'Quase lá · faltam 2 textos',
    );
    expect(
      landingReadinessTitle(configDone: 7, configTotal: 7, contentIssueCount: 0),
      'Pronto para vender',
    );
    expect(
      landingReadinessTitle(configDone: 5, configTotal: 7, contentIssueCount: 0),
      'Em preparação · setup 5/7',
    );
  });

  test('landingPublicationPercent combina setup e textos', () {
    expect(
      landingPublicationPercent(
        configDone: 7,
        configTotal: 7,
        textsReviewed: 6,
        textsTotal: 6,
      ),
      100,
    );
    expect(
      landingPublicationPercent(
        configDone: 7,
        configTotal: 7,
        textsReviewed: 2,
        textsTotal: 6,
      ),
      greaterThan(44),
    );
  });

  test('landingContentReviewBannerSummary explica setup concluido', () {
    expect(
      landingContentReviewBannerSummary(4, configComplete: true),
      'Setup concluído · faltam 4 textos para publicar.',
    );
    expect(
      landingContentReviewBannerSummary(4),
      '4 textos para revisar antes de publicar.',
    );
  });

  test('landingContentReviewScope and reviewed counts align', () {
    final faq = [
      (pergunta: 'dadsdad', resposta: 'ok'),
      (pergunta: 'real?', resposta: 'sim'),
    ];
    expect(landingContentReviewScopeCount(faq: faq), 4);
    expect(
      landingContentReviewedCount(
        faq: faq,
        primaryCta: 'Agendar avaliação',
        heroTitle: 'Transforme seu corpo',
      ),
      3,
    );
  });

  test('landingContentReviewBannerSummary uses unified text count', () {
    expect(
      landingContentReviewBannerSummary(4),
      '4 textos para revisar antes de publicar.',
    );
    expect(
      landingContentReviewBannerSummary(1),
      '1 texto para revisar antes de publicar.',
    );
  });

  test('landingContentReviewCount matches expanded review list', () {
    final count = landingContentReviewCount(
      faq: [
        (pergunta: 'dadsdad', resposta: 'ok'),
        (pergunta: 'teste', resposta: 'abc'),
        (pergunta: 'real?', resposta: 'sim'),
      ],
      primaryCta: 'Quero minha avaliacao',
      heroTitle: 'Transforme seu corpo',
    );
    expect(count, 3);
  });

  test('landingCompleteTemplateFromPreset normaliza ordem e copia CTAs', () {
    final preset = LandingNichePreset(
      id: 'TEST',
      label: 'Teste',
      heroTitle: 'Titulo',
      heroSubtitle: 'Sub',
      bioText: 'Bio premium de exemplo.',
      primaryCta: 'CTA 1',
      offerCta: 'CTA 2',
      finalCta: 'CTA 3',
      contactCta: 'CTA 4',
      servicos: const [LandingServiceItem(titulo: 'S1', descricao: 'D1')],
      faq: const [LandingFaqItem(pergunta: 'P?', resposta: 'R.')],
      sectionOrder: const ['faq', 'bio', 'faq'],
    );

    final template = landingCompleteTemplateFromPreset(preset);

    expect(template.id, 'TEST');
    expect(template.bioText, 'Bio premium de exemplo.');
    expect(template.primaryCta, 'CTA 1');
    expect(template.sectionOrder.take(2), ['faq', 'bio']);
    expect(template.sectionOrder.where((k) => k == 'faq'), hasLength(1));
  });

  test('landingUnifiedTemplateCatalog inclui padrao e remotos', () {
    final remote = LandingNichePreset(
      id: 'ONLINE',
      label: 'Online',
      heroTitle: 'H',
      heroSubtitle: 'S',
      primaryCta: 'C',
    );

    final catalog = landingUnifiedTemplateCatalog([remote]);

    expect(catalog.first.id, landingDefaultTemplateId);
    expect(catalog, hasLength(2));
    expect(catalog.last.id, 'ONLINE');
  });

  test('landingDefaultCompleteTemplate preenche pagina com copy premium', () {
    final template = landingDefaultCompleteTemplate;

    expect(template.bioText, isNotEmpty);
    expect(template.servicos, hasLength(3));
    expect(template.faq, hasLength(4));
    expect(template.heroTitle, isNotEmpty);
    expect(template.contactCta, isNotEmpty);
  });

  test('landingChecklistTarget maps cref to edit profile', () {
    expect(landingChecklistTarget('cref'), LandingChecklistTarget.editProfile);
  });
}
