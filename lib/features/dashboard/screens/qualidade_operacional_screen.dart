import 'dart:async';

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
import '../../../core/utils/pt_br_display.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../data/qualidade_operacional.dart';
import '../utils/qualidade_operacional_display.dart';
import '../widgets/dashboard_home_action_chip.dart';
import '../widgets/dashboard_section_header.dart';

class QualidadeOperacionalScreen extends ConsumerStatefulWidget {
  const QualidadeOperacionalScreen({super.key});

  @override
  ConsumerState<QualidadeOperacionalScreen> createState() =>
      _QualidadeOperacionalScreenState();
}

class _QualidadeOperacionalScreenState
    extends ConsumerState<QualidadeOperacionalScreen> {
  final _openedAt = DateTime.now();
  DateTime? _fetchedAt;
  var _viewTracked = false;
  ProviderSubscription<AsyncValue<QualidadeOperacionalData>>? _freshnessSub;

  @override
  void initState() {
    super.initState();
    _freshnessSub = ref.listenManual(qualidadeProvider, (_, next) {
      if (!next.hasValue || next.isLoading || next.hasError) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _fetchedAt = DateTime.now());
        _trackViewIfNeeded(next.requireValue);
      });
    }, fireImmediately: true);
  }

  void _trackViewIfNeeded(QualidadeOperacionalData data) {
    if (_viewTracked) return;
    _viewTracked = true;
    unawaited(
      AnalyticsService.instance.track(
        ProductEvents.relatoriosHubViewed,
        props: {
          'surface': 'qualidade',
          'score': data.score,
        },
      ),
    );
    unawaited(
      AnalyticsService.instance.track(
        ProductEvents.relatoriosHubTtv,
        props: {
          'surface': 'qualidade',
          'ms': DateTime.now().difference(_openedAt).inMilliseconds,
        },
      ),
    );
  }

  @override
  void dispose() {
    _freshnessSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(qualidadeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: 'Qualidade operacional',
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Qualidade',
          subtitle: freshnessLabel,
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar Qualidade',
              onTap: () {
                unawaited(
                  AnalyticsService.instance.track(
                    ProductEvents.relatoriosHubHelpOpened,
                    props: {'surface': 'qualidade'},
                  ),
                );
                showFxHelpSheet(
                  context,
                  title: 'Qualidade',
                  subtitle: 'Como a operação se compara ao mercado.',
                  tips: const [
                    FxHelpTip('Como calculamos', qualidadeComoCalculamos),
                    FxHelpTip(
                      'Índice',
                      'O card do topo é o recorte do dia.',
                    ),
                    FxHelpTip(
                      'Ticket',
                      'Compare o seu ticket médio com o mercado.',
                    ),
                    FxHelpTip(
                      'Retenção',
                      'Se a base cair, abra Saúde da base.',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: asyncData.when(
          loading:
              () => ListView(
                padding: const EdgeInsets.all(TokensStrip.s4),
                children: [
                  FxLoading.sectionShimmer(context, height: 160),
                  const SizedBox(height: TokensStrip.s4),
                  FxLoading.sectionShimmer(context, height: 88),
                  const SizedBox(height: TokensStrip.s3),
                  FxLoading.sectionShimmer(context, height: 88),
                ],
              ),
          error:
              (e, _) => FxErrorState(
                chromeOnDark: isDark,
                primary: primary,
                message: friendlyError(e),
                onRetry: () => ref.invalidate(qualidadeProvider),
              ),
          data: (data) {
            Future<void> refresh() async {
              unawaited(
                AnalyticsService.instance.track(
                  ProductEvents.relatoriosHubRefreshed,
                  props: {'surface': 'qualidade'},
                ),
              );
              ref.invalidate(qualidadeProvider);
              await ref.read(qualidadeProvider.future);
            }

            if (data.isEmpty) {
              return RefreshIndicator(
                color: primary,
                onRefresh: refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 48),
                    FxEmptyState(
                      icon: 'bar-chart-2',
                      title: 'Sem dados ainda',
                      subtitle:
                          'Cadastre alunos e registre mensalidades para ver o índice da operação.',
                      action: FxEmptyAction(
                        label: 'Ver alunos',
                        onTap: () {
                          unawaited(
                            AnalyticsService.instance.track(
                              ProductEvents.alunosViewed,
                            ),
                          );
                          goPersonalShellTab(context, '/alunos');
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              color: primary,
              onRefresh: refresh,
              child: FxContentWidthLimiter(
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
                  children: [_QualidadeBody(data: data, isDark: isDark)],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QualidadeBody extends StatelessWidget {
  const _QualidadeBody({required this.data, required this.isDark});

  final QualidadeOperacionalData data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forBrightness(context, isDark);
    final next = qualidadeNextAction(data);
    final band = qualidadeScoreBand(data.score);
    final scoreColor = switch (band) {
      QualidadeScoreBand.excellent => EagleTokens.good,
      QualidadeScoreBand.good => EagleTokens.warn,
      QualidadeScoreBand.attention => EagleTokens.bad,
    };
    final ticketAbove = data.ticketPessoal >= data.ticketMercado;
    final retencaoAbove = data.retencaoPessoal >= data.retencaoMercado;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FxStripCard(
          emphasize: true,
          semanticsLabel:
              'Índice ${data.score} de 100. ${qualidadeScoreLabel(data.score)}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Índice Focux', style: FocuxHubTypography.chip(chrome.mute)),
              const SizedBox(height: 6),
              Text(
                '${data.score}',
                style: FocuxHubTypography.kpi(
                  color: chrome.ink,
                  fontSize: FocuxHubTypography.metricLg,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                qualidadeScoreLabel(data.score),
                style: FocuxHubTypography.body(
                  color: chrome.ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                qualidadeRecomendacaoDisplay(data),
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
              const SizedBox(height: TokensStrip.s3),
              Align(
                alignment: Alignment.centerLeft,
                child: DashboardHomeActionChip(
                  label: next.label,
                  accent: scoreColor,
                  isDark: isDark,
                  onPressed: () {
                    if (next.shellTab) {
                      goPersonalShellTab(context, next.route);
                    } else {
                      context.push(next.route);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: TokensStrip.s4),
        const DashboardSectionHeader(title: 'Comparado ao mercado'),
        const SizedBox(height: TokensStrip.s3),
        InkWell(
          onTap: () => context.push('/financeiro'),
          borderRadius: BorderRadius.circular(12),
          child: OperationalMetricTile(
            label: 'Ticket médio',
            value: formatBrlCurrency(data.ticketPessoal, showDecimals: false),
            hint:
                ticketAbove
                    ? 'Acima do mercado ${formatBrlCurrency(data.ticketMercado, showDecimals: false)}'
                    : 'Mercado ${formatBrlCurrency(data.ticketMercado, showDecimals: false)}',
            color: ticketAbove ? EagleTokens.good : EagleTokens.warn,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: TokensStrip.s2),
        InkWell(
          onTap: () => context.push('/retencao'),
          borderRadius: BorderRadius.circular(12),
          child: OperationalMetricTile(
            label: 'Retenção',
            value: '${data.retencaoPessoal}%',
            hint:
                retencaoAbove
                    ? 'Acima do mercado ${data.retencaoMercado}%'
                    : 'Mercado ${data.retencaoMercado}%',
            color: retencaoAbove ? EagleTokens.good : EagleTokens.warn,
            isDark: isDark,
            emphasis:
                retencaoAbove
                    ? OperationalMetricEmphasis.normal
                    : OperationalMetricEmphasis.alert,
          ),
        ),
      ],
    );
  }
}
