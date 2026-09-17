import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../data/financeiro_repository.dart';
import '../financeiro_hub_scope.dart';
import '../providers/financeiro_provider.dart';
import '../utils/financeiro_hub_display.dart';

class FinanceiroResumoScreen extends ConsumerStatefulWidget {
  const FinanceiroResumoScreen({super.key});

  @override
  ConsumerState<FinanceiroResumoScreen> createState() =>
      _FinanceiroResumoScreenState();
}

class _FinanceiroResumoScreenState
    extends ConsumerState<FinanceiroResumoScreen> {
  late int _ano;
  late int _mes;
  bool _loadingOther = false;
  ResumoMensal? _otherResumo;
  String? _erro;
  DateTime? _otherFetchedAt;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _ano = now.year;
    _mes = now.month;
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _ano == now.year && _mes == now.month;
  }

  Future<void> _carregarOutroMes() async {
    setState(() {
      _loadingOther = true;
      _erro = null;
    });
    try {
      final r = await FinanceiroRepository(
        ref.read(apiClientProvider),
      ).resumoMensal(_ano, _mes);
      if (mounted) {
        setState(() {
          _otherResumo = r;
          _loadingOther = false;
          _otherFetchedAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = friendlyError(e);
          _loadingOther = false;
        });
      }
    }
  }

  Future<void> _abrirMes() async {
    var ops = financeiroMesOpcoes();
    if (!ops.any((o) => o.ano == _ano && o.mes == _mes)) {
      ops = [FinanceiroMesOpcao(ano: _ano, mes: _mes), ...ops];
    }
    final selected = FinanceiroMesOpcao(ano: _ano, mes: _mes).key;
    final picked = await showFxInsetPickerSheet<String>(
      context,
      title: 'Mês',
      selected: selected,
      items: [
        for (final o in ops)
          FxInsetPickerSheetItem(value: o.key, label: o.label),
      ],
    );
    if (!mounted || picked == null || picked == selected) return;
    final match = ops.where((o) => o.key == picked).firstOrNull;
    if (match == null) return;
    setState(() {
      _ano = match.ano;
      _mes = match.mes;
      _otherResumo = null;
      _erro = null;
    });
    if (!_isCurrentMonth) {
      await _carregarOutroMes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final mesLabel = financeiroMesTitulo(_mes, _ano);
    final homeAsync = ref.watch(financeiroHomeProvider);

    final ResumoMensal? resumo;
    final DateTime? fetchedAt;
    final bool loading;
    String? errorMsg = _erro;
    if (_isCurrentMonth) {
      resumo = homeAsync.valueOrNull?.resumoMesAtual;
      fetchedAt = homeAsync.valueOrNull?.fetchedAt;
      loading = homeAsync.isLoading && resumo == null;
      if (homeAsync.hasError && resumo == null) {
        errorMsg = friendlyError(homeAsync.error!);
      }
    } else {
      resumo = _otherResumo;
      fetchedAt = _otherFetchedAt;
      loading = _loadingOther;
    }

    final freshnessLabel = FxHubFreshness.fromFetchedAt(fetchedAt);

    return fxScreenA11yScope(
      label: 'Financeiro métricas. ${freshnessLabel ?? mesLabel}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                TokensStrip.s3,
                FxSettingsLayout.pageInset,
                0,
              ),
              child: SkeletonList(count: 3),
            )
          else if (errorMsg != null && resumo == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                TokensStrip.s3,
                FxSettingsLayout.pageInset,
                0,
              ),
              child: FxErrorState(
                chromeOnDark: isDark,
                primary: primary,
                message: errorMsg,
                onRetry: () {
                  if (_isCurrentMonth) {
                    ref.invalidate(financeiroHomeProvider);
                  } else {
                    _carregarOutroMes();
                  }
                },
              ),
            )
          else if (resumo == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                TokensStrip.s3,
                FxSettingsLayout.pageInset,
                0,
              ),
              child: FxEmptyState(
                icon: 'coin',
                title: 'Sem dados para exibir',
                subtitle: 'Nenhuma mensalidade neste período.',
                action: FxEmptyAction(
                  label: 'Nova mensalidade',
                  onTap: () => FinanceiroHubScope.maybeOf(
                    context,
                  )?.openNovaMensalidade(source: 'resumo_empty'),
                ),
              ),
            )
          else
            _buildContent(
              isDark,
              primary,
              freshnessLabel,
              mesLabel,
              resumo,
            ),
        ],
      ),
    );
  }

  Widget _buildContent(
    bool isDark,
    Color primary,
    String? freshnessLabel,
    String mesLabel,
    ResumoMensal r,
  ) {
    final mute = fxScreenMute(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        TokensStrip.s3,
        FxSettingsLayout.pageInset,
        0,
      ),
      child: FxStripCard(
        emphasize: true,
        padding: const EdgeInsets.all(TokensStrip.s3),
        semanticsLabel:
            'Recebido ${r.totalRecebido.format(showDecimals: false)}, '
            '${r.inadimplentes} inadimplentes',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _abrirMes,
              borderRadius: BorderRadius.circular(TokensStrip.rSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '$mesLabel · Cobrança do mês',
                  style: FocuxHubTypography.chip(mute),
                ),
              ),
            ),
            if (freshnessLabel != null) ...[
              const SizedBox(height: TokensStrip.s1),
              Text(
                freshnessLabel,
                style: FocuxHubTypography.bodyMuted(
                  color: mute,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: TokensStrip.s3),
            OperationalMetricTile(
              label: 'Recebido',
              value: r.totalRecebido.format(showDecimals: false),
              hint: 'Previsto ${r.totalPrevisto.format(showDecimals: false)}',
              color: EagleTokens.moneyGreen,
              isDark: isDark,
            ),
            const SizedBox(height: TokensStrip.s2),
            OperationalMetricTile(
              label: 'Inadimplentes',
              value: '${r.inadimplentes}',
              hint: 'Ticket ${r.ticketMedio.format(showDecimals: false)}',
              color: r.inadimplentes > 0 ? EagleTokens.bad : primary,
              isDark: isDark,
              emphasis: r.inadimplentes > 0
                  ? OperationalMetricEmphasis.alert
                  : OperationalMetricEmphasis.normal,
            ),
            const SizedBox(height: TokensStrip.s3),
            DashboardHomeActionChip(
              label: 'Ver mensalidades',
              accent: EagleTokens.moneyGreen,
              isDark: isDark,
              onPressed: () => FinanceiroHubScope.maybeOf(
                context,
              )?.goToMensalidades(source: 'metricas'),
            ),
          ],
        ),
      ),
    );
  }
}
