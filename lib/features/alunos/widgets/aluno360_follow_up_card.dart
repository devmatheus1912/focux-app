import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_followup_provider.dart';
import '../utils/aluno360_operacao_logic.dart';

class Aluno360FollowUpCard extends ConsumerStatefulWidget {
  const Aluno360FollowUpCard({
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Limpar follow-up?'),
            content: Text(
              'Remove a data de próximo contato de ${aluno.nome}. '
              'Você pode definir outra data depois.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Limpar'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    await _runAction(
      () => actions.clearFollowUp(aluno.id),
      'Follow-up limpo',
    );
  }

  Widget _snoozeMenuButton({
    required BuildContext context,
    required Color primary,
    required dynamic actions,
    required bool fullWidth,
  }) {
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          onPressed:
              _busy
                  ? null
                  : () => _runAction(
                    () => actions.snooze(aluno.id),
                    'Follow-up adiado por 24h',
                  ),
          child: const Text('Adiar 24h'),
        ),
        MenuItemButton(
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
          child: const Text('Adiar 3 dias'),
        ),
      ],
      builder: (context, controller, _) {
        final button = OutlinedButton.icon(
          onPressed: _busy ? null : controller.open,
          icon: const Icon(Icons.snooze_rounded, size: 16),
          label: const Text('Adiar'),
          style: Aluno360Layout.operacaoOutlinedButtonStyle(context, primary),
        );
        return Semantics(
          label: 'Adiar follow-up de ${aluno.nome}',
          button: true,
          child: fullWidth ? SizedBox(width: double.infinity, child: button) : button,
        );
      },
    );
  }

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
          reserveBottom: Aluno360Layout.snackbarStickyReserve,
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

  BoxDecoration _compactFollowUpDecoration({
    required BuildContext context,
    required Color primary,
    required bool isDark,
  }) {
    return Aluno360Layout.operacaoInsetSectionDecoration(
      context,
      primary: primary,
      isDark: isDark,
    );
  }

  Widget _buildCompactContactPriorityCard({
    required BuildContext context,
    required Color primary,
    required Color ink,
    required DateTime? followUpDate,
    required bool isSnoozed,
    required DateTime? snoozedUntil,
    required dynamic actions,
  }) {
    final mute = fxScreenMute(context);
    final isDark = widget.isDark;
    final subtitle = _compactFollowUpSubtitle(
      followUpDate: followUpDate,
      isSnoozed: isSnoozed,
      snoozedUntil: snoozedUntil,
    );
    final motionMs =
        reduceMotionOf(context)
            ? 0
            : 220;

    return DecoratedBox(
      key: const ValueKey('aluno360_followup_compact'),
      decoration: _compactFollowUpDecoration(
        context: context,
        primary: primary,
        isDark: isDark,
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              label:
                  'Próximo contato. $subtitle. '
                  '${_expanded ? 'Recolher' : 'Expandir'} opções de follow-up',
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom: Radius.circular(_expanded ? 0 : 16),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: BrandPalette.soft(primary, dark: isDark),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.event_available_rounded,
                          size: 18,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Próximo contato',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Aluno360Layout.captionStyle(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.04),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 20,
                          color: mute,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: Duration(milliseconds: motionMs),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child:
                  _expanded
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: mute.withValues(alpha: isDark ? 0.14 : 0.12),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                            child: _buildFollowUpActions(
                              context,
                              primary: primary,
                              ink: ink,
                              followUpDate: followUpDate,
                              isSnoozed: isSnoozed,
                              snoozedUntil: snoozedUntil,
                              actions: actions,
                              contactPrimaryOutlined: true,
                            ),
                          ),
                        ],
                      )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
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
      return _buildCompactContactPriorityCard(
        context: context,
        primary: primary,
        ink: ink,
        followUpDate: followUpDate,
        isSnoozed: isSnoozed,
        snoozedUntil: snoozedUntil,
        actions: actions,
      );
    }

    return Container(
      key: const ValueKey('aluno360_follow_up'),
      decoration: Aluno360Layout.operacaoInsetSectionDecoration(
        context,
        primary: primary,
        isDark: widget.isDark,
      ),
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
              final filledStyle = Aluno360Layout.operacaoFilledButtonStyle(
                context,
                primary,
              );
              final outlinedStyle = Aluno360Layout.operacaoOutlinedButtonStyle(
                context,
                primary,
              );
              Widget contactDoneButton({required bool fullWidth}) {
                final loadingIcon = SizedBox(
                  width: 16,
                  height: 16,
                  child: FxLoading(
                    size: 16,
                    strokeWidth: 2,
                    color: contactPrimaryOutlined ? primary : Colors.white,
                  ),
                );
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
                            icon: _busy ? loadingIcon : const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Contato feito'),
                            style: outlinedStyle,
                          )
                          : FilledButton.icon(
                            onPressed:
                                _busy
                                    ? null
                                    : () => _runAction(
                                      () => actions.markContactDone(aluno.id),
                                      'Contato salvo · follow-up atualizado',
                                    ),
                            icon: _busy ? loadingIcon : const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Contato feito'),
                            style: filledStyle,
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
                    style: outlinedStyle,
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
                    _snoozeMenuButton(
                      context: context,
                      primary: primary,
                      actions: actions,
                      fullWidth: true,
                    ),
                    if (followUpDate != null || isSnoozed)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed:
                              _busy ? null : () => _confirmClearFollowUp(actions),
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
                        child: _snoozeMenuButton(
                          context: context,
                          primary: primary,
                          actions: actions,
                          fullWidth: false,
                        ),
                      ),
                    ],
                  ),
                  if (followUpDate != null || isSnoozed)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed:
                            _busy ? null : () => _confirmClearFollowUp(actions),
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
