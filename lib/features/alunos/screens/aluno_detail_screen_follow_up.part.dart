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
              Text(
                'Follow-up do personal',
                style: TextStyle(
                  color: ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Semantics(
                label: 'Definir data de próximo contato para ${aluno.nome}',
                button: true,
                child: OutlinedButton.icon(
                onPressed: () => _pickFollowUpDate(context, ref),
                icon: const Icon(Icons.calendar_month_rounded, size: 16),
                label: const Text('Definir data'),
              ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await actions.snooze(aluno.id);
                  if (context.mounted) {
                    FeedbackHelper.showSuccess(context, 'Adiado por 24h');
                  }
                },
                icon: const Icon(Icons.snooze_rounded, size: 16),
                label: const Text('Adiar 24h'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await actions.snooze(aluno.id, duration: const Duration(days: 3));
                  if (context.mounted) {
                    FeedbackHelper.showSuccess(context, 'Adiado por 3 dias');
                  }
                },
                icon: const Icon(Icons.schedule_rounded, size: 16),
                label: const Text('Adiar 3d'),
              ),
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
