import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../data/aluno_repository.dart';

class Aluno360StudentQuickActions extends StatelessWidget {
  const Aluno360StudentQuickActions({
    super.key,
    required this.aluno,
    required this.isDark,
    required this.primary,
    required this.onPassword,
    required this.onEdit,
    required this.onEvolve,
  });

  final Aluno aluno;
  final bool isDark;
  final Color primary;
  final VoidCallback onPassword;
  final VoidCallback onEdit;
  final VoidCallback onEvolve;

  @override
  Widget build(BuildContext context) {
    final firstName = aluno.nome.split(' ').first;
    return Semantics(
      container: true,
      label: 'Ações rápidas da aba operação. Acesso e evolução de $firstName',
      child: Wrap(
        spacing: TokensStrip.s2,
        runSpacing: TokensStrip.s2,
        children: [
          DashboardHomeActionChip(
            label: 'Senha',
            accent: primary,
            isDark: isDark,
            onPressed: onPassword,
          ),
          DashboardHomeActionChip(
            label: 'Evoluir',
            accent: primary,
            isDark: isDark,
            onPressed: onEvolve,
          ),
          DashboardHomeActionChip(
            label: 'Editar',
            accent: primary,
            isDark: isDark,
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}
