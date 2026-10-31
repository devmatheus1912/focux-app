import 'dart:async';
import 'dart:math' as math;

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
import '../../../core/widgets/fx_action_row.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../data/qualidade_operacional.dart';
import '../utils/qualidade_operacional_display.dart';
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
                  subtitle: 'Como sua operação se compara à referência Focux.',
                  tips: const [
                    FxHelpTip('Como calculamos', qualidadeComoCalculamos),
                    FxHelpTip(
                      'Índice',
                      'Calculado na hora, com seus alunos e mensalidades.',
                    ),
                    FxHelpTip(
                      'Ticket',
                      'Valor médio das suas mensalidades.',
                    ),
                    FxHelpTip(
                      'Retenção',
                      'Se a base cair, abra Alunos em risco.',
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
                    TokensStrip.s6,
                  ),
                  children: [
                    _QualidadeBody(
                      data: data,
                      alunosAtivos:
                          ref.watch(planoFeaturesProvider).value?.alunosAtivos,
                    ),
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

class _QualidadeBody extends StatelessWidget {
  const _QualidadeBody({required this.data, required this.alunosAtivos});

  final QualidadeOperacionalData data;
  final int? alunosAtivos;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final basePequena = qualidadeBasePequena(alunosAtivos);
    final corIndice = switch (qualidadeScoreBand(data.score)) {
      _ when basePequena => chrome.mute,
      QualidadeScoreBand.excellent => EagleTokens.good,
      QualidadeScoreBand.good => EagleTokens.warn,
      QualidadeScoreBand.attention => EagleTokens.bad,
    };
    final ticketUnavailable = qualidadeTicketUnavailable(data.ticketPessoal);
    final ticketHint = qualidadeTicketHint(
      ticketPessoal: data.ticketPessoal,
      ticketMercado: data.ticketMercado,
    );
    final retencaoHint = qualidadeRetencaoHint(
      retencaoPessoal: data.retencaoPessoal,
      retencaoMercado: data.retencaoMercado,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FxStripCard(
          emphasize: true,
          semanticsLabel:
              'Índice ${data.score} de 100. ${qualidadeScoreLabel(data.score)}',
          child: Row(
            children: [
              SizedBox.square(
                dimension: 88,
                child: CustomPaint(
                  painter: _AnelPainter(
                    fracao: data.score / 100,
                    cor: corIndice,
                    fundo: chrome.line,
                  ),
                  child: Center(
                    child: Text(
                      '${data.score}',
                      style: FocuxHubTypography.metric(
                        color: chrome.ink,
                        fontSize: FocuxHubTypography.metricLg,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: TokensStrip.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Índice Focux',
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      basePequena
                          ? 'Poucos alunos para medir bem'
                          : qualidadeScoreLabel(data.score),
                      style: FocuxHubTypography.cardTitle(color: chrome.ink),
                    ),
                    const SizedBox(height: TokensStrip.s1),
                    Text(
                      qualidadeRecomendacaoDisplay(data),
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: TokensStrip.s4),
        const DashboardSectionHeader(title: 'Referência Focux'),
        const SizedBox(height: TokensStrip.s2),
        Container(
          padding: const EdgeInsets.all(TokensStrip.s3),
          decoration: fxListCardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LinhaReferencia(
                rotulo: 'Ticket médio',
                valor: qualidadeTicketValueLabel(data.ticketPessoal),
                apoio: ticketHint,
                fracao:
                    ticketUnavailable || data.ticketMercado <= 0
                        ? 0
                        : data.ticketPessoal / data.ticketMercado,
              ),
              const SizedBox(height: TokensStrip.s3),
              _LinhaReferencia(
                rotulo: 'Alunos que ficaram',
                valor: '${data.retencaoPessoal}%',
                apoio: retencaoHint,
                fracao:
                    data.retencaoMercado <= 0
                        ? 0
                        : data.retencaoPessoal / data.retencaoMercado,
              ),
            ],
          ),
        ),
        const SizedBox(height: TokensStrip.s3),
        FxActionRow(
          titulo: 'Revisar mensalidades',
          motivo: ticketHint,
          verbo: 'Abrir',
          onTap: () => context.push('/financeiro'),
        ),
        const SizedBox(height: TokensStrip.s2),
        FxActionRow(
          titulo: 'Ver alunos em risco',
          motivo: retencaoHint,
          verbo: 'Abrir',
          onTap: () => context.push('/retencao'),
        ),
      ],
    );
  }
}

/// Barra cheia = bateu a referência.
class _LinhaReferencia extends StatelessWidget {
  const _LinhaReferencia({
    required this.rotulo,
    required this.valor,
    required this.apoio,
    required this.fracao,
  });

  final String rotulo;
  final String valor;
  final String apoio;
  final double fracao;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: '$rotulo, $valor. $apoio',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rotulo,
                  style: FocuxHubTypography.body(color: chrome.ink),
                ),
              ),
              Text(
                valor,
                style: FocuxHubTypography.metric(
                  color: chrome.ink,
                  fontSize: FocuxHubTypography.metricEm,
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s1),
          ClipRRect(
            borderRadius: BorderRadius.circular(TokensStrip.s1),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: fracao.clamp(0.0, 1.0),
              color: primary,
              backgroundColor: primary.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: TokensStrip.s1),
          Text(apoio, style: FocuxHubTypography.bodyMuted(color: chrome.mute)),
        ],
      ),
    );
  }
}

class _AnelPainter extends CustomPainter {
  const _AnelPainter({
    required this.fracao,
    required this.cor,
    required this.fundo,
  });

  final double fracao;
  final Color cor;
  final Color fundo;

  @override
  void paint(Canvas canvas, Size size) {
    const espessura = 8.0;
    final area = (Offset.zero & size).deflate(espessura / 2);
    final traco =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = espessura
          ..strokeCap = StrokeCap.round;
    canvas.drawArc(area, 0, 2 * math.pi, false, traco..color = fundo);
    canvas.drawArc(
      area,
      -math.pi / 2,
      2 * math.pi * fracao.clamp(0.0, 1.0),
      false,
      traco..color = cor,
    );
  }

  @override
  bool shouldRepaint(_AnelPainter old) =>
      old.fracao != fracao || old.cor != cor || old.fundo != fundo;
}
