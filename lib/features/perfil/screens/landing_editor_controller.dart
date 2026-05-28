import 'dart:async';

import 'package:flutter/material.dart';

import '../data/landing_growth_repository.dart';
import '../data/perfil_repository.dart';
import 'landing_editor_quality.dart';
import 'landing_editor_sections.dart';
import 'landing_preset_mapper.dart';
import 'landing_section_templates.dart';

enum LandingEditorLeaveChoice { stay, discard, saveAndLeave }

/// Estado mutável e regras de negócio do editor (sem UI).
class LandingEditorController {
  LandingEditorController({required this.onStateChanged});

  final VoidCallback onStateChanged;

  final conteudoScroll = ScrollController();
  final heroSectionKey = GlobalKey();
  final ctasSectionKey = GlobalKey();
  final servicosSectionKey = GlobalKey();
  final faqSectionKey = GlobalKey();
  final capturaCardKey = GlobalKey();

  final heroTitle = TextEditingController();
  final heroSubtitle = TextEditingController();
  final primaryCta = TextEditingController();
  final offerCta = TextEditingController();
  final finalCta = TextEditingController();
  final contactCta = TextEditingController();

  List<String> sectionOrder = List<String>.from(landingEditorCanonicalSections);
  List<LandingServiceItem> servicos = [];
  List<LandingFaqItem> faq = [];
  String? slug;
  String? heroImageUrl;
  String? bioImageUrl;
  bool loaded = false;
  bool dirty = false;
  bool saving = false;
  bool uploadingHero = false;
  bool uploadingBio = false;
  bool generatingHero = false;
  int tabIndex = 0;
  bool heroExpanded = true;
  bool ctasExpanded = false;
  bool servicosExpanded = false;
  bool faqExpanded = false;
  bool checklistLoading = true;
  String? highlightedSectionKey;
  int? highlightedFaqIndex;
  Timer? highlightTimer;
  Timer? faqHighlightTimer;
  final faqItemKeys = <int, GlobalKey>{};
  List<LandingNichePreset> presets = [];

  List<LandingCompleteTemplate> get templateCatalog =>
      landingUnifiedTemplateCatalog(presets);
  List<LandingChecklistItem> checklist = [];
  int lastReviewCount = -1;
  bool celebrationShownForClear = false;
  bool reviewFocusMode = false;
  bool applyingTemplate = false;

  Iterable<TextEditingController> get _textControllers => [
        heroTitle,
        heroSubtitle,
        primaryCta,
        offerCta,
        finalCta,
        contactCta,
      ];

  void attachTextListeners() {
    for (final c in _textControllers) {
      c.addListener(_markDirtyFromText);
    }
  }

  void dispose() {
    for (final c in _textControllers) {
      c.removeListener(_markDirtyFromText);
      c.dispose();
    }
    highlightTimer?.cancel();
    faqHighlightTimer?.cancel();
    conteudoScroll.dispose();
  }

  void _markDirtyFromText() {
    if (!loaded) return;
    dirty = true;
    onStateChanged();
  }

  void markDirty() {
    if (!loaded) return;
    dirty = true;
    onStateChanged();
  }

  void notifyChanged() => onStateChanged();

  List<({String pergunta, String resposta})> faqPayload() {
    return faq.map((e) => (pergunta: e.pergunta, resposta: e.resposta)).toList();
  }

  List<LandingContentIssue> contentIssuesForReview() {
    return landingContentIssuesForReview(
      faq: faqPayload(),
      primaryCta: primaryCta.text,
      heroTitle: heroTitle.text,
    );
  }

  int contentReviewCount() {
    return landingContentReviewCount(
      faq: faqPayload(),
      primaryCta: primaryCta.text,
      heroTitle: heroTitle.text,
    );
  }

  int contentReviewScope() => landingContentReviewScopeCount(faq: faqPayload());

  int contentReviewedCount() {
    return landingContentReviewedCount(
      faq: faqPayload(),
      primaryCta: primaryCta.text,
      heroTitle: heroTitle.text,
    );
  }

  Set<int> focusFaqIndices() {
    return landingBadFaqIndices(faq: faqPayload()).toSet();
  }

  bool focusHeroIssue() {
    return contentIssuesForReview().any((issue) => issue.id != 'faq');
  }

  GlobalKey faqKeyFor(int index) =>
      faqItemKeys.putIfAbsent(index, GlobalKey.new);

  void applyPerfil(PerfilPersonal p) {
    heroTitle.text = p.heroTitle ?? '';
    heroSubtitle.text = p.heroSubtitle ?? '';
    primaryCta.text = p.primaryCta ?? '';
    offerCta.text = p.offerCta ?? '';
    finalCta.text = p.finalCta ?? '';
    contactCta.text = p.contactCta ?? '';
    slug = p.slug;
    heroImageUrl = p.heroImageUrl;
    bioImageUrl = p.bioImageUrl;
    servicos = p.servicos
        .map((e) => LandingServiceItem(titulo: e.titulo, descricao: e.descricao))
        .toList();
    faq = p.faq
        .map((e) => LandingFaqItem(pergunta: e.pergunta, resposta: e.resposta))
        .toList();
    sectionOrder = p.sectionOrder.isNotEmpty
        ? normalizeLandingSectionOrder(p.sectionOrder)
        : List<String>.from(landingEditorCanonicalSections);
    loaded = true;
    dirty = false;
    lastReviewCount = contentReviewCount();
  }

