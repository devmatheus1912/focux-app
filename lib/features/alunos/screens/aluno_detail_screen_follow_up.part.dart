part of 'aluno_detail_screen.dart';

class _AlunoFollowUpCard extends ConsumerStatefulWidget {
  const _AlunoFollowUpCard({
    required this.aluno,
    required this.isDark,
    this.compactContactPriority = false,
  });

  final Aluno aluno;
  final bool isDark;
  final bool compactContactPriority;

  @override
  ConsumerState<_AlunoFollowUpCard> createState() => _AlunoFollowUpCardState();
}

class _AlunoFollowUpCardState extends ConsumerState<_AlunoFollowUpCard> {
  bool _busy = false;
  bool _expanded = false;

  Aluno get aluno => widget.aluno;

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        FeedbackHelper.showSuccess(
          context,
          successMessage,
          reserveBottom: Aluno360Layout.snackbarStickyReserve,
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: 'Não foi possível salvar o follow-up.'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFollowUpDate() async {
    if (_busy) return;
    final now = DateTime.now();
    final current = aluno.followUpDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Próximo contato',
    );
    if (picked == null) return;
    await _runAction(
      () => ref.read(alunoFollowUpActionsProvider).setFollowUpDate(aluno.id, picked),
      'Follow-up definido para ${_formatDate(picked)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final ink = fxScreenInk(context);
    final primary = Theme.of(context).colorScheme.primary;
    final followUpDate = aluno.followUpDate;
    final snoozedUntil = aluno.snoozedUntilDate;
    final isSnoozed =
        snoozedUntil != null && snoozedUntil.isAfter(DateTime.now());
    final actions = ref.read(alunoFollowUpActionsProvider);
    final compact = widget.compactContactPriority;

    if (compact) {
      return Container(
        decoration: fxListCardDecoration(context),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: const ValueKey('aluno360_followup_compact'),
            initiallyExpanded: _expanded,
            onExpansionChanged: (value) => setState(() => _expanded = value),
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            leading: Icon(Icons.event_available_rounded, size: 18, color: primary),
            title: Text(
              'Follow-up do personal',
              style: TextStyle(
                color: ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              'Prioridade é contato · expanda para agendar',
              style: Aluno360Layout.captionStyle(context),
            ),
            children: [
              _buildFollowUpActions(
                context,
                primary: primary,
                ink: ink,
                followUpDate: followUpDate,
                isSnoozed: isSnoozed,
                snoozedUntil: snoozedUntil,
                actions: actions,
                contactPrimaryOutlined: true,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: fxListCardDecoration(context),
      padding: const EdgeInsets.all(Aluno360Layout.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available_rounded, size: 18, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Follow-up do personal',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            followUpDate == null
                ? 'Agendar próximo contato · sincronizado com a nuvem'
                : 'Próximo contato: ${_formatDate(followUpDate)}',
            style: Aluno360Layout.captionStyle(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (aluno.ultimoContatoDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Último contato: ${_formatDate(aluno.ultimoContatoDate!)}',
              style: Aluno360Layout.metaStyle(context),
            ),
          ],
          if (isSnoozed) ...[
            const SizedBox(height: 6),
            Text(
              'Adiado até ${_formatDate(snoozedUntil)} ${_formatTime(snoozedUntil)}',
              style: Aluno360Layout.metaStyle(context).copyWith(
                color: EagleTokens.warn,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _buildFollowUpActions(
            context,
            primary: primary,
            ink: ink,
            followUpDate: followUpDate,
            isSnoozed: isSnoozed,
            snoozedUntil: snoozedUntil,
            actions: actions,
            contactPrimaryOutlined: false,
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpActions(
    BuildContext context, {
    required Color primary,
    required Color ink,
    required DateTime? followUpDate,
    required bool isSnoozed,
    required DateTime? snoozedUntil,
    required dynamic actions,
    required bool contactPrimaryOutlined,
  }) {
    return LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 360;
              final compactFilled = FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                visualDensity: VisualDensity.compact,
                backgroundColor: primary,
                foregroundColor: Colors.white,
              );
              final compactOutlined = OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                visualDensity: VisualDensity.compact,
                foregroundColor: primary,
                side: BorderSide(color: primary.withValues(alpha: 0.28)),
              );
              Widget contactDoneButton({required bool fullWidth}) {
                final child = Semantics(
                  label: 'Registrar contato realizado com ${aluno.nome}',
                  button: true,
                  child:
                      contactPrimaryOutlined
                          ? OutlinedButton.icon(
                            onPressed:
                                _busy
                                    ? null
                                    : () => _runAction(
                                      () => actions.markContactDone(aluno.id),
                                      'Contato salvo · follow-up atualizado',
                                    ),
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Contato feito'),
                            style: compactOutlined,
                          )
                          : FilledButton.icon(
                            onPressed:
                                _busy
                                    ? null
                                    : () => _runAction(
                                      () => actions.markContactDone(aluno.id),
                                      'Contato salvo · follow-up atualizado',
                                    ),
                            icon:
                                _busy
                                    ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: FxLoading(
                                        size: 16,
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Contato feito'),
                            style: compactFilled,
                          ),
                );
                return fullWidth
                    ? SizedBox(width: double.infinity, child: child)
                    : child;
              }

              final primaryActions = [
                contactDoneButton(fullWidth: false),
                Semantics(
                  label: 'Definir data de próximo contato para ${aluno.nome}',
                  button: true,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _pickFollowUpDate,
                    icon: const Icon(Icons.calendar_month_rounded, size: 16),
                    label: const Text('Definir data'),
                    style: compactOutlined,
                  ),
                ),
              ];

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    contactDoneButton(fullWidth: true),
                    const SizedBox(height: 6),
                    ...primaryActions.skip(1).map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: SizedBox(width: double.infinity, child: action),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: PopupMenuButton<String>(
                        tooltip: 'Adiar follow-up',
                        enabled: !_busy,
                        onSelected: (value) async {
                          if (value == '24h') {
                            await _runAction(
                              () => actions.snooze(aluno.id),
                              'Follow-up adiado por 24h',
                            );
                          } else if (value == '3d') {
                            await _runAction(
                              () => actions.snooze(
                                aluno.id,
                                duration: const Duration(days: 3),
                              ),
                              'Follow-up adiado por 3 dias',
                            );
                          }
                        },
                        itemBuilder:
                            (_) => const [
                              PopupMenuItem(value: '24h', child: Text('Adiar 24h')),
                              PopupMenuItem(value: '3d', child: Text('Adiar 3 dias')),
                            ],
                        child: Semantics(
                          label: 'Adiar follow-up de ${aluno.nome}',
                          button: true,
                          child: IgnorePointer(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.snooze_rounded, size: 16),
                              label: const Text('Adiar'),
                              style: compactOutlined,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (followUpDate != null || isSnoozed)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed:
                              _busy
                                  ? null
                                  : () => _runAction(
                                    () => actions.clearFollowUp(aluno.id),
                                    'Follow-up limpo',
                                  ),
                          child: const Text('Limpar'),
                        ),
                      ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  contactDoneButton(fullWidth: true),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: primaryActions[1],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PopupMenuButton<String>(
                          tooltip: 'Adiar follow-up',
                          enabled: !_busy,
                          onSelected: (value) async {
                            if (value == '24h') {
                              await _runAction(
                                () => actions.snooze(aluno.id),
                                'Follow-up adiado por 24h',
                              );
                            } else if (value == '3d') {
                              await _runAction(
                                () => actions.snooze(
                                  aluno.id,
                                  duration: const Duration(days: 3),
                                ),
                                'Follow-up adiado por 3 dias',
                              );
                            }
                          },
                          itemBuilder:
                              (_) => const [
                                PopupMenuItem(value: '24h', child: Text('Adiar 24h')),
                                PopupMenuItem(value: '3d', child: Text('Adiar 3 dias')),
                              ],
                          child: Semantics(
                            label: 'Adiar follow-up de ${aluno.nome}',
                            button: true,
                            child: IgnorePointer(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.snooze_rounded, size: 16),
                                label: const Text('Adiar'),
                                style: compactOutlined,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (followUpDate != null || isSnoozed)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed:
                            _busy
                                ? null
                                : () => _runAction(
                                  () => actions.clearFollowUp(aluno.id),
                                  'Follow-up limpo',
                                ),
                        child: const Text('Limpar'),
                      ),
                    ),
                ],
              );
            },
          );
  }

  String _formatTime(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// removed duplicate _formatTime and old LayoutBuilder block below
