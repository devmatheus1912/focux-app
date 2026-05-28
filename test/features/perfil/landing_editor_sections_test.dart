import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/perfil/screens/landing_editor_checklist.dart';
import 'package:focux_app/features/perfil/screens/landing_editor_quality.dart';
import 'package:focux_app/features/perfil/screens/landing_editor_sections.dart';

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

  test('landingReadinessTitle reflects pending content review', () {
    expect(
      landingReadinessTitle(configDone: 7, configTotal: 7, contentIssueCount: 2),
      'Quase pronto · 7/7 configurados',
    );
    expect(
      landingReadinessTitle(configDone: 7, configTotal: 7, contentIssueCount: 0),
      'Pronto para vender (7/7)',
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
}
