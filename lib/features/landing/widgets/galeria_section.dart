import 'package:flutter/material.dart';
import '../models/public_personal_data.dart';
import 'landing_design_helpers.dart';

class GaleriaSection extends StatelessWidget {
  final PublicPersonalData data;
  const GaleriaSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (!data.isEnterprise || data.fotos.isEmpty) {
      return const SizedBox.shrink();
    }
    final accent = Theme.of(context).colorScheme.primary;
    final photos =
        LandingDesign.prioritize(
          data.fotos,
          data.featuredPhotoIndex,
        ).take(6).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 780;
        final horizontalPadding = wide ? 56.0 : 16.0;
        final contentWidth =
            (constraints.maxWidth - horizontalPadding * 2)
                .clamp(0.0, 1100.0)
                .toDouble();
        final tileWidth = wide ? (contentWidth - 24) / 3 : contentWidth;

        return Container(
          color: const Color(0xFF080C10),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            wide ? 48 : 32,
            horizontalPadding,
            wide ? 56 : 36,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BASTIDORES REAIS',
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Fotos reais para a pagina ter presenca humana.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (var i = 0; i < photos.length; i++)
                        SizedBox(
                          width: tileWidth,
                          child: _GalleryEditorialTile(
                            url: photos[i],
                            index: i,
                            accent: accent,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GalleryEditorialTile extends StatelessWidget {
  final String url;
  final int index;
  final Color accent;

  const _GalleryEditorialTile({
    required this.url,
    required this.index,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: index == 0 ? 1.16 : 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Container(
                    color: const Color(0xFF0F1419),
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: accent,
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
                    const Color(0xFF080C10).withValues(alpha: 0.54),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.44),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Text(
                  'Cena ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
