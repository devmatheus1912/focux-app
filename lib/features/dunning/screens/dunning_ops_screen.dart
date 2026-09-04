import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/dunning_repository.dart';
import '../utils/dunning_ops_display.dart';
import '../widgets/dunning_catalog_sheet.dart';

final _repoProvider = Provider(
  (ref) => DunningRepository(ref.read(apiClientProvider)),
);

class DunningOpsScreen extends ConsumerStatefulWidget {
  const DunningOpsScreen({super.key});

  @override
  ConsumerState<DunningOpsScreen> createState() => _DunningOpsScreenState();
}

class _DunningOpsScreenState extends ConsumerState<DunningOpsScreen> {
  final _openedAt = DateTime.now();
  DunningSnapshot? _snapshot;
  List<DunningFalha> _falhas = [];
  var _hasMore = false;
  var _page = 0;
  var _loading = true;
  String? _erro;
  int? _marcandoId;
  DateTime? _fetchedAt;
  var _viewTracked = false;
  var _ttvTracked = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final home = await ref.read(_repoProvider).getHome();
      if (!mounted) return;
      setState(() {
        _snapshot = home.snapshot;
        _falhas = home.falhas;
        _hasMore = home.hasMore;
        _page = home.page;
        _fetchedAt = DateTime.now();
        _loading = false;
      });
      _trackViewIfNeeded();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = friendlyError(e);
      });
    }
  }

  void _abrirCatalogo() {
    final snap = _snapshot;
    if (snap == null) return;
    showDunningCatalogSheet(
      context,
      firstPage: DunningHomeBundle(
        snapshot: snap,
        falhas: _falhas,
        page: _page,
        hasMore: _hasMore,
      ),
      repo: ref.read(_repoProvider),
      onMarcar: _marcarRecuperado,
    );
  }

  void _trackViewIfNeeded() {
    if (_viewTracked) return;
    _viewTracked = true;
    AnalyticsService.instance.track(
      ProductEvents.dunningHubViewed,
      props: {'abertas': _snapshot?.abertas ?? 0},
    );
    if (!_ttvTracked) {
      _ttvTracked = true;
      AnalyticsService.instance.track(
        ProductEvents.dunningHubTtv,
        props: {
          'ms': DateTime.now().difference(_openedAt).inMilliseconds,
        },
      );
    }
  }

  void _abrirFinanceiro() {
    AnalyticsService.instance.track(ProductEvents.financeiroViewed);
    goPersonalShellTab(context, '/financeiro');
  }

  Future<bool> _marcarRecuperado(DunningFalha falha) async {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Marcar como recuperada?',
      subtitle: dunningFalhaTitulo(falha.alunoNome, falha.contexto),
      message: 'A falha some da lista. Use só se o pagamento já entrou.',
      confirmLabel: 'Marcar recuperada',
    );
    if (!ok || !mounted) return false;

    AnalyticsService.instance.track(
      ProductEvents.dunningMarkedRecovered,
      props: {
        'feature': 'dunning',
        'falha_id': falha.id,
      },
    );
    setState(() => _marcandoId = falha.id);
    try {
      await ref.read(_repoProvider).marcarRecuperado(falha.id);
      if (!mounted) return false;
      FeedbackHelper.showSuccess(context, 'Falha marcada como recuperada.');
      await _carregar();
      return true;
    } catch (e) {
      if (!mounted) return false;
      FeedbackHelper.showError(context, friendlyError(e));
      return false;
    } finally {
      if (mounted) setState(() => _marcandoId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final snap = _snapshot;
    final firstFalha = _falhas.isEmpty ? null : _falhas.first;
    final preview = dunningFalhasPreview(_falhas);

    return fxScreenA11yScope(
      label: 'Cobrança auto',
      child: FeatureGate(
        featureName: 'Cobrança automática',
        requiredPlan: SubscriptionPlan.PRO,
        capability: 'financeiro',
        child: FxShellScaffold(
          useMesh: true,
          constrainWidth: false,
          appBar: FxShellAppBar(
            title: 'Cobrança auto',
            subtitle: FxHubFreshness.fromFetchedAt(_fetchedAt),
            onBack: () => safePopOrGo(context, '/financeiro'),
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar a cobrança automática',
                onTap: () {
                  AnalyticsService.instance.track(
                    ProductEvents.dunningHubHelpOpened,
                  );
                  showFxHelpSheet(
                    context,
                    title: 'Cobrança auto',
                    subtitle:
                        'Falhas de pagamento da base. A taxa é a mesma da Receita recorrente.',
                    tips: const [
                      FxHelpTip('Como calculamos', dunningComoCalculamos),
                      FxHelpTip(
                        'Em aberto',
                        'Toque na falha para marcar recuperada quando o pagamento entrar.',
                      ),
                      FxHelpTip(
                        'Assinatura Focux',
                        'É a sua assinatura do app, não a mensalidade do aluno.',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          body: _loading
              ? const SkeletonList(count: 6)
              : _erro != null
              ? FxErrorState(
                chromeOnDark: isDark,
                primary: primary,
                message: _erro!,
                onRetry: _carregar,
              )
              : RefreshIndicator(
                color: primary,
                onRefresh: () async {
                  AnalyticsService.instance.track(
                    ProductEvents.dunningHubRefreshed,
                  );
                  await _carregar();
                },
                child: snap == null || (snap.abertas == 0 && _falhas.isEmpty)
                    ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 48),
                        FxEmptyState(
                          icon: 'circle-check',
                          title: 'Tudo em dia',
                          subtitle: 'Nenhuma falha de pagamento em aberto.',
                          action: FxEmptyAction(
                            label: 'Ver financeiro',
                            onTap: _abrirFinanceiro,
                          ),
                        ),
                      ],
                    )
                    : FxContentWidthLimiter(
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.all(TokensStrip.s4),
                        children: [
                          _DunningFocusCard(
                            snap: snap,
                            firstFalha: firstFalha,
                            isDark: isDark,
                            onMarcar: firstFalha == null
                                ? _abrirFinanceiro
                                : () => _marcarRecuperado(firstFalha),
                            onFinanceiro: _abrirFinanceiro,
                          ),
                          const SizedBox(height: TokensStrip.s4),
                          OperationalMetricTile(
                            label: 'Taxa',
                            value: dunningRateLabel(snap.recoveryRate),
                            hint: dunningTaxaFraca(
                              snap.recoveryRate,
                              snap.total,
                            )
                                ? 'Abaixo de metade das tentativas'
                                : 'Recuperação no recorte',
                            color: dunningTaxaFraca(
                              snap.recoveryRate,
                              snap.total,
                            )
                                ? EagleTokens.bad
                                : EagleTokens.moneyGreen,
                            isDark: isDark,
                            emphasis: dunningTaxaFraca(
                              snap.recoveryRate,
                              snap.total,
                            )
                                ? OperationalMetricEmphasis.alert
                                : OperationalMetricEmphasis.normal,
                          ),
                          const SizedBox(height: TokensStrip.s2),
                          OperationalMetricTile(
                            label: 'Recuperadas',
                            value: dunningRecuperadasLabel(
                              snap.recuperadas,
                              snap.total,
                            ),
                            hint: 'Já voltaram a pagar',
                            color: primary,
                            isDark: isDark,
                          ),
                          const SizedBox(height: TokensStrip.s4),
                          const DashboardSectionHeader(title: 'Em aberto'),
                          const SizedBox(height: TokensStrip.s2),
                          Text(
                            'Toque para marcar como recuperada.',
                            style: FocuxHubTypography.bodyMuted(
                              color: fxScreenMute(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: TokensStrip.s3),
                          if (_falhas.isEmpty)
                            const FxSatelliteListTile(
                              title: 'Nenhuma falha na lista',
                            )
                          else ...[
                            for (final falha in preview)
                              FxSatelliteListTile(
                                title: dunningFalhaTitulo(
                                  falha.alunoNome,
                                  falha.contexto,
                                ),
                                subtitle: Text(
                                  dunningFalhaSubtitle(
                                    contexto: falha.contexto,
                                    alunoNome: falha.alunoNome,
                                    motivo: falha.motivo,
                                    tentativa: falha.tentativa,
                                  ),
                                ),
                                trailing: Text(
                                  _marcandoId == falha.id
                                      ? '…'
                                      : dunningMoneyLabel(falha.valor),
                                  style: FocuxHubTypography.bodyMuted(
                                    color: EagleTokens.bad,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                accent: EagleTokens.bad,
                                onTap: _marcandoId == falha.id
                                    ? null
                                    : () => _marcarRecuperado(falha),
                              ),
                            if (_falhas.length > 3 || _hasMore)
                              FxSatelliteListTile(
                                title: 'Ver mais',
                                onTap: _abrirCatalogo,
                              ),
                          ],
                        ],
                      ),
                    ),
              ),
        ),
      ),
    );
  }
}

class _DunningFocusCard extends StatelessWidget {
  const _DunningFocusCard({
    required this.snap,
    required this.firstFalha,
    required this.isDark,
    required this.onMarcar,
    required this.onFinanceiro,
  });

  final DunningSnapshot snap;
  final DunningFalha? firstFalha;
  final bool isDark;
  final VoidCallback onMarcar;
  final VoidCallback onFinanceiro;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final abertas = snap.abertas;
    return FxStripCard(
      emphasize: true,
      semanticsLabel: '$abertas falhas em aberto',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Em aberto', style: FocuxHubTypography.chip(chrome.mute)),
          const SizedBox(height: 6),
          Text(
            '$abertas',
            style: FocuxHubTypography.kpi(
              color: chrome.ink,
              fontSize: FocuxHubTypography.metricLg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            abertas == 0
                ? 'Nenhuma falha em aberto'
                : 'Taxa ${dunningRateLabel(snap.recoveryRate)}',
            style: FocuxHubTypography.body(
              color: chrome.ink,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: TokensStrip.s3),
          Align(
            alignment: Alignment.centerLeft,
            child: DashboardHomeActionChip(
              label: firstFalha == null ? 'Ver financeiro' : 'Marcar primeira',
              accent: firstFalha == null
                  ? Theme.of(context).colorScheme.primary
                  : EagleTokens.bad,
              isDark: isDark,
              onPressed: firstFalha == null ? onFinanceiro : onMarcar,
            ),
          ),
        ],
      ),
    );
  }
}
