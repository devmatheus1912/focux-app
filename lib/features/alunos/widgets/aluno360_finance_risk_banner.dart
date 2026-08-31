import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';

/// Finance delinquency row on the Operação tab — inset Perfil, not a tinted card.
class Aluno360FinanceRiskBanner extends StatelessWidget {
  const Aluno360FinanceRiskBanner({
    super.key,
    required this.alunoId,
  });

  final int alunoId;

  @override
  Widget build(BuildContext context) {
    return FxSettingsGroup(
      accent: EagleTokens.bad,
      children: [
        FxSettingsTile(
          icon: Icons.payments_outlined,
          label: 'Pendência financeira',
          subtitle: 'Abrir mensalidades deste aluno',
          value: '',
          accent: EagleTokens.bad,
          highlight: true,
          showDivider: false,
          semanticsLabel:
              'Pendência financeira. Abrir mensalidades deste aluno',
          onTap: () => context.push('/financeiro?alunoId=$alunoId'),
        ),
      ],
    );
  }
}
