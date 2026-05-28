/// Validação leve de qualidade do conteúdo antes de publicar a landing.
library;

class LandingContentIssue {
  const LandingContentIssue({
    required this.id,
    required this.message,
    this.faqIndex,
    this.faqIndices,
  });

  final String id;
  final String message;
  final int? faqIndex;
  final List<int>? faqIndices;
}

bool landingTextLooksLikePlaceholder(String text) {
  final clean = text.trim().toLowerCase();
  if (clean.isEmpty) return false;
  if (clean.length < 3) return true;

  if (RegExp(r'^(dad|ada|test|asdf|xxx|qwerty|lorem)').hasMatch(clean)) {
    return true;
  }

  final letters = clean.replaceAll(RegExp(r'[^a-záàâãéêíóôõúç]'), '');
  if (letters.length >= 6) {
    final unique = letters.split('').toSet().length;
    if (unique <= 3) return true;
  }

  return false;
}

String? landingCtaAccentSuggestion(String text) {
  if (text.toLowerCase().contains('avaliacao') && !text.contains('avaliação')) {
    return text.replaceAll(
      RegExp('avaliacao', caseSensitive: false),
      'avaliação',
    );
  }
  return null;
}

List<int> landingBadFaqIndices({
  required List<({String pergunta, String resposta})> faq,
}) {
  final badFaq = <int>[];
  for (var i = 0; i < faq.length; i++) {
    final p = faq[i].pergunta.trim();
    final r = faq[i].resposta.trim();
    if (p.isEmpty && r.isEmpty) continue;
    if (landingTextLooksLikePlaceholder(p) || landingTextLooksLikePlaceholder(r)) {
      badFaq.add(i);
    }
  }
  return badFaq;
}

List<LandingContentIssue> landingContentIssues({
  required List<({String pergunta, String resposta})> faq,
  required String primaryCta,
  required String heroTitle,
}) {
  final issues = <LandingContentIssue>[];

  if (landingTextLooksLikePlaceholder(heroTitle)) {
    issues.add(
      const LandingContentIssue(
        id: 'hero',
        message: 'Título principal parece incompleto ou genérico.',
      ),
    );
  }

  if (landingTextLooksLikePlaceholder(primaryCta)) {
    issues.add(
      const LandingContentIssue(
        id: 'cta',
        message: 'Texto do botão principal parece incompleto.',
      ),
    );
  }

  if (landingCtaAccentSuggestion(primaryCta) != null) {
    issues.add(
      const LandingContentIssue(
        id: 'cta_accent',
        message: 'Botão principal: use "avaliação" com acento.',
      ),
    );
  }

  final badFaq = landingBadFaqIndices(faq: faq);

  if (badFaq.length == 1) {
    issues.add(
      LandingContentIssue(
        id: 'faq',
        faqIndex: badFaq.first,
        faqIndices: badFaq,
        message: 'Pergunta ${badFaq.first + 1} parece texto de teste.',
      ),
    );
  } else if (badFaq.length > 1) {
    issues.add(
      LandingContentIssue(
        id: 'faq',
        faqIndices: badFaq,
        message: '${badFaq.length} perguntas frequentes parecem texto de teste.',
      ),
    );
  }

  return issues;
}

/// Lista expandida para o sheet de revisão (1 item por FAQ problemática).
List<LandingContentIssue> landingContentIssuesForReview({
  required List<({String pergunta, String resposta})> faq,
  required String primaryCta,
  required String heroTitle,
}) {
  final issues = landingContentIssues(
    faq: faq,
    primaryCta: primaryCta,
    heroTitle: heroTitle,
  );
  final expanded = <LandingContentIssue>[];

  for (final issue in issues) {
    if (issue.id == 'faq' &&
        issue.faqIndex == null &&
        (issue.faqIndices?.length ?? 0) > 1) {
      for (final index in issue.faqIndices!) {
        expanded.add(
          LandingContentIssue(
            id: 'faq',
            faqIndex: index,
            faqIndices: issue.faqIndices,
            message: 'Pergunta ${index + 1} parece texto de teste.',
          ),
        );
      }
      continue;
    }
    expanded.add(issue);
  }

  return expanded;
}

List<String> landingContentWarnings({
  required List<({String pergunta, String resposta})> faq,
  required String primaryCta,
  required String heroTitle,
}) {
  return landingContentIssues(
    faq: faq,
    primaryCta: primaryCta,
    heroTitle: heroTitle,
  ).map((e) => e.message).toList();
}

String landingContentReviewBannerSummary(int reviewCount) {
  if (reviewCount <= 0) return '';
  if (reviewCount == 1) return '1 texto para revisar antes de publicar.';
  return '$reviewCount textos para revisar antes de publicar.';
}

int landingContentReviewCount({
  required List<({String pergunta, String resposta})> faq,
  required String primaryCta,
  required String heroTitle,
}) {
  return landingContentIssuesForReview(
    faq: faq,
    primaryCta: primaryCta,
    heroTitle: heroTitle,
  ).length;
}

String landingReadinessTitle({
  required int configDone,
  required int configTotal,
  required int contentIssueCount,
}) {
  if (contentIssueCount == 0 && configDone == configTotal) {
    return 'Pronto para vender ($configDone/$configTotal)';
  }
  if (contentIssueCount > 0) {
    return 'Quase pronto · $configDone/$configTotal configurados';
  }
  return 'Pronto para vender ($configDone/$configTotal)';
}

String landingReadinessSubtitle({
  required int contentIssueCount,
}) {
  if (contentIssueCount == 0) {
    return 'Configuração e textos revisados. Toque em um item para editar.';
  }
  if (contentIssueCount == 1) {
    return 'Falta 1 texto para revisar antes de publicar.';
  }
  return 'Faltam $contentIssueCount textos para revisar antes de publicar.';
}

bool landingFaqItemHasIssue({
  required List<({String pergunta, String resposta})> faq,
  required int index,
}) {
  return landingBadFaqIndices(faq: faq).contains(index);
}
