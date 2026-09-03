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
    final chrome = ShellChrome.forDark(isDark);
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
            showChevron: true,
            onTap: () => Navigator.pop(context, _TreinoAction.assign),
          ),
          TreinoInsetActionSpec(
            icon: Icons.assignment_ind_rounded,
            label: 'Copiar para aluno',
            showChevron: true,
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

class _AssignWorkoutSheet extends StatefulWidget {
  final List<Aluno> alunos;

  const _AssignWorkoutSheet({required this.alunos});

  @override
  State<_AssignWorkoutSheet> createState() => _AssignWorkoutSheetState();
}

class _AssignWorkoutSheetState extends State<_AssignWorkoutSheet> {
  int? selectedAlunoId;

  @override
  void initState() {
    super.initState();
    selectedAlunoId = widget.alunos.isEmpty ? null : widget.alunos.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forDark(isDark);

    return TreinoHomeSheetSurface(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: chrome.mute.withValues(alpha: 0.26),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          SizedBox(height: TokensStrip.s4),
          TreinoSheetChromeHeader(
            icon: Icons.person_add_alt_1_rounded,
            title: 'Atribuir treino',
            subtitle:
                widget.alunos.isEmpty
                    ? 'Cadastre um aluno antes.'
                    : 'Escolha quem recebe este plano.',
            isDark: isDark,
          ),
          const SizedBox(height: TokensStrip.s4),
          if (widget.alunos.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? heroTealSurface(0.04) : TokensStrip.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: chrome.line),
              ),
              child: Text(
                'Adicione um aluno para atribuir treinos direto da biblioteca.',
                style: FocuxHubTypography.bodyMuted(
                  color: chrome.mute,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.alunos.length,
                separatorBuilder: (_, __) => SizedBox(height: TokensStrip.s2),
                itemBuilder: (context, index) {
                  final aluno = widget.alunos[index];
                  final selected = selectedAlunoId == aluno.id;
                  final initials =
                      aluno.nome.trim().isEmpty
                          ? '?'
                          : aluno.nome
                              .trim()
                              .split(RegExp(r'\s+'))
                              .take(2)
                              .map((part) => part[0].toUpperCase())
                              .join();

                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => selectedAlunoId = aluno.id);
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            selected
                                ? BrandPalette.soft(primary, dark: isDark)
                                : isDark
                                ? heroTealSurface(0.03)
                                : heroTealInk(),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color:
                              selected
                                  ? primary.withValues(alpha: 0.30)
                                  : chrome.line,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? primary : chrome.line,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              initials,
                              style: FocuxHubTypography.bodyMuted(
                                color: selected ? heroTealInk() : chrome.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          SizedBox(width: TokensStrip.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  aluno.nome,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FocuxHubTypography.cardTitle(
                                    color: chrome.ink,
                                  ),
                                ),
                                SizedBox(height: TokensStrip.s1),
                                Text(
                                  aluno.objetivo?.trim().isNotEmpty == true
                                      ? TreinosListLabels.prettyField(
                                        aluno.objetivo!.trim(),
                                      )
                                      : 'Objetivo não definido',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FocuxHubTypography.bodyMuted(
                                    color: chrome.mute,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color:
                                selected
                                    ? primary
                                    : chrome.mute.withValues(alpha: 0.7),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: TokensStrip.s4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: chrome.ink,
                    side: BorderSide(color: chrome.line),
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Cancelar',
                    style: FocuxHubTypography.cardTitle(color: chrome.ink),
                  ),
                ),
              ),
              SizedBox(width: TokensStrip.s3),
              Expanded(
                child: FilledButton(
                  onPressed:
                      selectedAlunoId == null
                          ? null
                          : () => Navigator.pop(context, selectedAlunoId),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: heroTealInk(),
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Atribuir',
                    style: FocuxHubTypography.cardTitle(color: heroTealInk()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
