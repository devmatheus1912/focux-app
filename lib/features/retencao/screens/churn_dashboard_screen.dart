import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
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
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/retencao_repository.dart';
import '../utils/retencao_display.dart';
import '../widgets/retencao_catalog_sheet.dart';

final retencaoRepositoryProvider = Provider(
  (ref) => RetencaoRepository(ref.read(apiClientProvider)),
);

class ChurnDashboardScreen extends ConsumerStatefulWidget {
  const ChurnDashboardScreen({super.key});

  @override
  ConsumerState<ChurnDashboardScreen> createState() =>
      _ChurnDashboardScreenState();
}

class _ChurnDashboardScreenState extends ConsumerState<ChurnDashboardScreen> {
  RetencaoHome? _home;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final home = await ref.read(retencaoRepositoryProvider).getHome();
      if (!mounted) return;
      setState(() {
        _home = home;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = friendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final home = _home;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(home?.fetchedAt);

    return fxScreenA11yScope(
      label: 'Saúde da base',
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Saúde da base',
          subtitle: freshnessLabel ?? 'Score de retenção por aluno',
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar a retenção',
              onTap:
                  () => showFxHelpSheet(
                    context,
                    title: 'Saúde da base',
                    subtitle: 'Quem está em risco e o que fazer agora.',
                    tips: const [
                      FxHelpTip('Como calculamos', retencaoComoCalculamos),
                      FxHelpTip(
                        'Risco alto',
                        'O card do topo é quem precisa de contato hoje.',
                      ),
                      FxHelpTip(
                        'Lista',
                        'Os 3 primeiros já vêm do servidor. Ver todos abre a base paginada.',
                      ),
                    ],
                  ),
            ),
          ],
        ),
        body:
            _loading
                ? const SkeletonList(count: 6)
                : _error != null
                ? FxErrorState(
                  chromeOnDark: isDark,
                  primary: primary,
                  message: _error!,
                  onRetry: _load,
                )
                : RefreshIndicator(
                  color: primary,
                  onRefresh: _load,
                  child:
                      home == null || home.isEmpty
                          ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 48),
                              FxEmptyState(
                                icon: 'activity',
                                title: 'Scores em breve',
                                subtitle:
                                    'A rotina calcula os scores aos domingos. '
                                    'Cadastre alunos e aguarde a primeira leitura.',
                                action: FxEmptyAction(
                                  label: 'Ver alunos',
                                  onTap: () {
                                    AnalyticsService.instance.track(
                                      ProductEvents.alunosViewed,
                                    );
                                    goPersonalShellTab(context, '/alunos');
                                  },
                                ),
                              ),
                            ],
                          )
                          : FxContentWidthLimiter(
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.fromLTRB(
                                TokensStrip.s4,
                                TokensStrip.s2,
                                TokensStrip.s4,
                                40,
                              ),
                              children: [
                                _RetencaoFocusCard(home: home, isDark: isDark),
                                const SizedBox(height: TokensStrip.s4),
                                DashboardSectionHeader(
                                  title: 'Quem olhar agora',
                                  actionLabel:
                                      home.alto + home.medio + home.saudavel > 3
                                          ? 'Ver todos'
                                          : null,
                                  onAction:
                                      home.alto + home.medio + home.saudavel > 3
                                          ? () {
                                            showRetencaoCatalogSheet(
                                              context,
                                              repo: ref.read(
                                                retencaoRepositoryProvider,
                                              ),
                                            );
                                          }
                                          : null,
                                ),
                                const SizedBox(height: TokensStrip.s2),
                                for (final score in home.top3)
                                  _RetencaoTile(score: score),
                              ],
                            ),
                          ),
                ),
      ),
    );
  }
}

class _RetencaoFocusCard extends StatelessWidget {
  const _RetencaoFocusCard({required this.home, required this.isDark});

  final RetencaoHome home;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final alto = home.alto;
    final firstAlto = firstAltoRetencao(home.top3);
    return FxStripCard(
      emphasize: true,
      semanticsLabel:
          alto == 0
              ? 'Nenhum aluno em risco alto'
              : '$alto em risco alto',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Risco alto', style: FocuxHubTypography.chip(chrome.mute)),
          const SizedBox(height: 6),
          Text(
            '$alto',
            style: FocuxHubTypography.kpi(
              color: chrome.ink,
              fontSize: FocuxHubTypography.metricLg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            alto == 0
                ? 'Ninguém em alerta agora'
                : alto == 1
                ? 'Aluno precisa de contato'
                : 'Alunos precisam de contato',
            style: FocuxHubTypography.body(
              color: chrome.ink,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '${home.medio} médios · ${home.saudavel} saudáveis',
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
          const SizedBox(height: TokensStrip.s3),
          Align(
            alignment: Alignment.centerLeft,
            child: DashboardHomeActionChip(
              label:
                  firstAlto == null ? 'Ver alunos' : 'Abrir o mais crítico',
              accent:
                  alto > 0
                      ? EagleTokens.bad
                      : Theme.of(context).colorScheme.primary,
              isDark: isDark,
              onPressed: () {
                final alvo = firstAlto;
                if (alvo == null) {
                  AnalyticsService.instance.track(ProductEvents.alunosViewed);
                  goPersonalShellTab(context, '/alunos');
                  return;
                }
                AnalyticsService.instance.track(
                  ProductEvents.alertaRiscoOpened,
                  props: {'alunoId': alvo.alunoId},
                );
                context.push('/alunos/${alvo.alunoId}');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RetencaoTile extends StatelessWidget {
  const _RetencaoTile({required this.score});

  final RetencaoAlunoScore score;

  @override
  Widget build(BuildContext context) {
    final alto = retencaoRiscoAlto(score.riscoChurn);
    return FxSatelliteListTile(
      title: score.alunoNome,
      subtitle: Text(
        'Score ${score.scoreAtual} · ${retencaoRiscoLabel(score.riscoChurn)}',
      ),
      accent: alto ? EagleTokens.bad : null,
      onTap: () => context.push('/alunos/${score.alunoId}'),
    );
  }
}