  void applyTemplate(LandingCompleteTemplate template) {
    heroTitle.text = template.heroTitle;
    heroSubtitle.text = template.heroSubtitle;
    primaryCta.text = template.primaryCta;
    offerCta.text = template.offerCta;
    finalCta.text = template.finalCta;
    contactCta.text = template.contactCta;
    servicos = List<LandingServiceItem>.from(template.servicos);
    faq = List<LandingFaqItem>.from(template.faq);
    sectionOrder = List<String>.from(template.sectionOrder);
    heroExpanded = true;
    faqExpanded = true;
    servicosExpanded = true;
    ctasExpanded = false;
    reviewFocusMode = false;
    dirty = true;
    onStateChanged();
  }

  void applyPolishToControllers({
    required List<LandingServiceItem> polishedServicos,
    required List<LandingFaqItem> polishedFaq,
    required String polishedHeroTitle,
    required String polishedPrimaryCta,
    required String polishedOfferCta,
    required String polishedFinalCta,
    required String polishedContactCta,
  }) {
    heroTitle.text = polishedHeroTitle;
    primaryCta.text = polishedPrimaryCta;
    offerCta.text = polishedOfferCta;
    finalCta.text = polishedFinalCta;
    contactCta.text = polishedContactCta;
    servicos = polishedServicos;
    faq = polishedFaq;
  }

  String polishCta(String text) {
    final polished = landingPolishShortText(text);
    return landingCtaAccentSuggestion(polished) ?? polished;
  }

  List<LandingFaqItem> faqForSave() {
    return faq
        .where((item) =>
            item.pergunta.trim().length >= 3 && item.resposta.trim().length >= 3)
        .map(
          (item) => LandingFaqItem(
            pergunta: landingPolishShortText(item.pergunta),
            resposta: landingPolishShortText(item.resposta),
          ),
        )
        .toList();
  }

  List<LandingServiceItem> servicosForSave() {
    return servicos
        .where((s) =>
            s.titulo.trim().isNotEmpty || s.descricao.trim().isNotEmpty)
        .map(
          (s) => LandingServiceItem(
            titulo: landingPolishShortText(s.titulo),
            descricao: s.descricao.trim(),
          ),
        )
        .toList();
  }

  String? validateBeforeSave() {
    for (var i = 0; i < faq.length; i++) {
      final p = faq[i].pergunta.trim();
      final r = faq[i].resposta.trim();
      final hasAny = p.isNotEmpty || r.isNotEmpty;
      if (!hasAny) continue;
      if (p.length < 3) {
        return 'FAQ ${i + 1}: escreva uma pergunta com pelo menos 3 caracteres.';
      }
      if (r.length < 3) {
        return 'FAQ ${i + 1}: escreva uma resposta com pelo menos 3 caracteres.';
      }
    }
    if (heroTitle.text.trim().isEmpty) {
      return 'Informe o título principal da sua página.';
    }
    if (primaryCta.text.trim().isEmpty) {
      return 'Informe o texto do botão principal.';
    }
    return null;
  }

  void reorderSection(int oldIndex, int newIndex, {required VoidCallback onHighlightEnd}) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = sectionOrder.removeAt(oldIndex);
    sectionOrder.insert(newIndex, item);
    dirty = true;
    highlightedSectionKey = item;
    onStateChanged();
    highlightTimer?.cancel();
    highlightTimer = Timer(const Duration(milliseconds: 750), onHighlightEnd);
  }

  void moveSection(int index, int delta, {required VoidCallback onHighlightEnd}) {
    if (delta < 0) {
      if (index <= 0) return;
      reorderSection(index, index - 1, onHighlightEnd: onHighlightEnd);
      return;
    }
    if (index >= sectionOrder.length - 1) return;
    reorderSection(index, index + 2, onHighlightEnd: onHighlightEnd);
  }

  void addServico() {
    servicos = [...servicos, const LandingServiceItem(titulo: '', descricao: '')];
    dirty = true;
    onStateChanged();
  }

  void removeServico(int index) {
    servicos = [...servicos]..removeAt(index);
    dirty = true;
    onStateChanged();
  }

  void updateServico(int index, {String? titulo, String? descricao}) {
    final current = servicos[index];
    servicos[index] = LandingServiceItem(
      titulo: titulo ?? current.titulo,
      descricao: descricao ?? current.descricao,
    );
    dirty = true;
    onStateChanged();
  }

  void addFaq() {
    faq = [...faq, const LandingFaqItem(pergunta: '', resposta: '')];
    dirty = true;
    onStateChanged();
  }

  void removeFaq(int index) {
    faq = [...faq]..removeAt(index);
    dirty = true;
    onStateChanged();
  }

  void updateFaq(int index, {String? pergunta, String? resposta}) {
    final current = faq[index];
    faq[index] = LandingFaqItem(
      pergunta: pergunta ?? current.pergunta,
      resposta: resposta ?? current.resposta,
    );
    dirty = true;
    onStateChanged();
  }

  void pulseFaqHighlight(int? index, {required VoidCallback onHighlightEnd}) {
    highlightedFaqIndex = index;
    onStateChanged();
    faqHighlightTimer?.cancel();
    faqHighlightTimer = Timer(const Duration(milliseconds: 900), onHighlightEnd);
  }

  void clearSectionHighlight() {
    highlightedSectionKey = null;
    onStateChanged();
  }

  void clearFaqHighlight() {
    highlightedFaqIndex = null;
    onStateChanged();
  }
}
