import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/dunning_repository.dart';
import '../utils/dunning_ops_display.dart';
import '../widgets/dunning_ops_help_sheet.dart';

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
  var _carregandoMais = false;
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

  Future<void> _carregarMais() async {
    if (_carregandoMais || !_hasMore) return;
    setState(() => _carregandoMais = true);
    try {
      final home = await ref.read(_repoProvider).getHome(page: _page + 1);
      if (!mounted) return;
      final seen = _falhas.map((f) => f.id).toSet();
      setState(() {
        _snapshot = home.snapshot;
        _falhas = [
          ..._falhas,
          ...home.falhas.where((f) => seen.add(f.id)),
        ];
        _hasMore = home.hasMore;
        _page = home.page;
        _carregandoMais = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregandoMais = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
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

  Future<void> _marcarRecuperado(DunningFalha falha) async {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Marcar como recuperada?',
      subtitle: dunningFalhaTitulo(falha.alunoNome, falha.contexto),
      message:
          'A falha some da lista. Use só se o pagamento já entrou.',
      confirmLabel: 'Marcar recuperada',
    );
    if (!ok || !mounted) return;

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
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Falha marcada como recuperada.');
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _marcandoId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final snap = _snapshot;

    return fxScreenA11yScope(
      label: 'Cobrança auto',
      child: FeatureGate(
        featureName: 'Cobrança automática',
        requiredPlan: SubscriptionPlan.PRO,
        capability: 'financeiro',
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Cobrança auto',
            subtitle: FxHubFreshness.fromFetchedAt(_fetchedAt),
            onBack: () => safePopOrGo(context, '/dashboard/personal'),
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar a cobrança automática',
                onTap: () {
                  AnalyticsService.instance.track(
                    ProductEvents.dunningHubHelpOpened,
                  );
                  showDunningOpsHelpSheet(context);
                },
              ),
            ],
          ),
          body: _loading
              ? const Padding(
                padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                child: SkeletonList(count: 6),
              )
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
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    8,
                    FxSettingsLayout.pageInset,
                    110,
                  ),
                  children: [
                    if (snap != null) ...[
                      const DashboardSectionHeader(title: 'Recuperação'),
                      const SizedBox(height: TokensStrip.s2),
                      Text(
                        'A taxa é a mesma da Receita recorrente.',
                        style: FocuxHubTypography.bodyMuted(
                          color: fxScreenMute(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: TokensStrip.s3),
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
                        label: 'Em aberto',
                        value: '${snap.abertas}',
                        hint: snap.abertas > 0
                            ? 'Toque na falha para marcar recuperada'
                            : 'Nenhuma falha em aberto',
                        color: snap.abertas > 0
                            ? EagleTokens.bad
                            : EagleTokens.moneyGreen,
                        isDark: isDark,
                        emphasis: snap.abertas > 0
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
                      const SizedBox(height: TokensStrip.s5),
                    ],
                    if (_falhas.isEmpty)
                      SizedBox(
                        height: 280,
                        child: FxEmptyState(
                          icon: 'circle-check',
                          title: 'Tudo em dia',
                          subtitle:
                              'Nenhuma falha de pagamento em aberto.',
                          action: FxEmptyAction(
                            label: 'Atualizar',
                            onTap: _carregar,
                          ),
                        ),
                      )
                    else ...[
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
                      for (final falha in _falhas)
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
                      if (_hasMore)
                        FxSatelliteListTile(
                          title: _carregandoMais
                              ? 'Carregando…'
                              : 'Carregar mais',
                          onTap: _carregandoMais ? null : _carregarMais,
                        ),
                    ],
                  ],
                ),
              ),
        ),
      ),
    );
  }
}
