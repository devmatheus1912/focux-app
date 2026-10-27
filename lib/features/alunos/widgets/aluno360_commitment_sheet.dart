import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_quick_chips.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
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

  /// Atalhos de data: amanhã, em 3 dias, em 1 semana. "Outro" abre a lista completa.
  List<DateTime> get _atalhosDeData {
    final hoje = DateTime.now();
    final base = DateTime(hoje.year, hoje.month, hoje.day);
    return [
      base.add(const Duration(days: 1)),
      base.add(const Duration(days: 3)),
      base.add(const Duration(days: 7)),
    ];
  }

  bool _mesmoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _rotuloAtalho(DateTime d) {
    final dias = d.difference(_atalhosDeData.first).inDays;
    return switch (dias) {
      0 => 'Amanhã',
      2 => 'Em 3 dias',
      _ => 'Em 1 semana',
    };
  }

  Future<void> _definirAtalho(DateTime data) {
    return _runAction(
      () => ref.read(alunoFollowUpActionsProvider).setFollowUpDate(aluno.id, data),
      _isSleep
          ? 'Sono combinado para ${_formatDate(data)}'
          : 'Follow-up definido para ${_formatDate(data)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final followUpDate = aluno.followUpDate;
    final snoozedUntil = aluno.snoozedUntilDate;
    final isSnoozed =
        snoozedUntil != null && snoozedUntil.isAfter(DateTime.now());
    final actions = ref.read(alunoFollowUpActionsProvider);
    final atalhos = _atalhosDeData;
    final dataAtual = isSnoozed ? null : followUpDate;
    final dataEhAtalho =
        dataAtual != null && atalhos.any((d) => _mesmoDia(d, dataAtual));
    final ultimo = aluno.ultimoContatoDate;

    return FxSheetFrame(
      title: _title,
      subtitle: _subtitle,
      leading: Icon(
        _isSleep ? Icons.bedtime_outlined : Icons.event_outlined,
        color: primary,
        size: 20,
      ),
      footer: FxLiquidPrimaryButton(
        label: _doneLabel,
        loading: _busy,
        onPressed: _busy ? null : () => _markDone(actions),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxSettingsGroup(
            children: [
              FxSettingsTile(
                icon: Icons.history_rounded,
                label: 'Último contato',
                value: ultimo == null ? 'Ainda não registrado' : _formatDate(ultimo),
                showDivider: true,
              ),
              FxSettingsTile(
                icon: Icons.event_available_outlined,
                label: _isSleep ? 'Combinado para' : 'Próximo contato',
                value: isSnoozed
                    ? 'Adiado até ${_formatDate(snoozedUntil)} ${_formatTime(snoozedUntil)}'
                    : (followUpDate == null
                          ? 'Sem data'
                          : _formatDate(followUpDate)),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s3),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, TokensStrip.s1),
            child: Semantics(
              header: true,
              child: Text(
                'Agendar',
                style: FocuxHubTypography.chip(fxScreenMute(context)),
              ),
            ),
          ),
          FxQuickChips<DateTime>(
            itens: atalhos,
            selecionado: dataAtual == null
                ? null
                : atalhos.where((d) => _mesmoDia(d, dataAtual)).firstOrNull,
            rotuloDe: _rotuloAtalho,
            outroSelecionado: dataAtual != null && !dataEhAtalho,
            outroRotulo: dataAtual != null && !dataEhAtalho
                ? _formatDate(dataAtual)
                : 'Escolher data',
            onSelecionar: (d) {
              if (!_busy) _definirAtalho(d);
            },
            onOutro: _busy ? null : _pickDate,
          ),
          const SizedBox(height: TokensStrip.s3),
          FxSettingsGroup(
            children: [
              FxSettingsTile(
                icon: Icons.snooze_rounded,
                label: 'Adiar',
                subtitle: 'Volta a avisar em 24 horas ou 3 dias',
                value: '',
                picker: true,
                showDivider: followUpDate != null || isSnoozed,
                onTap: _busy ? null : () => _showSnoozeSheet(actions),
              ),
              if (followUpDate != null || isSnoozed)
                FxSettingsTile(
                  icon: Icons.event_busy_rounded,
                  label: _isSleep ? 'Limpar combinação' : 'Limpar follow-up',
                  value: '',
                  danger: true,
                  showDivider: false,
                  onTap: _busy ? null : () => _confirmClear(actions),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
