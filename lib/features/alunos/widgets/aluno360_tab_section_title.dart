import 'package:flutter/material.dart';

import '../constants/aluno_360_layout.dart';

/// H2 section title for Aluno 360 tab surfaces (Medidas, Módulos, etc.).
class Aluno360TabSectionTitle extends StatelessWidget {
  const Aluno360TabSectionTitle({
    super.key,
    required this.title,
    required this.primary,
    required this.isDark,
  });

  final String title;
  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: Aluno360Layout.tabSectionTitleStyle(
          context,
          primary: primary,
          isDark: isDark,
        ),
      ),
    );
  }
}
