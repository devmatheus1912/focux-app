import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';

class DashboardHeaderProfileAvatar extends StatelessWidget {
  const DashboardHeaderProfileAvatar({
    super.key,
    required this.primary,
    required this.isDark,
    required this.initials,
    required this.onTap,
    this.photoUrl,
    this.size = 40,
  });

  final Color primary;
  final bool isDark;
  final String initials;
  final VoidCallback onTap;
  final String? photoUrl;
  final double size;

  static const double _ring = 2;
  static const double _gap = 2;

  @override
  Widget build(BuildContext context) {
    // Marca do personal (pilar 8) — softened lê teal no dark;
    // accent clareava demais e parecia anel neutro.
    final brand = BrandPalette.softened(primary);
    final ring = brand.withValues(alpha: isDark ? 0.92 : 0.78);
    final glow = brand.withValues(alpha: isDark ? 0.22 : 0.14);
    final outer = size;
    final avatarRadius = (outer - _ring * 2 - _gap * 2) / 2;
    return Semantics(
      button: true,
      label: 'Abrir perfil',
      child: SizedBox(
        width: outer,
        height: outer,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: glow,
                      blurRadius: isDark ? 8 : 6,
                    ),
                  ],
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              clipBehavior: Clip.none,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                splashColor: brand.withValues(alpha: 0.12),
                highlightColor: brand.withValues(alpha: 0.06),
                child: Container(
                  width: outer,
                  height: outer,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ring, width: _ring),
                  ),
                  padding: const EdgeInsets.all(_gap),
                  child: ClipOval(
                    child:
                        photoUrl != null && photoUrl!.isNotEmpty
                            ? Image.network(
                              photoUrl!,
                              width: avatarRadius * 2,
                              height: avatarRadius * 2,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => ColoredBox(
                                    color: primary,
                                    child: Center(
                                      child: Text(
                                        initials,
                                        style: FocuxHubTypography.chip(
                                          Colors.white,
                                        ).copyWith(
                                          fontSize: avatarRadius * 0.72,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                            )
                            : ColoredBox(
                              color: primary,
                              child: Center(
                                child: Text(
                                  initials,
                                  style: FocuxHubTypography.chip(
                                    Colors.white,
                                  ).copyWith(
                                    fontSize: avatarRadius * 0.72,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
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
