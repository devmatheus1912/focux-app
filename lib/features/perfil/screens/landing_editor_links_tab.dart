import 'package:flutter/material.dart';

import '../../../core/config/env.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/landing_growth_repository.dart';
import '../utils/landing_default_images.dart';
import '../widgets/landing_editor_widgets.dart';
import 'landing_editor_controller.dart';
import 'landing_section_templates.dart';

class LandingEditorLinksTab extends StatelessWidget {
  const LandingEditorLinksTab({
    super.key,
    required this.controller,
    required this.onReviewFocus,
    required this.onChecklistTap,
    required this.onApplyTemplate,
  });

  final LandingEditorController controller;
  final VoidCallback onReviewFocus;
  final ValueChanged<LandingChecklistItem> onChecklistTap;
  final ValueChanged<LandingCompleteTemplate> onApplyTemplate;

  @override
  Widget build(BuildContext context) {
    final slug = controller.slug;
    if (slug == null || slug.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(TokensStrip.s4),
        children: [
          FxSatellitePanel(
            padding: const EdgeInsets.all(TokensStrip.s4),
            child: Text(
              'Defina seu slug no perfil para gerar os links da sua página.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ),
        ],
      );
    }

    final landingUrl = Env.landingPageUrl(slug);
    final capturaUrl = Env.capturaPageUrl(slug);
    final templates = controller.templateCatalog;
    final nicheCount = templates.length > 1 ? templates.length - 1 : 0;
    final applying = controller.applyingTemplate || controller.saving;

    final previewImage = landingResolvedHeroImageUrl(slug, controller.heroImageUrl);

    return ListView(
      padding: const EdgeInsets.all(TokensStrip.s4),
      children: [
        LandingLivePreviewCard(
          previewImageUrl: previewImage,
          displayLabel: Env.landingPageDisplayLabel(slug),
          unsavedChanges: controller.dirty,
          onOpen: () => openLandingLink(context, url: landingUrl),
        ),
        const SizedBox(height: 12),
        LandingLinkCard(
          icon: Icons.public_rounded,
          title: 'Página completa na internet',
          subtitle:
              'Site com planos e depoimentos — ideal para Instagram, WhatsApp e bio.',
          displayLabel: Env.landingPageDisplayLabel(slug),
          copyUrl: landingUrl,
          onOpen: () => openLandingLink(context, url: landingUrl),
          onCopy: () => copyLandingLink(
            context,
            url: landingUrl,
            successMessage: 'Link da página copiado.',
          ),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: controller.capturaCardKey,
          child: LandingLinkCard(
            icon: Icons.bolt_rounded,
            title: 'Formulário rápido de contato',
            subtitle:
                'Só nome e WhatsApp — use em anúncios quando quiser captar lead direto.',
            displayLabel: Env.capturaPageDisplayLabel(slug),
            copyUrl: capturaUrl,
            onOpen: () => openLandingLink(context, url: capturaUrl),
            onCopy: () => copyLandingLink(
              context,
              url: capturaUrl,
              successMessage: 'Link do formulário copiado.',
            ),
          ),
        ),
        if (controller.checklistLoading) ...[
          const SizedBox(height: 16),
          const LandingChecklistSkeleton(),
        ] else if (controller.checklist.isNotEmpty) ...[
          const SizedBox(height: 16),
          LandingChecklistCard(
            items: controller.checklist,
            contentIssueCount: controller.contentReviewCount(),
            contentReviewScope: controller.contentReviewScope(),
            contentReviewedCount: controller.contentReviewedCount(),
            onReviewContent: onReviewFocus,
            onItemTap: onChecklistTap,
          ),
        ],
        const SizedBox(height: 16),
        LandingTemplatesCompactCard(
          templates: templates,
          nicheCount: nicheCount,
          applying: applying,
          onApplyTemplate: onApplyTemplate,
          onBrowseTemplates: () => showLandingTemplatesSheet(
            context,
            sectionOrder: controller.sectionOrder,
            templates: templates,
            applying: applying,
            onApplyTemplate: onApplyTemplate,
          ),
        ),
      ],
    );
  }
}
