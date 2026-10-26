import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_week_strip.dart';
import '../../../l10n/app_localizations.dart';
import 'dashboard_section_header.dart';

/// "Esta semana": o kit [FxWeekStrip] com título. A faixa toda toca e leva
/// à aba Treinos.
class AlunoSemanaFaixa extends StatelessWidget {
  const AlunoSemanaFaixa({super.key, required this.dias, required this.onTap});

  final List<FxWeekDay> dias;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (dias.isEmpty) return const SizedBox.shrink();
    final s = S.of(context);
    return Semantics(
      button: true,
      label: '${s.alunoSemanaFaixaTitulo}. ${FxWeekStrip.semantica(s, dias)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardSectionHeader(title: s.alunoSemanaFaixaTitulo),
            const SizedBox(height: TokensStrip.s2),
            FxWeekStrip(dias: dias),
          ],
        ),
      ),
    );
  }
}
