import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../dashboard/data/command_action_item.dart';
import '../../dashboard/widgets/command_action_tile.dart';

/// Pendência financeira — navegação para mensalidades, não transação.
class Aluno360FinanceRiskBanner extends StatelessWidget {
  const Aluno360FinanceRiskBanner({
    super.key,
    required this.alunoId,
  });

  final int alunoId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CommandActionTile(
      item: const CommandActionItem(
        icon: 'alert-triangle',
        title: 'Pendência financeira',
        subtitle: 'Abrir mensalidades deste aluno',
        route: '/financeiro',
        tone: CommandActionTone.hot,
      ),
      isDark: isDark,
      primary: EagleTokens.bad,
      showDivider: false,
      onTap: () => context.push('/financeiro?alunoId=$alunoId'),
    );
  }
}
