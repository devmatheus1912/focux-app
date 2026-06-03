import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
class DashboardHeaderProfileAvatar extends StatelessWidget {
  const DashboardHeaderProfileAvatar({
    required this.primary,
    required this.isDark,
    required this.initials,
    required this.onTap,
    this.photoUrl,
  });

  final Color primary;
  final bool isDark;
  final String initials;
  final VoidCallback onTap;
  final String? photoUrl;

  static const double _outer = 40;
  static const double _ring = 2;
  static const double _gap = 2;

  @override
  Widget build(BuildContext context) {
    final neon = BrandPalette.accent(primary);
    final avatarRadius = (_outer - _ring * 2 - _gap * 2) / 2;
    const glowPad = 5.0;

    return Semantics(
      button: true,
      label: 'Abrir perfil',
      child: SizedBox(
        width: _outer + glowPad * 2,
        height: _outer + glowPad * 2,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: _outer,
              height: _outer,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: neon.withValues(alpha: isDark ? 0.34 : 0.24),
                    blurRadius: isDark ? 12 : 10,
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              clipBehavior: Clip.none,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                splashColor: neon.withValues(alpha: 0.12),
                highlightColor: neon.withValues(alpha: 0.06),
                child: Container(
                  width: _outer,
                  height: _outer,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: neon.withValues(alpha: isDark ? 0.98 : 0.88),
                      width: _ring,
                    ),
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
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: avatarRadius * 0.72,
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
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: avatarRadius * 0.72,
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
