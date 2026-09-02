import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_dock.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/command_center_data.dart';
import '../providers/dashboard_provider.dart';
import '../utils/copilot_actions_display.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
import 'package:focux_app/core/widgets/skeleton_loader.dart';

part 'copilot_actions_screen_widgets.part.dart';

final iaActionsProvider = FutureProvider.family<List<FilaAcaoResumo>, String>((
  ref,
  status,
) {
  return ref
      .read(dashboardRepositoryProvider)
      .getIaCommandActions(status: status);
});

class CopilotActionsScreen extends ConsumerStatefulWidget {
  const CopilotActionsScreen({super.key});

  @override
  ConsumerState<CopilotActionsScreen> createState() =>
      _CopilotActionsScreenState();
}

class _CopilotActionsScreenState extends ConsumerState<CopilotActionsScreen> {
  String _status = copilotActionsStatusAberto;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final brand = dark ? BrandPalette.accent(primary) : primary;
    final ink = dark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = dark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final actionsAsync = ref.watch(iaActionsProvider(_status));

    return fxScreenA11yScope(
      label: 'Tarefas IA',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Tarefas IA',
          subtitle: 'Centro de Comando',
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como funcionam as tarefas IA',
              onTap: _abrirAjuda,
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(
            TokensStrip.s4,
            0,
            TokensStrip.s4,
            14,
          ),
          child: SafeArea(
            top: false,
            child: FxDock(
              items: FxDockItems.personal,
              currentIndex: 4,
              isDark: dark,
              onTap: (index) {
                final path = switch (index) {
                  0 => '/dashboard/personal',
                  1 => '/alunos',
                  2 => '/treinos',
                  3 => '/agenda',
                  _ => '/ia/copiloto',
                };
                context.go(path);
              },
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                2,
                FxSettingsLayout.pageInset,
                TokensStrip.s2,
              ),
              child: FxSettingsGroup(
                children: [
                  FxSettingsTile(
                    fxIcon: 'spark',
                    label: copilotActionsFiltroTitle(),
                    value: copilotActionsStatusLabel(_status),
                    picker: true,
                    accent: brand,
                    mute: mute,
                    showDivider: false,
                    onTap: _abrirFiltro,
                  ),
                ],
              ),
            ),
            Expanded(
              child: actionsAsync.when(
                loading: () => const SkeletonList(count: 6),
                error:
                    (e, _) => FxErrorState(
                      chromeOnDark: dark,
                      primary: brand,
                      message: friendlyError(e),
                      onRetry: _refresh,
                    ),
                data: (actions) {
                  final copilot =
                      actions
                          .where((action) => action.tipo == 'IA_COPILOTO')
                          .toList();
                  final radar =
                      actions
                          .where((action) => action.tipo != 'IA_COPILOTO')
                          .toList();

                  if (actions.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          FxSettingsLayout.pageInset,
                          TokensStrip.s4,
                          FxSettingsLayout.pageInset,
                          120,
                        ),
                        children: [
                          FxEmptyState(
                            icon: 'circle-check',
                            title: copilotActionsEmptyTitle(_status),
                            subtitle: copilotActionsEmptySubtitle(_status),
                            action: FxEmptyAction(
                              label: copilotActionsAtualizarLabel(),
                              onTap: _refresh,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        FxSettingsLayout.pageInset,
                        10,
                        FxSettingsLayout.pageInset,
                        120,
                      ),
                      children: [
                        if (copilot.isNotEmpty) ...[
                          _SectionHeader(
                            title: 'Copiloto',
                            detail: copilotActionsSectionDetail(
                              _status,
                              copilot.length,
                            ),
                            ink: ink,
                            mute: mute,
                          ),
                          const SizedBox(height: 8),
                          for (final entry in copilot.asMap().entries) ...[
                            _CopilotTaskCard(
                              action: entry.value,
                              status: _status,
                              highlighted:
                                  _status == copilotActionsStatusAberto &&
                                  entry.key == 0,
                              ink: ink,
                              mute: mute,
                              brand: brand,
                              onOpen: () => _openAction(context, entry.value),
                              onComplete: () => _complete(entry.value),
                              onSnooze: () => _snooze(entry.value),
                              onReopen: () => _reopen(entry.value),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                        if (radar.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _SectionHeader(
                            title: 'Sinais automáticos',
                            detail: '${radar.length} sinais',
                            ink: ink,
                            mute: mute,
                          ),
                          const SizedBox(height: 8),
                          for (final action in radar) ...[
                            _RadarSignalCard(
                              action: action,
                              status: _status,
                              ink: ink,
                              mute: mute,
                              brand: brand,
                              onOpen: () => _openAction(context, action),
                              onComplete: () => _complete(action),
                              onSnooze: () => _snooze(action),
                              onReopen: () => _reopen(action),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirFiltro() async {
    final picked = await showFxInsetPickerSheet<String>(
      context,
      title: copilotActionsFiltroTitle(),
      selected: _status,
      items: [
        for (final status in copilotActionsStatusValues)
          FxInsetPickerSheetItem(
            value: status,
            label: copilotActionsStatusLabel(status),
          ),
      ],
    );
    if (!mounted || picked == null || picked == _status) return;
    setState(() => _status = picked);
  }

  void _abrirAjuda() {
    showFxHelpSheet(
      context,
      title: copilotActionsHelpTitle(),
      subtitle: copilotActionsHelpSubtitle(),
      tips: const [
        FxHelpTip(
          'Copiloto',
          'Tarefas que você salvou a partir de um insight. Revisar o aluno não conclui a tarefa.',
        ),
        FxHelpTip(
          'Sinais',
          'Alertas automáticos do Radar. Concluir, adiar ou reabrir pede confirmação.',
        ),
      ],
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(iaActionsProvider(_status));
    await ref.read(iaActionsProvider(_status).future);
  }

  void _openAction(BuildContext context, FilaAcaoResumo action) {
    if (action.acaoUrl.startsWith('/')) {
      context.push(action.acaoUrl);
    }
  }

  Future<void> _complete(FilaAcaoResumo action) async {
    final ok = await showFxConfirmSheet(
      context,
      title: copilotActionsCompleteConfirmTitle(),
      message: copilotActionsCompleteConfirmMessage(),
      confirmLabel: copilotActionsConcluirLabel(),
    );
    if (!ok || !mounted) return;
    await _runAction(
      () => ref
          .read(dashboardRepositoryProvider)
          .completeCommandAction(action.actionKey),
      'Tarefa concluída',
    );
  }

  Future<void> _snooze(FilaAcaoResumo action) async {
    final ok = await showFxConfirmSheet(
      context,
      title: copilotActionsSnoozeConfirmTitle(),
      message: copilotActionsSnoozeConfirmMessage(),
      confirmLabel: copilotActionsAdiarLabel(),
    );
    if (!ok || !mounted) return;
    await _runAction(
      () => ref
          .read(dashboardRepositoryProvider)
          .snoozeCommandAction(action.actionKey, hours: 24),
      'Tarefa adiada por 24h',
    );
  }

  Future<void> _reopen(FilaAcaoResumo action) async {
    final ok = await showFxConfirmSheet(
      context,
      title: copilotActionsReopenConfirmTitle(),
      message: copilotActionsReopenConfirmMessage(),
      confirmLabel: copilotActionsReabrirLabel(),
    );
    if (!ok || !mounted) return;
    await _runAction(
      () => ref
          .read(dashboardRepositoryProvider)
          .reopenCommandAction(action.actionKey),
      'Tarefa reaberta',
    );
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (!mounted) return;
      ref.invalidate(iaActionsProvider(_status));
      ref.invalidate(dashboardHomeProvider);
      ref.invalidate(commandCenterProvider);
      FeedbackHelper.showInfo(context, successMessage);
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        friendlyError(e, fallback: 'Não foi possível atualizar a tarefa.'),
      );
    }
  }
}
