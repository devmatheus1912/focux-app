import 'package:flutter/material.dart';

import 'perfil_card_section.dart';

/// Seção Marca e vitrine do hub Perfil.
class PerfilMarcaVitrineSection extends StatelessWidget {
  const PerfilMarcaVitrineSection({
    super.key,
    required this.profileComplete,
    required this.isDark,
    required this.accent,
    required this.actionInk,
    required this.onEditBrand,
    this.brandPreview,
    this.brandPalette,
    required this.publicLink,
  });

  final bool profileComplete;
  final bool isDark;
  final Color accent;
  final Color actionInk;
  final VoidCallback onEditBrand;
  final Widget? brandPreview;
  final Widget? brandPalette;
  final Widget publicLink;

  @override
  Widget build(BuildContext context) {
    return PerfilCardSection(
      title: 'Marca e vitrine',
      subtitle:
          profileComplete
              ? 'Link e compartilhamento da vitrine.'
              : 'Link para divulgar e preview do aluno.',
      trailingLabel: 'Editar',
      onTrailingTap: onEditBrand,
      isDark: isDark,
      accent: accent,
      actionInk: actionInk,
      child: Semantics(
        container: true,
        label: 'Marca e vitrine online',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!profileComplete && brandPreview != null) ...[
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
