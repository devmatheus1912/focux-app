import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import 'landing_editor_sections.dart';

/// Alvo mínimo de toque (Material 48dp / Apple 44pt).
const double kLandingEditorMinTouch = 48;

TextStyle landingEditorMutedStyle(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return TokensStrip.bodyMuted(color: scheme.onSurface.withValues(alpha: 0.72));
}

ButtonStyle landingEditorTextButtonStyle() => TextButton.styleFrom(
      minimumSize: const Size(kLandingEditorMinTouch, kLandingEditorMinTouch),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

Widget landingEditorDeleteIconButton({
  required VoidCallback onPressed,
  required String tooltip,
}) {
  return IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    icon: const Icon(Icons.delete_outline),
    style: IconButton.styleFrom(
      minimumSize: const Size(kLandingEditorMinTouch, kLandingEditorMinTouch),
      foregroundColor: EagleTokens.bad,
    ),
  );
}

class LandingEditorSectionHeader extends StatelessWidget {
  const LandingEditorSectionHeader({
    super.key,
    required this.title,
    this.hint,
    this.onAdd,
  });

  final String title;
  final String? hint;
  final VoidCallback? onAdd;

  static const titleStyle = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: TokensStrip.fontH2,
    letterSpacing: TokensStrip.trackingH2,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: titleStyle)),
            if (onAdd != null)
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Adicionar'),
              ),
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(hint!, style: landingEditorMutedStyle(context)),
        ],
      ],
    );
  }
}

class LandingEditorImageUploadCard extends StatelessWidget {
  const LandingEditorImageUploadCard({
    super.key,
    this.title,
    this.hint,
    required this.imageUrl,
    this.defaultPreviewUrl,
    required this.uploading,
    required this.onUpload,
    this.optional = false,
    this.emptyHint,
    this.compact = false,
    this.onPreview,
    this.onRemove,
    this.onUseDefault,
    this.useDefaultLabel,
    this.defaultActiveHint,
  });

  final String? title;
  final String? hint;
  final String? imageUrl;
  final String? defaultPreviewUrl;
  final bool uploading;
  final VoidCallback onUpload;
  final bool optional;
  final String? emptyHint;
  final bool compact;
  final VoidCallback? onPreview;
  final VoidCallback? onRemove;
  final VoidCallback? onUseDefault;
  final String? useDefaultLabel;
  final String? defaultActiveHint;

  bool get _hasManualImage => imageUrl != null && imageUrl!.isNotEmpty;

  bool get _usesDefaultPreview =>
      !_hasManualImage &&
      defaultPreviewUrl != null &&
      defaultPreviewUrl!.isNotEmpty;

