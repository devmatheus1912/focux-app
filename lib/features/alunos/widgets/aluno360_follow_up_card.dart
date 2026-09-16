import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_followup_provider.dart';
import '../utils/aluno360_a11y.dart';
import '../utils/aluno360_followup_dates.dart';
import '../utils/aluno360_operacao_logic.dart';

class Aluno360FollowUpCard extends ConsumerStatefulWidget {
  const Aluno360FollowUpCard({
    super.key,
    required this.aluno,
    required this.isDark,
    this.compactContactPriority = false,
  });

  final Aluno aluno;
  final bool isDark;
  final bool compactContactPriority;

  @override
  ConsumerState<Aluno360FollowUpCard> createState() =>
      _Aluno360FollowUpCardState();
}

class _Aluno360FollowUpCardState extends ConsumerState<Aluno360FollowUpCard> {
  bool _busy = false;
  bool _expanded = false;

  Aluno get aluno => widget.aluno;

  Future<void> _confirmClearFollowUp(dynamic actions) async {
    if (_busy) return;
    final confirmed = await showFxConfirmSheet(
      context,
      title: 'Limpar follow-up?',
      message:
          'Remove a data de próximo contato de ${aluno.nome}. '
          'Você pode definir outra data depois.',
      icon: Icons.event_busy_rounded,
      confirmLabel: 'Limpar',
    );
    if (!confirmed) return;
    await _runAction(() => actions.clearFollowUp(aluno.id), 'Follow-up limpo');
  }

  String _formatDate(DateTime date) => alunoFollowUpDateLabel(date);

  String _formatTime(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage, {
    VoidCallback? onSuccess,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        onSuccess?.call();
        if (successMessage.isNotEmpty) {
          FeedbackHelper.showOperacaoSuccess(context, successMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showOperacaoError(
          context,
          friendlyError(e, fallback: 'Não foi possível salvar o follow-up.'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markContactDone(dynamic actions) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = await actions.markContactDone(aluno.id);
      if (!mounted) return;
      final when = updated.ultimoContatoDate;
      final msg =
          when == null
              ? 'Contato registrado'
              : 'Contato registrado em ${_formatDate(when)}';
      if (widget.compactContactPriority) {
        setState(() => _expanded = false);
      }
      FeedbackHelper.showOperacaoSuccess(context, msg);
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showOperacaoError(
        context,
        friendlyError(e, fallback: 'Não foi possível salvar o follow-up.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFollowUpDate() async {
    if (_busy) return;
    final options = alunoFollowUpDateOptions(DateTime.now());
    final picked = await showFxInsetPickerSheet<DateTime>(
      context,
      title: 'Próximo contato',
      subtitle: 'Quando você fala de novo com ${aluno.nome}.',
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
      'Follow-up definido para ${_formatDate(picked)}',
    );
  }

  Future<void> _showSnoozeSheet(dynamic actions) async {
    if (_busy) return;
    final picked = await showFxInsetPickerSheet<Duration>(
      context,
      title: 'Adiar follow-up',
      subtitle: 'Escolha por quanto tempo adiar o contato com ${aluno.nome}.',
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
        'Follow-up adiado por 3 dias',
      );
      return;
    }
    await _runAction(
      () => actions.snooze(aluno.id),
      'Follow-up adiado por 24h',
    );
  }

  String _compactFollowUpSubtitle({
    required DateTime? followUpDate,
    required bool isSnoozed,
    required DateTime? snoozedUntil,
  }) {
    return alunoFollowUpCompactSubtitle(
      alunoNome: aluno.nome,
      followUpDate: followUpDate,
      isSnoozed: isSnoozed,
      snoozedUntil: snoozedUntil,
      formatDate: _formatDate,
    );
  }

  String? _groupCaption({
    required bool compact,
    required DateTime? followUpDate,
    required bool isSnoozed,
    required DateTime? snoozedUntil,
  }) {
    if (compact) return null;

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
    } else {
      parts.add('Agendar próximo contato · sincronizado com a nuvem');
    }
    return parts.join(' · ');
  }

  /// Hierarquia: 1 primária sólida (Contato feito) + secundárias outlined.
  List<Widget> _buildFollowUpChips({
    required Color primary,
    required DateTime? followUpDate,
    required bool isSnoozed,
    required dynamic actions,
  }) {
    Widget secondary(String label, VoidCallback onPressed) {
      return OutlinedButton(
        style: Aluno360Layout.operacaoOutlinedButtonStyle(context, primary),
        onPressed: _busy ? null : onPressed,
        child: Text(label),
      );
    }

    return [
      DashboardHomeActionChip(
        label: 'Contato feito',
        accent: primary,
        isDark: widget.isDark,
        enabled: !_busy,
        onPressed: () => _markContactDone(actions),
      ),
      secondary(
        followUpDate == null
            ? 'Definir data'
            : 'Data ${_formatDate(followUpDate)}',
        _pickFollowUpDate,
      ),
      secondary('Adiar', () => _showSnoozeSheet(actions)),
      if (followUpDate != null || isSnoozed)
        secondary('Limpar', () => _confirmClearFollowUp(actions)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final followUpDate = aluno.followUpDate;
    final snoozedUntil = aluno.snoozedUntilDate;
    final isSnoozed =
        snoozedUntil != null && snoozedUntil.isAfter(DateTime.now());
    final actions = ref.read(alunoFollowUpActionsProvider);
    final compact = widget.compactContactPriority;
    final motionMs = fxMotionDurationMs(context);
    final summarySubtitle = _compactFollowUpSubtitle(
      followUpDate: followUpDate,
      isSnoozed: isSnoozed,
      snoozedUntil: snoozedUntil,
    );
    final caption = _groupCaption(
      compact: compact,
      followUpDate: followUpDate,
      isSnoozed: isSnoozed,
      snoozedUntil: snoozedUntil,
    );
    final showActions = !compact || _expanded;
    final chips = _buildFollowUpChips(
      primary: primary,
      followUpDate: followUpDate,
      isSnoozed: isSnoozed,
      actions: actions,
    );

    return Semantics(
      container: true,
      label: aluno360FollowUpSemantics(
        subtitle: compact ? summarySubtitle : (caption ?? ''),
        expanded: compact && _expanded,
      ),
      child: Column(
        key:
            compact
                ? const ValueKey('aluno360_followup_compact')
                : const ValueKey('aluno360_follow_up'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(
            title: compact ? 'Próximo contato' : 'Follow-up do personal',
          ),
          if (caption != null && caption.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              caption,
              style: Aluno360Layout.metaStyle(context).copyWith(
                color: fxScreenMute(context),
              ),
            ),
          ],
          const SizedBox(height: TokensStrip.s3),
          if (compact)
            Align(
              alignment: Alignment.centerLeft,
              child: DashboardHomeActionChip(
                label: 'Registrar ou agendar',
                accent: primary,
                isDark: widget.isDark,
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
            ),
          AnimatedSize(
            duration: Duration(milliseconds: motionMs),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child:
                showActions
                    ? Padding(
                      padding: EdgeInsets.only(top: compact ? TokensStrip.s2 : 0),
                      child: Wrap(
                        spacing: TokensStrip.s2,
                        runSpacing: TokensStrip.s2,
                        children: chips,
                      ),
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
