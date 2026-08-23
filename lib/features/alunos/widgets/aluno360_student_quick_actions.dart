import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/aluno_360_layout.dart';
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
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    return Semantics(
      container: true,
      label: 'Ações rápidas da aba operação',
      child: Container(
        padding: const EdgeInsets.all(Aluno360Layout.cardPadding),
        decoration: Aluno360Layout.operacaoInsetSectionDecoration(
          context,
          primary: primary,
          isDark: isDark,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.flash_on_rounded, color: primary, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ações rápidas',
                        style: Aluno360Layout.panelTitleStyle(context, ink),
                      ),
                      Text(
                        'Acesso e evolução de ${aluno.nome.split(' ').first}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Aluno360Layout.captionStyle(
                          context,
                        ).copyWith(color: mute, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Aluno360QuickActionPill(
                    icon: Icons.key_outlined,
                    label: 'Senha',
                    primary: primary,
                    onTap: onPassword,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Aluno360QuickActionPill(
                    icon: Icons.trending_up_rounded,
                    label: 'Evoluir',
                    primary: primary,
                    onTap: onEvolve,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Aluno360QuickActionPill(
                    icon: Icons.edit_outlined,
                    label: 'Editar',
                    primary: primary,
                    onTap: onEdit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Aluno360QuickActionPill extends StatelessWidget {
  const Aluno360QuickActionPill({
    super.key,
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillInk =
        Color.lerp(
          primary,
          isDark ? Colors.white : Colors.black,
          isDark ? 0.08 : 0.55,
        )!;
    return Semantics(
      button: true,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: isDark ? 0.14 : 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: primary.withValues(alpha: isDark ? 0.42 : 0.50),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: pillInk),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.bodyMuted(
                      color: pillInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
