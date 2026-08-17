import 'package:flutter/material.dart';

import '../../dashboard/utils/dashboard_readability.dart';
import 'perfil_card_section.dart';

/// Seção Marca e vitrine do hub Perfil.
class PerfilMarcaVitrineSection extends StatelessWidget {
  const PerfilMarcaVitrineSection({
    super.key,
    required this.profileComplete,
    required this.isDark,
    required this.accent,
    required this.actionInk,
    this.brandPreview,
    this.brandPalette,
    required this.publicLink,
  });

  final bool profileComplete;
  final bool isDark;
  final Color accent;
  final Color actionInk;
  final Widget? brandPreview;
  final Widget? brandPalette;
  final Widget publicLink;

  @override
  Widget build(BuildContext context) {
    if (profileComplete) {
      final heading = dashboardReadableCaption(context, isDark: isDark);
      return Semantics(
        container: true,
        label: 'Marca e vitrine online',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Marca e vitrine',
              style: FocuxHubTypography.eyebrow(
                context,
                color: heading,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
              ),
            ),
            const SizedBox(height: 10),
            publicLink,
          ],
        ),
      );
    }

    return PerfilCardSection(
      title: 'Marca e vitrine',
      subtitle: 'Link para divulgar e preview do aluno.',
      isDark: isDark,
      accent: accent,
      actionInk: actionInk,
      child: Semantics(
        container: true,
        label: 'Marca e vitrine online',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (brandPreview != null) ...[
              brandPreview!,
              if (brandPalette != null) ...[
                const SizedBox(height: 8),
                brandPalette!,
              ],
              const SizedBox(height: 8),
            ],
            publicLink,
          ],
        ),
      ),
    );
  }
}
