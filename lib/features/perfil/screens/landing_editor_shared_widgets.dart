import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';

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
    final scheme = Theme.of(context).colorScheme;
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
          Text(
            hint!,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
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

  bool get _hasImage => imageUrl != null && imageUrl!.isNotEmpty;

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
                Text(
                  hint!,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurface.withValues(alpha: 0.72),
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
            if (_hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(TokensStrip.rMd),
                child: Image.network(
                  imageUrl!,
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
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: uploading ? null : onUpload,
                    icon: Icon(uploading ? Icons.hourglass_top : Icons.upload_outlined),
                    label: Text(uploading ? 'Enviando…' : 'Enviar imagem'),
                  ),
                ),
                if (_hasImage && onPreview != null) ...[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Ver na página',
                    onPressed: onPreview,
                    icon: const Icon(Icons.open_in_new_rounded, size: 20),
                  ),
                ],
              ],
            ),
            if ((_hasImage && onRemove != null) ||
                (!_hasImage && onUseDefault != null && optional)) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 0,
                children: [
                  if (_hasImage && onRemove != null)
                    TextButton.icon(
                      onPressed: uploading ? null : onRemove,
                      icon: Icon(Icons.delete_outline, size: 18, color: scheme.error),
                      label: Text(
                        'Remover',
                        style: TextStyle(color: scheme.error, fontWeight: FontWeight.w700),
                      ),
                    ),
                  if (onUseDefault != null && (_hasImage || optional))
                    TextButton.icon(
                      onPressed: uploading ? null : onUseDefault,
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
  final scheme = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText: labelText,
    helperText: helperText,
    helperMaxLines: 2,
    helperStyle: TextStyle(
      color: scheme.onSurface.withValues(alpha: 0.72),
      height: 1.4,
    ),
    counterStyle: TextStyle(
      color: scheme.onSurface.withValues(alpha: 0.72),
      fontWeight: FontWeight.w600,
      fontSize: 12,
    ),
  );
}
