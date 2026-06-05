part of 'aluno_detail_screen.dart';

class _AlunoFollowUpCard extends ConsumerStatefulWidget {
  const _AlunoFollowUpCard({required this.aluno, required this.isDark});

  final Aluno aluno;
  final bool isDark;

  @override
  ConsumerState<_AlunoFollowUpCard> createState() => _AlunoFollowUpCardState();
}

class _AlunoFollowUpCardState extends ConsumerState<_AlunoFollowUpCard> {
  bool _busy = false;

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
        FeedbackHelper.showSuccess(context, successMessage);
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
                ? 'Sem data definida · sincronizado com a nuvem'
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
          LayoutBuilder(
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
              final primaryActions = [
                Semantics(
                  label: 'Registrar contato realizado com ${aluno.nome}',
                  button: true,
                  child: FilledButton.icon(
                    onPressed:
                        _busy
                            ? null
                            : () => _runAction(
                              () => actions.markContactDone(aluno.id),
                              'Contato registrado',
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
                ),
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
                    ...primaryActions.map(
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

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...primaryActions,
                  Semantics(
                    label: 'Adiar follow-up de ${aluno.nome} por 24 horas',
                    button: true,
                    child: OutlinedButton.icon(
                      onPressed:
                          _busy
                              ? null
                              : () => _runAction(
                                () => actions.snooze(aluno.id),
                                'Follow-up adiado por 24h',
                              ),
                      icon: const Icon(Icons.snooze_rounded, size: 16),
                      label: const Text('Adiar 24h'),
                      style: compactOutlined,
                    ),
                  ),
                  Semantics(
                    label: 'Adiar follow-up de ${aluno.nome} por 3 dias',
                    button: true,
                    child: OutlinedButton.icon(
                      onPressed:
                          _busy
                              ? null
                              : () => _runAction(
                                () => actions.snooze(
                                  aluno.id,
                                  duration: const Duration(days: 3),
                                ),
                                'Follow-up adiado por 3 dias',
                              ),
                      icon: const Icon(Icons.schedule_rounded, size: 16),
                      label: const Text('Adiar 3d'),
                      style: compactOutlined,
                    ),
                  ),
                  if (followUpDate != null || isSnoozed)
                    TextButton(
                      onPressed:
                          _busy
                              ? null
                              : () => _runAction(
                                () => actions.clearFollowUp(aluno.id),
                                'Follow-up limpo',
                              ),
                      child: const Text('Limpar'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
