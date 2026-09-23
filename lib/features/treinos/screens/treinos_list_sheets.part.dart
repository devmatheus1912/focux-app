part of 'treinos_list_screen.dart';

class _DeleteWorkoutSheet extends StatelessWidget {
  final int count;
  final String? name;
  final bool unlinkOnly;

  const _DeleteWorkoutSheet({
    required this.count,
    required this.name,
    required this.unlinkOnly,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chrome = ShellChrome.forBrightness(context, isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final line = chrome.line;
    final dangerSoft =
        isDark
            ? EagleTokens.bad.withValues(alpha: 0.16)
            : EagleTokens.badSoft.withValues(alpha: 0.88);
    final title = TreinosListLabels.deleteTitle(
      unlinkOnly: unlinkOnly,
      count: count,
    );
    final body = TreinosListLabels.deleteBody(
      unlinkOnly: unlinkOnly,
      count: count,
      name: name,
    );
    final actionLabel = TreinosListLabels.deleteConfirmLabel(
      unlinkOnly: unlinkOnly,
    );

    return TreinoHomeSheetSurface(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          SizedBox(height: TokensStrip.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: dangerSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  unlinkOnly
                      ? Icons.link_off_rounded
                      : Icons.delete_outline_rounded,
                  color: EagleTokens.bad,
                  size: 23,
                ),
              ),
              SizedBox(width: TokensStrip.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: FocuxHubTypography.pageTitle(
                        context,
                        color: ink,
                      ).copyWith(fontWeight: FontWeight.w800, height: 1.15),
                    ),
                    SizedBox(height: TokensStrip.s2),
                    Text(
                      body,
                      style: FocuxHubTypography.bodyMuted(
                        color: mute,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: TokensStrip.s4),
          SizedBox(
            height: TreinosLayout.touchTarget,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: EagleTokens.bad,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: TreinosLayout.touchTarget,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: mute,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _TreinoAction { open, assign, clone, duplicate, delete }

class _TreinoActionsSheet extends StatelessWidget {
  final Treino treino;
  final bool canAssign;

  const _TreinoActionsSheet({required this.treino, required this.canAssign});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    final displayName = displayWorkoutName(treino.nome);

    return TreinoInsetActionSheet(
      isDark: isDark,
      maxHeight: maxHeight,
      headerIcon: Icons.fitness_center_rounded,
      title: 'Ações do treino',
      subtitle: displayName,
      accent: primary,
      actions: [
        TreinoInsetActionSpec(
          icon: Icons.open_in_new_rounded,
          label: 'Abrir treino',
          showChevron: true,
          onTap: () => Navigator.pop(context, _TreinoAction.open),
        ),
        if (canAssign) ...[
          TreinoInsetActionSpec(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Atribuir a um aluno',
            onTap: () => Navigator.pop(context, _TreinoAction.assign),
          ),
          TreinoInsetActionSpec(
            icon: Icons.assignment_ind_rounded,
            label: 'Copiar para aluno',
            onTap: () => Navigator.pop(context, _TreinoAction.clone),
          ),
        ],
        TreinoInsetActionSpec(
          icon: Icons.control_point_duplicate_rounded,
          label: 'Duplicar treino',
          onTap: () => Navigator.pop(context, _TreinoAction.duplicate),
        ),
        TreinoInsetActionSpec(
          icon: Icons.delete_outline_rounded,
          label: 'Excluir treino',
          danger: true,
          onTap: () => Navigator.pop(context, _TreinoAction.delete),
        ),
      ],
    );
  }
}
