import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/coach_proativo_repository.dart';
import '../widgets/coach_proativo_card.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  DateTime? _fetchedAt;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final mensagens = ref.watch(coachMensagensProvider);
    ref.listen(coachMensagensProvider, (_, next) {
      if (!next.hasValue || next.isLoading) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _fetchedAt = DateTime.now());
      });
    });

    return fxScreenA11yScope(
      label: 'Coach proativo',
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Coach',
          subtitle:
              FxHubFreshness.fromFetchedAt(_fetchedAt) ??
              'Orientações automáticas',
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar o coach',
              onTap:
                  () => showFxHelpSheet(
                    context,
                    title: 'Coach',
                    subtitle: 'O que merece atenção agora.',
                    tips: const [
                      FxHelpTip(
                        'Pendente',
                        'O card do topo é a próxima orientação.',
                      ),
                      FxHelpTip(
                        'Entendi',
                        'Marca a mensagem como lida sem apagar o histórico.',
                      ),
                    ],
                  ),
            ),
          ],
        ),
        body: mensagens.when(
          loading:
              () => const Padding(
                padding: EdgeInsets.all(TokensStrip.s4),
                child: SkeletonList(count: 3),
              ),
          error:
              (e, _) => FxErrorState(
                chromeOnDark: isDark,
                primary: primary,
                message: friendlyError(e),
                onRetry: () => ref.invalidate(coachMensagensProvider),
              ),
          data: (msgs) {
            if (msgs.isEmpty) {
              return FxEmptyState(
                icon: 'spark',
                title: 'Nenhuma orientação agora',
                subtitle:
                    'O coach avisa aqui quando encontrar algo que merece sua atenção.',
                action: FxEmptyAction(
                  label: 'Ir para o Hoje',
                  onTap:
                      () => goPersonalShellTab(context, '/dashboard/personal'),
                ),
              );
            }
            final unread = msgs.where((m) => !m.lido).toList(growable: false);
            final focus = unread.isNotEmpty ? unread.first : msgs.first;
            return RefreshIndicator(
              color: primary,
              onRefresh: () async {
                ref.invalidate(coachMensagensProvider);
                await ref.read(coachMensagensProvider.future);
              },
              child: FxContentWidthLimiter(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(TokensStrip.s4),
                  children: [
                    _CoachFocusCard(
                      focus: focus,
                      pending: unread.length,
                      isDark: isDark,
                      onAck: () async {
                        await CoachProativoRepository(
                          ref.read(apiClientProvider),
                        ).marcarLido(focus.id);
                        ref.invalidate(coachMensagensProvider);
                        ref.invalidate(alunoDashboardHomeProvider);
                      },
                    ),
                    const SizedBox(height: TokensStrip.s4),
                    const DashboardSectionHeader(title: 'Fila'),
                    const SizedBox(height: TokensStrip.s2),
                    CoachProativoCard(isDark: isDark, mensagens: msgs),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CoachFocusCard extends StatelessWidget {
  const _CoachFocusCard({
    required this.focus,
    required this.pending,
    required this.isDark,
    required this.onAck,
  });

  final CoachMensagem focus;
  final int pending;
  final bool isDark;
  final VoidCallback onAck;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    return FxStripCard(
      emphasize: true,
      semanticsLabel: 'Próxima orientação. $pending pendentes.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pending == 0 ? 'Em dia' : 'Pendente',
            style: FocuxHubTypography.chip(chrome.mute),
          ),
          const SizedBox(height: 6),
          Text(
            '$pending',
            style: FocuxHubTypography.kpi(
              color: chrome.ink,
              fontSize: FocuxHubTypography.metricLg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            focus.mensagem,
            style: FocuxHubTypography.body(
              color: chrome.ink,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: TokensStrip.s3),
          Align(
            alignment: Alignment.centerLeft,
            child: DashboardHomeActionChip(
              label: 'Entendi',
              accent: Theme.of(context).colorScheme.primary,
              isDark: isDark,
              onPressed: onAck,
            ),
          ),
        ],
      ),
    );
  }
}
