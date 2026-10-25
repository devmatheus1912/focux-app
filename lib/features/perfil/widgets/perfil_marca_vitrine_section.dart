import 'package:flutter/material.dart';

import '../../../core/widgets/fx_settings_group.dart';

/// Vitrine — grupo inset ChatGPT/iOS (sem card de preview).
class PerfilMarcaVitrineSection extends StatelessWidget {
  const PerfilMarcaVitrineSection({
    super.key,
    required this.profileComplete,
    required this.children,
  });

  final bool profileComplete;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Sua página online',
      child: FxSettingsGroup(
        header: 'Sua página',
        caption:
            profileComplete ? null : 'Link público e identidade da marca.',
        children: children,
      ),
    );
  }
}
