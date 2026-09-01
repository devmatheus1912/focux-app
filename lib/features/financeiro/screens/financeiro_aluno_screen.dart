import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focux_app/core/widgets/fx_empty_state.dart';
import 'package:focux_app/core/widgets/fx_error_state.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
import 'package:focux_app/core/widgets/fx_shell_scaffold.dart';
import 'package:focux_app/core/widgets/skeleton_loader.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../features/alunos/utils/satellite_screen_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/financeiro_repository.dart';
import '../utils/financeiro_hub_display.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: 'Minhas mensalidades',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Minhas mensalidades',
          subtitle: freshness ?? 'Suas cobranças',
        ),
        body: FxContentWidthLimiter(
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
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 72),
                                FxEmptyState(
                                  icon: 'coin',
                                  title: 'Nenhuma mensalidade',
                                  subtitle:
                                      'Quando seu personal lançar uma cobrança, ela aparece aqui.',
                                ),
                              ],
                            )
                            : ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                FxSettingsLayout.pageInset,
                                8,
                                FxSettingsLayout.pageInset,
                                32,
                              ),
                              children: [
                                FxSettingsGroup(
                                  header: 'Cobranças',
                                  caption:
                                      'Valores e status da sua mensalidade.',
                                  children: [
                                    for (
                                      var i = 0;
                                      i < _mensalidades.length;
                                      i++
                                    )
                                      FxSettingsTile(
                                        fxIcon:
                                            _mensalidades[i].status ==
                                                    'ATRASADO'
                                                ? 'alert-triangle'
                                                : _mensalidades[i].status ==
                                                    'PAGO'
                                                ? 'circle-check'
                                                : 'coin',
                                        label:
                                            financeiroMensalidadeMesPorExtenso(
                                              _mensalidades[i].mesReferencia,
                                            ),
                                        subtitle:
                                            financeiroMensalidadeStatusLabel(
                                              _mensalidades[i].status,
                                            ),
                                        value: formatBrlCurrency(
                                          _mensalidades[i].valor,
                                          showDecimals: false,
                                        ),
                                        numeric: true,
                                        danger:
                                            _mensalidades[i].status ==
                                            'ATRASADO',
                                        showDivider:
                                            i != _mensalidades.length - 1 ||
                                            _hasMore,
                                        onTap: () {},
                                      ),
                                    if (_hasMore)
                                      FxSettingsTile(
                                        fxIcon: 'plus',
                                        label:
                                            _carregandoMais
                                                ? 'Carregando…'
                                                : 'Carregar mais',
                                        value: '',
                                        showDivider: false,
                                        onTap:
                                            _carregandoMais
                                                ? () {}
                                                : _carregarMais,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                  ),
        ),
      ),
    );
  }
}
