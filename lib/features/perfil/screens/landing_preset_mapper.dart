/// Mapper unificado: presets remotos (API) e modelo local → [LandingCompleteTemplate].
library;

import '../data/landing_growth_repository.dart';
import '../data/perfil_repository.dart';
import 'landing_editor_sections.dart';
import 'landing_section_templates.dart';

const landingDefaultTemplateId = 'PADRAO';

LandingCompleteTemplate landingCompleteTemplateFromPreset(
  LandingNichePreset preset,
) {
  return LandingCompleteTemplate(
    id: preset.id,
    label: preset.label,
    heroTitle: preset.heroTitle,
    heroSubtitle: preset.heroSubtitle,
    bioText: preset.bioText,
    primaryCta: preset.primaryCta,
    offerCta: preset.offerCta,
    finalCta: preset.finalCta,
    contactCta: preset.contactCta,
    servicos: List<LandingServiceItem>.from(preset.servicos),
    faq: List<LandingFaqItem>.from(preset.faq),
    sectionOrder: preset.sectionOrder.isNotEmpty
        ? normalizeLandingSectionOrder(preset.sectionOrder)
        : List<String>.from(landingEditorCanonicalSections),
  );
}

List<LandingCompleteTemplate> landingCompleteTemplatesFromPresets(
  List<LandingNichePreset> presets,
) {
  return presets
      .map(landingCompleteTemplateFromPreset)
      .toList(growable: false);
}

/// Catálogo unificado: modelo padrão Focux + nichos da API.
List<LandingCompleteTemplate> landingUnifiedTemplateCatalog(
  List<LandingNichePreset> remotePresets,
) {
  return [
    landingDefaultCompleteTemplate,
    ...landingCompleteTemplatesFromPresets(remotePresets),
  ];
}

bool landingTemplateIsRemote(LandingCompleteTemplate template) {
  return template.id != landingDefaultTemplateId;
}
