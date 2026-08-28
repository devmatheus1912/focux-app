import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_followup_provider.dart';
import '../utils/aluno360_a11y.dart';
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

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

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
      () => ref
          .read(alunoFollowUpActionsProvider)
          .setFollowUpDate(aluno.id, picked),
      'Follow-up definido para ${_formatDate(picked)}',
    );
  }

  Future<void> _showSnoozeSheet(dynamic actions) async {
    if (_busy) return;
    final sheetDark = Theme.of(context).brightness == Brightness.dark;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);

    await showFxHomeSheet<void>(
      context,
      builder: (ctx) {
        return FxHomeSheetSurface(
          isDark: sheetDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: sheetDark),
              const SizedBox(height: TokensStrip.s3),
              Text(
                'Adiar follow-up',
                textAlign: TextAlign.center,
                style: Aluno360Layout.sectionTitleStyle(ctx, ink),
              ),
              const SizedBox(height: TokensStrip.s1),
              Text(
                'Escolha por quanto tempo adiar o contato com ${aluno.nome}.',
                textAlign: TextAlign.center,
                style: Aluno360Layout.captionStyle(ctx).copyWith(
                  color: mute,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: TokensStrip.s4),
              FxSettingsTile(
                icon: Icons.snooze_rounded,
                label: 'Adiar 24 horas',
                value: '',
                showDivider: true,
                onTap: () {
                  Navigator.pop(ctx);
                  _runAction(
                    () => actions.snooze(aluno.id),
                    'Follow-up adiado por 24h',
                  );
                },
              ),
              FxSettingsTile(
                icon: Icons.date_range_rounded,
                label: 'Adiar 3 dias',
                value: '',
                showDivider: false,
                onTap: () {
                  Navigator.pop(ctx);
                  _runAction(
                    () => actions.snooze(
                      aluno.id,
                      duration: const Duration(days: 3),
                    ),
                    'Follow-up adiado por 3 dias',
                  );
                },
              ),
            ],
          ),
        );
      },
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
    if (compact) {
      return _compactFollowUpSubtitle(
        followUpDate: followUpDate,
        isSnoozed: isSnoozed,
        snoozedUntil: snoozedUntil,
      );
    }

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

  List<Widget> _buildFollowUpTiles({
    required Color primary,
    required DateTime? followUpDate,
    required bool isSnoozed,
    required DateTime? snoozedUntil,
    required dynamic actions,
    required bool highlightContactDone,
  }) {
    final busyValue = _busy ? '…' : '';
    final dateValue =
        followUpDate == null ? '' : _formatDate(followUpDate);
    final snoozeSubtitle =
        isSnoozed && snoozedUntil != null
            ? 'Adiado até ${_formatDate(snoozedUntil)}'
            : '24 horas ou 3 dias';

    return [
      FxSettingsTile(
        icon: Icons.check_rounded,
        label: 'Contato feito',
        subtitle: 'Registrar que falou com ${aluno.nome.split(' ').first}',
        value: busyValue,
        highlight: highlightContactDone,
        accent: primary,
        onTap: _busy ? () {} : () => _markContactDone(actions),
      ),
      FxSettingsTile(
        icon: Icons.calendar_month_rounded,
        label: 'Definir data',
        subtitle:
            followUpDate == null
                ? 'Agendar próximo contato'
                : 'Alterar data agendada',
        value: dateValue,
        onTap: _busy ? () {} : _pickFollowUpDate,
      ),
      FxSettingsTile(
        icon: Icons.snooze_rounded,
        label: 'Adiar',
        subtitle: snoozeSubtitle,
        value: '',
        showDivider: followUpDate == null && !isSnoozed,
        onTap: _busy ? () {} : () => _showSnoozeSheet(actions),
      ),
      if (followUpDate != null || isSnoozed)
        FxSettingsTile(
          icon: Icons.event_busy_rounded,
          label: 'Limpar follow-up',
          subtitle: 'Remove data e adiamento',
          value: '',
          danger: true,
          showDivider: false,
          onTap: _busy ? () {} : () => _confirmClearFollowUp(actions),
        ),
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
    final caption = _groupCaption(
      compact: compact,
      followUpDate: followUpDate,
      isSnoozed: isSnoozed,
      snoozedUntil: snoozedUntil,
    );

    return Semantics(
      container: true,
      label: aluno360FollowUpSemantics(subtitle: caption ?? ''),
      child: FxSettingsGroup(
        key:
            compact
                ? const ValueKey('aluno360_followup_compact')
                : const ValueKey('aluno360_follow_up'),
        header: compact ? 'Próximo contato' : 'Follow-up do personal',
        caption: caption,
        accent: primary,
        children: _buildFollowUpTiles(
          primary: primary,
          followUpDate: followUpDate,
          isSnoozed: isSnoozed,
          snoozedUntil: snoozedUntil,
          actions: actions,
          highlightContactDone: !compact,
        ),
      ),
    );
  }
}
