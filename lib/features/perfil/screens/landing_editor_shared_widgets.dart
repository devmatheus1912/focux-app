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
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
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
    required this.title,
    required this.hint,
    required this.imageUrl,
    required this.uploading,
    required this.onUpload,
  });

  final String title;
  final String hint;
  final String? imageUrl;
  final bool uploading;
  final VoidCallback onUpload;

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
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              hint,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 8),
            if (imageUrl != null && imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(TokensStrip.rMd),
                child: Image.network(
                  imageUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return SizedBox(
                      height: 120,
                      child: Center(
                        child: FxLoading(
                          size: 24,
                          strokeWidth: 2,
                          color: scheme.primary,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 120,
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(TokensStrip.rMd),
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                ),
                child: const Icon(Icons.image_outlined, size: 36),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: uploading ? null : onUpload,
              icon: Icon(uploading ? Icons.hourglass_top : Icons.upload_outlined),
              label: Text(uploading ? 'Enviando…' : 'Enviar imagem'),
            ),
          ],
        ),
      ),
    );
  }
}
