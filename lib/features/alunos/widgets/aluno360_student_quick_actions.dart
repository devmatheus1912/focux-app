import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../data/aluno_repository.dart';

/// Ações secundárias da Operação — atrás de um toque (v3.1 / A30).
class Aluno360StudentQuickActions extends StatelessWidget {
  const Aluno360StudentQuickActions({
    super.key,
    required this.aluno,
    required this.isDark,
    required this.primary,
    required this.onPassword,
    required this.onEdit,
    required this.onEvolve,
    this.onLista,
  });

  final Aluno aluno;
  final bool isDark;
  final Color primary;
  final VoidCallback onPassword;
  final VoidCallback onEdit;
  final VoidCallback onEvolve;
  final VoidCallback? onLista;

  Future<void> _openMaisAcoes(BuildContext context) async {
    final firstName = aluno.nome.split(' ').first;
    final items = <FxInsetPickerSheetItem<VoidCallback>>[
      if (onLista != null)
        FxInsetPickerSheetItem(
          value: onLista!,
          label: 'Lista de alunos',
          subtitle: 'Voltar para a lista',
          icon: Icons.list_alt_rounded,
        ),
      FxInsetPickerSheetItem(
        value: onPassword,
        label: 'Senha de acesso',
        subtitle: 'Gerar ou reenviar para $firstName',
        icon: Icons.password_rounded,
      ),
      FxInsetPickerSheetItem(
        value: onEvolve,
        label: 'Evoluir com IA',
        subtitle: 'Sugestão de carga e progressão',
        icon: Icons.auto_awesome_outlined,
      ),
      FxInsetPickerSheetItem(
        value: onEdit,
        label: 'Editar cadastro',
        subtitle: 'Dados, contato e objetivo',
        icon: Icons.edit_outlined,
      ),
    ];
    final chosen = await showFxInsetPickerSheet<VoidCallback>(
      context,
      title: 'Mais ações',
      headerIcon: Icons.more_horiz_rounded,
      selected: null,
      items: items,
    );
    if (chosen == null) return;
    HapticFeedback.selectionClick();
    chosen();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = aluno.nome.split(' ').first;
    return Semantics(
      container: true,
      label: 'Mais ações da operação para $firstName',
      child: Align(
        alignment: Alignment.centerLeft,
        child: DashboardHomeActionChip(
          label: 'Mais ações',
          accent: primary,
          isDark: isDark,
          onPressed: () => _openMaisAcoes(context),
        ),
      ),
    );
  }
}
