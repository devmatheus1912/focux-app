import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_followup_provider.dart';
import '../utils/aluno360_followup_dates.dart';

/// Compromisso do personal com o aluno — follow-up ou sono (mesmo contrato).
enum Aluno360CommitmentKind { followUp, sleep }

/// S7: Feito / Definir data / Adiar / Limpar. Sem endpoint novo — reuse follow-up.
Future<void> showAluno360CommitmentSheet(
  BuildContext context, {
  required Aluno aluno,
  Aluno360CommitmentKind kind = Aluno360CommitmentKind.followUp,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showFxHomeSheet<void>(
    context,
    builder: (sheetContext) {
      return Aluno360CommitmentSheet(
        aluno: aluno,
        kind: kind,
        isDark: isDark,
        hostContext: context,
      );
    },
  );
}

class Aluno360CommitmentSheet extends ConsumerStatefulWidget {
  const Aluno360CommitmentSheet({
    super.key,
    required this.aluno,
    required this.kind,
    required this.isDark,
    required this.hostContext,
  });

  final Aluno aluno;
  final Aluno360CommitmentKind kind;
  final bool isDark;
  final BuildContext hostContext;

  @override
  ConsumerState<Aluno360CommitmentSheet> createState() =>
      _Aluno360CommitmentSheetState();
}

class _Aluno360CommitmentSheetState
    extends ConsumerState<Aluno360CommitmentSheet> {
  bool _busy = false;

  Aluno get aluno => widget.aluno;

  bool get _isSleep => widget.kind == Aluno360CommitmentKind.sleep;

  String _formatDate(DateTime date) => alunoFollowUpDateLabel(date);

  String _formatTime(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _title => _isSleep ? 'Combinar sono' : 'Follow-up';

  String get _doneLabel => _isSleep ? 'Feito' : 'Contato feito';

  String get _subtitle {
    if (_isSleep) {
      return 'Combine o horário e registre quando falar com ${aluno.nome}.';
    }
    return 'Quando você fala de novo com ${aluno.nome}.';
  }

  String _statusLine({
    required DateTime? followUpDate,
    required bool isSnoozed,
    required DateTime? snoozedUntil,
  }) {
    final parts = <String>[];
    if (aluno.ultimoContatoDate != null) {
      parts.add('Último contato: ${_formatDate(aluno.ultimoContatoDate!)}');
    }
    if (isSnoozed && snoozedUntil != null) {
      parts.add(
        'Adiado até ${_formatDate(snoozedUntil)} ${_formatTime(snoozedUntil)}',
      );
    } else if (followUpDate != null) {
      parts.add('Próximo contato: ${_formatDate(followUpDate)}');
    } else if (_isSleep) {
      parts.add('Ainda sem data — use Definir data ou Adiar');
    } else {
      parts.add('Agendar próximo contato · sincronizado com a nuvem');
    }
    return parts.join(' · ');
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      if (successMessage.isNotEmpty) {
        FeedbackHelper.showOperacaoSuccess(
          widget.hostContext.mounted ? widget.hostContext : context,
          successMessage,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showOperacaoError(
        widget.hostContext.mounted ? widget.hostContext : context,
        friendlyError(e, fallback: 'Não foi possível salvar o follow-up.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markDone(dynamic actions) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = await actions.markContactDone(aluno.id);
      if (!mounted) return;
      final when = updated.ultimoContatoDate;
      final msg =
          when == null
              ? (_isSleep ? 'Combinado registrado' : 'Contato registrado')
              : (_isSleep
                  ? 'Combinado em ${_formatDate(when)}'
                  : 'Contato registrado em ${_formatDate(when)}');
      FeedbackHelper.showOperacaoSuccess(
        widget.hostContext.mounted ? widget.hostContext : context,
        msg,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showOperacaoError(
        widget.hostContext.mounted ? widget.hostContext : context,
        friendlyError(e, fallback: 'Não foi possível salvar o follow-up.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate() async {
    if (_busy) return;
    final options = alunoFollowUpDateOptions(DateTime.now());
    final picked = await showFxInsetPickerSheet<DateTime>(
      context,
      title: _isSleep ? 'Quando combinar' : 'Próximo contato',
      subtitle:
          _isSleep
              ? 'Data para falar do sono com ${aluno.nome}.'
              : 'Quando você fala de novo com ${aluno.nome}.',
      headerIcon: Icons.event_outlined,
      selected: alunoFollowUpDateSelected(
        options: options,
        current: aluno.followUpDate,
      ),
      sameValue:
          (a, b) => a.year == b.year && a.month == b.month && a.day == b.day,
      items: [
        for (final option in options)
          FxInsetPickerSheetItem(
            value: option.date,
            label: option.label,
            subtitle: option.subtitle,
            icon: Icons.event_outlined,
          ),
      ],
    );
    if (picked == null) return;
    await _runAction(
      () => ref
          .read(alunoFollowUpActionsProvider)
          .setFollowUpDate(aluno.id, picked),
      _isSleep
          ? 'Sono combinado para ${_formatDate(picked)}'
          : 'Follow-up definido para ${_formatDate(picked)}',
    );
  }

  Future<void> _showSnoozeSheet(dynamic actions) async {
    if (_busy) return;
    final picked = await showFxInsetPickerSheet<Duration>(
      context,
      title: _isSleep ? 'Adiar sono' : 'Adiar follow-up',
      subtitle:
          _isSleep
              ? 'Quando voltar a combinar o sono com ${aluno.nome}.'
              : 'Escolha por quanto tempo adiar o contato com ${aluno.nome}.',
      headerIcon: Icons.snooze_rounded,
      items: const [
        FxInsetPickerSheetItem(
          value: Duration(hours: 24),
          label: 'Adiar 24 horas',
          subtitle: 'Amanhã no mesmo horário',
          icon: Icons.snooze_rounded,
        ),
        FxInsetPickerSheetItem(
          value: Duration(days: 3),
          label: 'Adiar 3 dias',
          subtitle: 'Reabrir daqui a 72 horas',
          icon: Icons.date_range_rounded,
        ),
      ],
    );
    if (picked == null) return;
    if (picked.inDays >= 3) {
      await _runAction(
        () => actions.snooze(aluno.id, duration: const Duration(days: 3)),
        'Adiado por 3 dias',
      );
      return;
    }
    await _runAction(() => actions.snooze(aluno.id), 'Adiado por 24h');
  }

  Future<void> _confirmClear(dynamic actions) async {
    if (_busy) return;
    final confirmed = await showFxConfirmSheet(
      context,
      title: _isSleep ? 'Limpar combinação?' : 'Limpar follow-up?',
      message:
          'Remove a data combinada de ${aluno.nome}. '
          'Você pode definir outra data depois.',
      icon: Icons.event_busy_rounded,
      confirmLabel: 'Limpar',
    );
    if (!confirmed) return;
    await _runAction(
      () => actions.clearFollowUp(aluno.id),
      _isSleep ? 'Combinação limpa' : 'Follow-up limpo',
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final mute = fxScreenMute(context);
    final followUpDate = aluno.followUpDate;
    final snoozedUntil = aluno.snoozedUntilDate;
    final isSnoozed =
        snoozedUntil != null && snoozedUntil.isAfter(DateTime.now());
    final actions = ref.read(alunoFollowUpActionsProvider);
    final status = _statusLine(
      followUpDate: followUpDate,
      isSnoozed: isSnoozed,
      snoozedUntil: snoozedUntil,
    );

    Widget secondary(String label, VoidCallback onPressed) {
      return OutlinedButton(
        style: Aluno360Layout.operacaoOutlinedButtonStyle(context, primary),
        onPressed: _busy ? null : onPressed,
        child: Text(label),
      );
    }

    return FxHomeSheetScaffold(
      isDark: widget.isDark,
      leading: Icon(
        _isSleep ? Icons.bedtime_outlined : Icons.event_outlined,
        color: primary,
        size: 20,
      ),
      title: _title,
      subtitle: _subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            status,
            style: FocuxHubTypography.bodyMuted(
              color: mute,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: TokensStrip.s4),
          FilledButton(
            style: Aluno360Layout.operacaoFilledButtonStyle(context, primary),
            onPressed: _busy ? null : () => _markDone(actions),
            child: Text(_doneLabel),
          ),
          const SizedBox(height: TokensStrip.s2),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: [
              secondary(
                followUpDate == null
                    ? 'Definir data'
                    : 'Data ${_formatDate(followUpDate)}',
                _pickDate,
              ),
              secondary('Adiar', () => _showSnoozeSheet(actions)),
              if (followUpDate != null || isSnoozed)
                secondary('Limpar', () => _confirmClear(actions)),
            ],
          ),
        ],
      ),
    );
  }
}
