part of 'aluno_detail_screen.dart';

class _AlunoFollowUpCard extends ConsumerWidget {
  const _AlunoFollowUpCard({required this.aluno, required this.isDark});

  final Aluno aluno;
  final bool isDark;

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> _pickFollowUpDate(BuildContext context, WidgetRef ref) async {
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
    await ref.read(alunoFollowUpActionsProvider).setFollowUpDate(aluno.id, picked);
    if (context.mounted) {
      FeedbackHelper.showSuccess(
        context,
        'Follow-up definido para ${_formatDate(picked)}',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final primary = Theme.of(context).colorScheme.primary;
    final followUpDate = aluno.followUpDate;
    final snoozedUntil = aluno.snoozedUntilDate;
    final isSnoozed =
        snoozedUntil != null && snoozedUntil.isAfter(DateTime.now());
    final actions = ref.read(alunoFollowUpActionsProvider);

    return Container(
      decoration: fxListCardDecoration(context),
      padding: const EdgeInsets.all(16),
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
            style: TextStyle(color: mute, fontSize: 12, height: 1.35),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (aluno.ultimoContatoDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Último contato: ${_formatDate(aluno.ultimoContatoDate!)}',
              style: TextStyle(color: mute, fontSize: 11.5),
            ),
          ],
          if (isSnoozed) ...[
            const SizedBox(height: 6),
            Text(
              'Adiado até ${_formatDate(snoozedUntil)} ${_formatTime(snoozedUntil)}',
              style: TextStyle(
                color: EagleTokens.warn,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 360;
              final primaryActions = [
                Semantics(
                  label: 'Registrar contato realizado com ${aluno.nome}',
                  button: true,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await actions.markContactDone(aluno.id);
                      if (context.mounted) {
                        FeedbackHelper.showSuccess(context, 'Contato registrado');
                      }
                    },
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Contato feito'),
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                Semantics(
                  label: 'Definir data de próximo contato para ${aluno.nome}',
                  button: true,
                  child: OutlinedButton.icon(
                    onPressed: () => _pickFollowUpDate(context, ref),
                    icon: const Icon(Icons.calendar_month_rounded, size: 16),
                    label: const Text('Definir data'),
                  ),
                ),
              ];

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...primaryActions.map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(width: double.infinity, child: action),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: PopupMenuButton<String>(
                        tooltip: 'Adiar follow-up',
                        onSelected: (value) async {
                          if (value == '24h') {
                            await actions.snooze(aluno.id);
                            if (context.mounted) {
                              FeedbackHelper.showSuccess(context, 'Adiado por 24h');
                            }
                          } else if (value == '3d') {
                            await actions.snooze(
                              aluno.id,
                              duration: const Duration(days: 3),
                            );
                            if (context.mounted) {
                              FeedbackHelper.showSuccess(context, 'Adiado por 3 dias');
                            }
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
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (followUpDate != null || isSnoozed)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () async {
                            await actions.clearFollowUp(aluno.id);
                            if (context.mounted) {
                              FeedbackHelper.showSuccess(context, 'Follow-up limpo');
                            }
                          },
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
                      onPressed: () async {
                        await actions.snooze(aluno.id);
                        if (context.mounted) {
                          FeedbackHelper.showSuccess(context, 'Adiado por 24h');
                        }
                      },
                      icon: const Icon(Icons.snooze_rounded, size: 16),
                      label: const Text('Adiar 24h'),
                    ),
                  ),
                  Semantics(
                    label: 'Adiar follow-up de ${aluno.nome} por 3 dias',
                    button: true,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await actions.snooze(
                          aluno.id,
                          duration: const Duration(days: 3),
                        );
                        if (context.mounted) {
                          FeedbackHelper.showSuccess(context, 'Adiado por 3 dias');
                        }
                      },
                      icon: const Icon(Icons.schedule_rounded, size: 16),
                      label: const Text('Adiar 3d'),
                    ),
                  ),
                  if (followUpDate != null || isSnoozed)
                    TextButton(
                      onPressed: () async {
                        await actions.clearFollowUp(aluno.id);
                        if (context.mounted) {
                          FeedbackHelper.showSuccess(context, 'Follow-up limpo');
                        }
                      },
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
