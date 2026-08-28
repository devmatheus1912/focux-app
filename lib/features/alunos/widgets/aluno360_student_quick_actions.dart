import 'package:flutter/material.dart';

import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
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
      label: 'Ações rápidas da aba operação',
      child: FxSettingsGroup(
        header: 'Ações rápidas',
        caption: 'Acesso e evolução de $firstName',
        accent: primary,
        children: [
          FxSettingsTile(
            icon: Icons.key_outlined,
            label: 'Senha',
            subtitle: 'Redefinir acesso do aluno',
            value: '',
            onTap: onPassword,
          ),
          FxSettingsTile(
            icon: Icons.trending_up_rounded,
            label: 'Evoluir',
            subtitle: 'Medidas e histórico corporal',
            value: '',
            onTap: onEvolve,
          ),
          FxSettingsTile(
            icon: Icons.edit_outlined,
            label: 'Editar',
            subtitle: 'Cadastro e objetivo',
            value: '',
            showDivider: false,
            onTap: onEdit,
          ),
        ],
      ),
    );
  }
}
