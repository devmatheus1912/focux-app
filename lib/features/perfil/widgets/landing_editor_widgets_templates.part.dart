part of 'landing_editor_widgets.dart';

class _LandingTemplatesSheet extends StatelessWidget {
  const _LandingTemplatesSheet({
    required this.sectionOrder,
    required this.templates,
    required this.applying,
    required this.onApplyTemplate,
    required this.onClose,
  });

  final List<String> sectionOrder;
  final List<LandingCompleteTemplate> templates;
  final bool applying;
  final ValueChanged<LandingCompleteTemplate> onApplyTemplate;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.88;
    final defaultTemplate = templates.isNotEmpty ? templates.first : null;

    return Material(
      color: scheme.surface,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: sheetHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Semantics(
                  label: 'Arraste para fechar catálogo de modelos',
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        label:
                            'Catálogo de modelos da landing. '
                            'Oito seções editáveis e modelos por nicho.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Catálogo de modelos',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '8 seções · padrão Focux'
                              '${templates.length > 1 ? ' + ${templates.length - 1} nichos' : ''}',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: scheme.onSurface.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar catálogo',
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    Text(
                      'Sua página tem 8 seções editáveis. Use um modelo para preencher textos de abertura, serviços, FAQ e botões.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: scheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 14),
                    LandingTemplateCatalogSections(sectionOrder: sectionOrder),
                    if (templates.length > 1) ...[
                      const SizedBox(height: 8),
                      LandingTemplateNichePicker(
                        templates: templates,
                        applying: applying,
                        onApplyTemplate: onApplyTemplate,
                      ),
                    ],
                  ],
                ),
              ),
              Material(
                elevation: 10,
                color: scheme.surface,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Semantics(
                    button: true,
                    label:
                        defaultTemplate == null
                            ? 'Aplicar modelo padrão Focux'
                            : 'Aplicar ${defaultTemplate.label}',
                    enabled: !applying && defaultTemplate != null,
                    child: OutlinedButton.icon(
                      onPressed:
                          applying || defaultTemplate == null
                              ? null
                              : () => onApplyTemplate(defaultTemplate),
                      icon:
                          applying
                              ? const FxLoading(size: 16, strokeWidth: 2)
                              : const Icon(
                                Icons.auto_fix_high_outlined,
                                size: 18,
                              ),
                      label: Text(
                        defaultTemplate == null
                            ? 'Aplicar modelo padrão Focux'
                            : 'Aplicar ${defaultTemplate.label}',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LandingTemplateCatalogSections extends StatelessWidget {
  const LandingTemplateCatalogSections({super.key, required this.sectionOrder});

  final List<String> sectionOrder;

  IconData _iconFor(String name) {
    return switch (name) {
      'person' => Icons.person_outline_rounded,
      'fitness' => Icons.fitness_center_outlined,
      'route' => Icons.route_outlined,
      'payments' => Icons.payments_outlined,
      'reviews' => Icons.reviews_outlined,
      'photo_library' => Icons.photo_library_outlined,
      'help' => Icons.help_outline_rounded,
      'chat' => Icons.chat_bubble_outline_rounded,
      _ => Icons.view_agenda_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeKeys = sectionOrder.map(normalizeLandingSectionKey).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in landingSectionTemplateCatalog) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _iconFor(section.iconName),
                size: 18,
                color:
                    activeKeys.contains(section.key)
                        ? EagleTokens.good
                        : scheme.outline,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      section.description,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: scheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ex.: ${section.example}',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        fontStyle: FontStyle.italic,
                        color: scheme.onSurface.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class LandingTemplateNichePicker extends StatelessWidget {
  const LandingTemplateNichePicker({
    super.key,
    required this.templates,
    required this.applying,
    required this.onApplyTemplate,
  });

  final List<LandingCompleteTemplate> templates;
  final bool applying;
  final ValueChanged<LandingCompleteTemplate> onApplyTemplate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Modelos por nicho',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: scheme.onSurface.withValues(alpha: 0.88),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Preenche abertura, serviços, dúvidas, botões e ordem das seções.',
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
            color: scheme.onSurface.withValues(alpha: 0.68),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final template in templates.skip(1))
              Semantics(
                button: true,
                label: 'Aplicar modelo ${template.label}',
                enabled: !applying,
                child: ActionChip(
                  label: Text(template.label),
                  onPressed: applying ? null : () => onApplyTemplate(template),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Preview visual da capa + atalho para abrir a página como o cliente vê.
class LandingLivePreviewCard extends StatelessWidget {
  const LandingLivePreviewCard({
    super.key,
    required this.previewImageUrl,
    required this.displayLabel,
    required this.onOpen,
    this.unsavedChanges = false,
  });

  final String previewImageUrl;
  final String displayLabel;
  final VoidCallback onOpen;
  final bool unsavedChanges;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label: 'Preview da landing. $displayLabel',
      child: Container(
        decoration: fxListCardDecoration(context, radius: TokensStrip.rLg),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    previewImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                scheme.primary.withValues(alpha: 0.35),
                                scheme.surfaceContainerHighest,
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: scheme.onSurface.withValues(alpha: 0.35),
                          ),
                        ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 10,
                    child: Text(
                      displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: TokensStrip.fontBodySm,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
                      ),
                    ),
                  ),
                  if (unsavedChanges)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Não salvo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: TokensStrip.fontBodySm,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Preview da sua página',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: TokensStrip.fontBody,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onOpen();
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Ver ao vivo'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> copyLandingLink(
  BuildContext context, {
  required String url,
  required String successMessage,
  double reserveBottom = 0,
}) async {
  await Clipboard.setData(ClipboardData(text: url));
  if (!context.mounted) return;
  FeedbackHelper.showSuccess(
    context,
    successMessage,
    reserveBottom: reserveBottom,
  );
}

Future<void> openLandingLink(
  BuildContext context, {
  required String url,
}) async {
  try {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!context.mounted) return;
    if (opened) {
      FeedbackHelper.showInfo(context, 'Abrindo como seu cliente vê…');
    } else {
      FeedbackHelper.showWarn(context, 'Não foi possível abrir o link.');
    }
  } catch (_) {
    if (!context.mounted) return;
    FeedbackHelper.showError(context, 'Não foi possível abrir a página.');
  }
}