  String? get _displayUrl =>
      _hasManualImage ? imageUrl : (_usesDefaultPreview ? defaultPreviewUrl : null);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TokensStrip.rLg),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!compact && title != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(title!, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  if (optional)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: scheme.primaryContainer.withValues(alpha: 0.55),
                      ),
                      child: Text(
                        'Opcional',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
              if (hint != null) ...[
                const SizedBox(height: 4),
                Text(hint!, style: landingEditorMutedStyle(context)),
              ],
              const SizedBox(height: 8),
            ],
            if (_displayUrl != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(TokensStrip.rMd),
                    child: Image.network(
                      _displayUrl!,
                      height: compact ? 100 : 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return SizedBox(
                          height: compact ? 100 : 120,
                          child: Center(
                            child: FxLoading(
                              size: 24,
                              strokeWidth: 2,
                              color: scheme.primary,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => SizedBox(
                        height: compact ? 100 : 120,
                        child: const Center(child: Icon(Icons.broken_image_outlined)),
                      ),
                    ),
                  ),
                  if (_usesDefaultPreview)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: scheme.surface.withValues(alpha: 0.92),
                        ),
                        child: Text(
                          'Padrão',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            else if (optional)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emptyHint ?? 'Sem foto — sua página abre com título e botões.',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurface.withValues(alpha: 0.62),
                        height: 1.45,
                      ),
                    ),
                    if (defaultActiveHint != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        defaultActiveHint!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.primary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              Container(
                height: compact ? 100 : 120,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(TokensStrip.rMd),
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                ),
                child: const Icon(Icons.image_outlined, size: 36),
              ),
            if (_usesDefaultPreview && defaultActiveHint != null) ...[
              const SizedBox(height: 6),
              Text(
                defaultActiveHint!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary.withValues(alpha: 0.9),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: uploading ? null : onUpload,
                    icon: Icon(uploading ? Icons.hourglass_top : Icons.upload_outlined),
                    label: Text(uploading ? 'Enviando…' : 'Enviar imagem'),
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primaryContainer.withValues(alpha: 0.72),
                      foregroundColor: scheme.onPrimaryContainer,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ),
                if (_hasManualImage && onPreview != null) ...[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Ver na página',
                    onPressed: onPreview,
                    icon: const Icon(Icons.open_in_new_rounded, size: 20),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(kLandingEditorMinTouch, kLandingEditorMinTouch),
                    ),
                  ),
                ],
              ],
            ),
            if (_usesDefaultPreview && onPreview != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Ver na página'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.primary,
                    side: BorderSide(color: scheme.primary.withValues(alpha: 0.28)),
                    minimumSize: const Size.fromHeight(42),
                  ),
                ),
              ),
            ],
            if ((_hasManualImage && onRemove != null) ||
                (_hasManualImage && onUseDefault != null) ||
                (!_hasManualImage && onUseDefault != null && optional)) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 0,
                children: [
                  if (_hasManualImage && onRemove != null)
                    TextButton.icon(
                      onPressed: uploading ? null : onRemove,
                      style: landingEditorTextButtonStyle(),
                      icon: Icon(Icons.delete_outline, size: 18, color: scheme.error),
                      label: Text(
                        'Remover',
                        style: TextStyle(color: scheme.error, fontWeight: FontWeight.w700),
                      ),
                    ),
                  if (onUseDefault != null && _hasManualImage)
                    TextButton.icon(
                      onPressed: uploading ? null : onUseDefault,
                      style: landingEditorTextButtonStyle(),
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label: Text(useDefaultLabel ?? 'Usar padrão'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

InputDecoration landingEditorFieldDecoration(
  BuildContext context, {
  required String labelText,
  String? helperText,
  int? maxLength,
}) {
  return InputDecoration(
    labelText: labelText,
    helperText: helperText,
    helperMaxLines: 2,
    helperStyle: landingEditorMutedStyle(context),
    counterStyle: landingEditorMutedStyle(context).copyWith(fontWeight: FontWeight.w600),
  );
}

/// Atalhos horizontais para pular entre blocos da aba Conteúdo.
class LandingContentSectionJumpBar extends StatelessWidget {
  const LandingContentSectionJumpBar({
    super.key,
    required this.onJump,
    this.hiddenSections = const {},
  });

  final ValueChanged<LandingEditorContentSection> onJump;
  final Set<LandingEditorContentSection> hiddenSections;

  static const _order = LandingEditorContentSection.values;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = _order.where((s) => !hiddenSections.contains(s)).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Semantics(
      container: true,
      label: 'Ir para seção do conteúdo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ir para',
            style: TokensStrip.bodyMuted(color: scheme.onSurface.withValues(alpha: 0.8))
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  ActionChip(
                    label: Text(landingEditorContentSectionLabel(visible[i])),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onJump(visible[i]);
                    },
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: TokensStrip.fontBodySm,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LandingStickyCtaInfoBanner extends StatelessWidget {
  const LandingStickyCtaInfoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(TokensStrip.rMd),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'A barra fixa no rodapé da página usa o mesmo texto do botão principal (Abertura).',
              style: landingEditorMutedStyle(context),
            ),
          ),
        ],
      ),
    );
  }
}
