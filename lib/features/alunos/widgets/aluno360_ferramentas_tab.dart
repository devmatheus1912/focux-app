import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../constants/aluno_360_layout.dart';
import 'aluno360_operacao_tab.dart';

/// Ferramentas tab layout: measurements grid + modules grid.
class Aluno360FerramentasTab extends StatelessWidget {
  const Aluno360FerramentasTab({
    super.key,
    required this.primary,
    required this.isDark,
    required this.measurementsSection,
    required this.modulesSection,
    this.animateEntrance = false,
    this.onEntrancePlayed,
  });

  final Color primary;
  final bool isDark;
  final Widget measurementsSection;
  final Widget modulesSection;
  final bool animateEntrance;
  final VoidCallback? onEntrancePlayed;

  Widget _section(int step, Widget child) {
    return Aluno360OperacaoEntrance(
      enabled: animateEntrance,
      delay: Duration(milliseconds: step * 40),
      onPlayed: onEntrancePlayed,
      child: child,
    );
  }

  Widget _sectionHeader(String title) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: AppTypography.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: BrandPalette.sectionHeading(primary, dark: isDark),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final measurements = _section(
      0,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Medidas'),
          const SizedBox(height: Aluno360Layout.sectionGap),
          measurementsSection,
        ],
      ),
    );
    final modules = _section(
      1,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Módulos'),
          const SizedBox(height: Aluno360Layout.sectionGap),
          modulesSection,
        ],
      ),
    );

    return Semantics(
      container: true,
      label: 'Ferramentas do aluno: medidas corporais e módulos de ação',
      child: Aluno360Layout.operacaoContentWidthLimiter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            measurements,
            const SizedBox(height: 20),
            modules,
          ],
        ),
      ),
    );
  }
}
