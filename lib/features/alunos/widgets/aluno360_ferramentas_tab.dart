import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';

/// Ferramentas tab layout: measurements grid + modules grid.
class Aluno360FerramentasTab extends StatelessWidget {
  const Aluno360FerramentasTab({
    super.key,
    required this.primary,
    required this.isDark,
    required this.measurementsSection,
    required this.modulesSection,
  });

  final Color primary;
  final bool isDark;
  final Widget measurementsSection;
  final Widget modulesSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        measurementsSection,
        const SizedBox(height: 20),
        Text(
          'Módulos',
          style: AppTypography.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: BrandPalette.sectionHeading(primary, dark: isDark),
          ),
        ),
        const SizedBox(height: 12),
        modulesSection,
      ],
    );
  }
}
