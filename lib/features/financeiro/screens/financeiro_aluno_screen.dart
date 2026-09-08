import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/money/fx_money.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/alunos/utils/satellite_screen_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../data/financeiro_repository.dart';
import '../utils/financeiro_hub_display.dart';
import '../widgets/financeiro_aluno_cobranca_sheet.dart';
import '../widgets/financeiro_aluno_help_sheet.dart';

class FinanceiroAlunoScreen extends ConsumerStatefulWidget {
  const FinanceiroAlunoScreen({super.key});

  @override
  ConsumerState<FinanceiroAlunoScreen> createState() =>
      _FinanceiroAlunoScreenState();
}

class _FinanceiroAlunoScreenState extends ConsumerState<FinanceiroAlunoScreen> {
  List<Mensalidade> _mensalidades = [];
  var _page = 0;
  var _hasMore = false;
  var _loading = true;
  var _carregandoMais = false;
  String? _erro;
  DateTime? _fetchedAt;

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
      final result =
          await FinanceiroRepository(
            ref.read(apiClientProvider),
          ).minhasMensalidades();
      if (!mounted) return;
      setState(() {
        _mensalidades = result.mensalidades;
        _page = result.page;
        _hasMore = result.hasMore;
        _fetchedAt = DateTime.now();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _carregarMais() async {
    if (_carregandoMais || !_hasMore) return;
    setState(() => _carregandoMais = true);
    try {
      final next = await FinanceiroRepository(
        ref.read(apiClientProvider),
      ).minhasMensalidades(page: _page + 1);
      if (!mounted) return;
      final seen = _mensalidades.map((m) => m.id).toSet();
      setState(() {
        _mensalidades = [
          ..._mensalidades,
          ...next.mensalidades.where((m) => seen.add(m.id)),
        ];
        _page = next.page;
        _hasMore = next.hasMore;
        _carregandoMais = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregandoMais = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  List<Mensalidade> get _abertas =>
      _mensalidades
          .where((m) => m.status == 'PENDENTE' || m.status == 'ATRASADO')
          .toList();

  FxMoney get _abertoTotal =>
      _abertas.fold(FxMoney.zero, (sum, item) => sum + item.valor);

  int get _atrasadas =>
      _mensalidades.where((m) => m.status == 'ATRASADO').length;

  int get _pagas => _mensalidades.where((m) => m.status == 'PAGO').length;

  Widget _atalhos({required Color primary, required bool isDark}) {
    return Wrap(
      spacing: TokensStrip.s2,
      runSpacing: TokensStrip.s2,
      children: [
        DashboardHomeActionChip(
          label: 'Assinatura',
          accent: primary,
          isDark: isDark,
          onPressed: () => context.push('/aluno/recorrencia'),
        ),
        DashboardHomeActionChip(
          label: 'Chat',
          accent: primary,
          isDark: isDark,
          onPressed: () => context.push('/chat/aluno'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final showSticky = !_loading && _erro == null;
    final hubSubtitle = financeiroAlunoHubSubtitle(
      lancamentos: _mensalidades.length,
      freshness: freshness,
    );

    return fxScreenA11yScope(
      label: 'Minhas mensalidades',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Mensalidades',
          onBack: () => safePopOrGo(context, '/dashboard/aluno'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar suas mensalidades',
              onTap: () => showFinanceiroAlunoHelpSheet(context),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: FxContentWidthLimiter(
                child:
                    _loading
                        ? const Padding(
                          padding: EdgeInsets.only(top: TokensStrip.s4),
                          child: SkeletonList(count: 5),
                        )
                        : _erro != null
                        ? FxErrorState(
                          chromeOnDark: isDark,
                          primary: primary,
                          title: FocuxMicrocopy.naoFoiPossivelCarregar,
                          message: _erro!,
                          onRetry: _carregar,
                        )
                        : RefreshIndicator(
                          onRefresh: _carregar,
                          child:
                              _mensalidades.isEmpty
                                  ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                      FxSettingsLayout.pageInset,
                                      TokensStrip.s4,
                                      FxSettingsLayout.pageInset,
                                      32,
                                    ),
                                    children: [
                                      FxHubHeader(
                                        title: 'Suas cobranças',
                                        subtitle: hubSubtitle,
                                      ),
                                      const SizedBox(height: TokensStrip.s4),
                                      OperationalMetricTile(
                                        label: 'Em aberto',
                                        value: _abertoTotal.format(
                                          showDecimals: false,
                                        ),
                                        hint: 'Nada atrasado',
                                        color: primary,
                                        isDark: isDark,
                                      ),
                                      const SizedBox(height: TokensStrip.s3),
                                      OperationalMetricTile(
                                        label: 'Pagas',
                                        value: '$_pagas',
                                        hint: 'Neste recorte',
                                        color: primary,
                                        isDark: isDark,
                                        emphasis:
                                            OperationalMetricEmphasis.muted,
                                      ),
                                      const SizedBox(height: TokensStrip.s4),
                                      _atalhos(
                                        primary: primary,
                                        isDark: isDark,
                                      ),
                                      const SizedBox(height: TokensStrip.s4),
                                      const FxEmptyState(
                                        icon: 'coin',
                                        title: 'Nenhuma mensalidade',
                                        subtitle:
                                            'Quando seu personal lançar uma cobrança, ela aparece aqui.',
                                      ),
                                    ],
                                  )
                                  : ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                      FxSettingsLayout.pageInset,
                                      TokensStrip.s4,
                                      FxSettingsLayout.pageInset,
                                      32,
                                    ),
                                    itemCount:
                                        _mensalidades.length +
                                        5 +
                                        (_hasMore ? 1 : 0),
                                    itemBuilder: (context, i) {
                                      if (i == 0) {
                                        return FxHubHeader(
                                          title: 'Suas cobranças',
                                          subtitle: hubSubtitle,
                                        );
                                      }
                                      if (i == 1) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: TokensStrip.s4,
                                            bottom: TokensStrip.s3,
                                          ),
                                          child: OperationalMetricTile(
                                            label: 'Em aberto',
                                            value: _abertoTotal.format(
                                              showDecimals: false,
                                            ),
                                            hint:
                                                _atrasadas == 0
                                                    ? 'Nada atrasado'
                                                    : '$_atrasadas atrasada${_atrasadas == 1 ? '' : 's'}',
                                            color:
                                                _atrasadas > 0
                                                    ? EagleTokens.bad
                                                    : primary,
                                            isDark: isDark,
                                            emphasis:
                                                _atrasadas > 0
                                                    ? OperationalMetricEmphasis
                                                        .alert
                                                    : OperationalMetricEmphasis
                                                        .normal,
                                          ),
                                        );
                                      }
                                      if (i == 2) {
                                        return OperationalMetricTile(
                                          label: 'Pagas',
                                          value: '$_pagas',
                                          hint: 'Neste recorte',
                                          color: primary,
                                          isDark: isDark,
                                        );
                                      }
                                      if (i == 3) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: TokensStrip.s4,
                                            bottom: TokensStrip.s3,
                                          ),
                                          child: _atalhos(
                                            primary: primary,
                                            isDark: isDark,
                                          ),
                                        );
                                      }
                                      if (i == 4) {
                                        return const SizedBox(
                                          height: TokensStrip.s2,
                                        );
                                      }
                                      final itemIndex = i - 5;
                                      if (itemIndex >= _mensalidades.length) {
                                        return FxSatelliteListTile(
                                          title:
                                              _carregandoMais
                                                  ? 'Carregando…'
                                                  : 'Carregar mais',
                                          titleCase: false,
                                          onTap:
                                              _carregandoMais
                                                  ? null
                                                  : _carregarMais,
                                          leading: FxIcon(
                                            name: 'plus',
                                            size: 18,
                                            color: primary,
                                          ),
                                        );
                                      }
                                      final item = _mensalidades[itemIndex];
                                      final overdue = item.status == 'ATRASADO';
                                      return FxSatelliteListTile(
                                        title:
                                            financeiroMensalidadeMesPorExtenso(
                                              item.mesReferencia,
                                            ),
                                        titleCase: false,
                                        onTap:
                                            () =>
                                                showFinanceiroAlunoCobrancaSheet(
                                                  context,
                                                  item: item,
                                                  onFalar:
                                                      () => context.push(
                                                        '/chat/aluno',
                                                      ),
                                                ),
                                        subtitle: Text(
                                          financeiroMensalidadeStatusLabel(
                                            item.status,
                                          ),
                                        ),
                                        accent:
                                            overdue
                                                ? EagleTokens.bad
                                                : primary,
                                        leading: FxIcon(
                                          name:
                                              overdue
                                                  ? 'alert-triangle'
                                                  : item.status == 'PAGO'
                                                  ? 'circle-check'
                                                  : 'coin',
                                          size: 18,
                                          color:
                                              overdue
                                                  ? EagleTokens.bad
                                                  : primary,
                                        ),
                                        trailing: Text(
                                          item.valor.format(
                                            showDecimals: false,
                                          ),
                                          style: FocuxHubTypography.metric(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),
              ),
            ),
            if (showSticky)
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    TokensStrip.s2,
                    FxSettingsLayout.pageInset,
                    TokensStrip.s3 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: FxLiquidPrimaryButton(
                    label: 'Falar com o personal',
                    onPressed: () => context.push('/chat/aluno'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
