import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/money/fx_money.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../data/financeiro_repository.dart';
import '../providers/financeiro_provider.dart';
import '../utils/financeiro_hub_display.dart';
import '../utils/mensalidade_surface_actions.dart';

part 'financeiro_mensalidades_tab_actions.part.dart';
part 'financeiro_mensalidades_tab_forms.part.dart';
part 'financeiro_mensalidades_tab_widgets.part.dart';

class FinanceiroMensalidadesTab extends ConsumerStatefulWidget {
  const FinanceiroMensalidadesTab({super.key, this.initialAlunoId});

  final int? initialAlunoId;

  @override
  ConsumerState<FinanceiroMensalidadesTab> createState() =>
      _FinanceiroMensalidadesTabState();
}

class _FinanceiroMensalidadesTabState
    extends ConsumerState<FinanceiroMensalidadesTab> {
  List<Mensalidade> _homeItems = [];
  List<Mensalidade> _items = [];
  var _page = 0;
  var _homePage = 0;
  var _hasMore = false;
  var _homeHasMore = false;
  var _loading = true;
  var _carregandoMais = false;
  String? _erro;
  var _buscaAtiva = '';
  var _modoSelecao = false;
  final _selecionados = <int>{};
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      setState(() {
        _buscaAtiva = '';
        _items = _homeItems;
        _page = _homePage;
        _hasMore = _homeHasMore;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await FinanceiroRepository(
          ref.read(apiClientProvider),
        ).listarPagina(
          nomeAluno: query,
          alunoId: widget.initialAlunoId,
        );
        if (!mounted) return;
        setState(() {
          _buscaAtiva = query;
          _items = results.mensalidades;
          _page = results.page;
          _hasMore = results.hasMore;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _buscaAtiva = query;
          _items =
              _homeItems
                  .where(
                    (m) => m.alunoNome.toLowerCase().contains(
                      query.toLowerCase(),
                    ),
                  )
                  .toList();
          _hasMore = false;
        });
      }
    });
  }

  Future<void> _applyPage(MensalidadesPage page, {required bool fromHome}) async {
    setState(() {
      _items = page.mensalidades;
      _page = page.page;
      _hasMore = page.hasMore;
      if (fromHome || widget.initialAlunoId != null) {
        _homeItems = page.mensalidades;
        _homePage = page.page;
        _homeHasMore = page.hasMore;
      }
      _buscaAtiva = '';
      _loading = false;
    });
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      if (force) {
        invalidateFinanceiroCaches(ref);
      }
      final alunoFilter = widget.initialAlunoId;
      if (alunoFilter != null) {
        final page = await FinanceiroRepository(
          ref.read(apiClientProvider),
        ).listarPagina(alunoId: alunoFilter);
        if (!mounted) return;
        await _applyPage(page, fromHome: false);
        return;
      }
      final home = await ref.read(financeiroHomeProvider.future);
      if (!mounted) return;
      await _applyPage(
        MensalidadesPage(
          mensalidades: home.mensalidades,
          page: home.page,
          size: home.size,
          hasMore: home.hasMore,
        ),
        fromHome: true,
      );
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
      ).listarPagina(
        page: _page + 1,
        nomeAluno: _buscaAtiva.isEmpty ? null : _buscaAtiva,
        alunoId: widget.initialAlunoId,
      );
      if (!mounted) return;
      final seen = _items.map((m) => m.id).toSet();
      final merged = [
        ..._items,
        ...next.mensalidades.where((m) => seen.add(m.id)),
      ];
      setState(() {
        _items = merged;
        _page = next.page;
        _hasMore = next.hasMore;
        if (_buscaAtiva.isEmpty) {
          _homeItems = merged;
          _homePage = next.page;
          _homeHasMore = next.hasMore;
        }
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
    final chrome = ShellChrome.of(context);
    final mute = chrome.mute;
    final primary = Theme.of(context).colorScheme.primary;
    return fxScreenA11yScope(
      label: 'Mensalidades',
      child: Column(
        children: [
          if (widget.initialAlunoId == null)
            Padding(
            padding: const EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              8,
              FxSettingsLayout.pageInset,
              4,
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por nome do aluno',
                hintStyle: TextStyle(
                  color: mute,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FxIcon(name: 'search', size: 18, color: mute),
                ),
                suffixIcon:
                    _searchCtrl.text.isNotEmpty
                        ? IconButton(
                          tooltip: 'Limpar busca',
                          icon: FxIcon(name: 'x', size: 16, color: mute),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _buscaAtiva = '';
                              _items = _homeItems;
                              _page = _homePage;
                              _hasMore = _homeHasMore;
                            });
                          },
                        )
                        : null,
                filled: true,
                fillColor: chrome.cardFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: FxInputDeco.outlineBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: chrome.line),
                ),
                enabledBorder: FxInputDeco.outlineBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: chrome.line),
                ),
                focusedBorder: FxInputDeco.outlineBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primary, width: 1.6),
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child:
                _loading
                    ? _buildMensalidadesLoading(context)
                    : _erro != null
                    ? FxErrorState(
                      chromeOnDark: chrome.isDark,
                      primary: primary,
                      message: _erro!,
                      onRetry: () => _load(force: true),
                    )
                    : _items.isEmpty
                    ? _buildMensalidadesEmpty(context)
                    : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            FxSettingsLayout.pageInset,
                            8,
                            FxSettingsLayout.pageInset,
                            8,
                          ),
                          child: Wrap(
                            spacing: TokensStrip.s2,
                            runSpacing: TokensStrip.s2,
                            children: [
                              DashboardHomeActionChip(
                                label: 'Atualizar atrasos',
                                accent: primary,
                                isDark: chrome.isDark,
                                onPressed: _atualizarAtrasos,
                              ),
                              if (_items.any(
                                (m) => financeiroStatusAberto(m.status),
                              ))
                                DashboardHomeActionChip(
                                  label: financeiroLotePagoChipLabel(
                                    modoSelecao: _modoSelecao,
                                    selecionados: _selecionados.length,
                                  ),
                                  accent: EagleTokens.moneyGreen,
                                  isDark: chrome.isDark,
                                  onPressed: _modoSelecao
                                      ? _confirmarLotePago
                                      : _entrarModoLote,
                                ),
                              if (_modoSelecao)
                                DashboardHomeActionChip(
                                  label: 'Cancelar',
                                  accent: chrome.mute,
                                  isDark: chrome.isDark,
                                  onPressed: _sairModoLote,
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              FxSettingsLayout.pageInset,
                              0,
                              FxSettingsLayout.pageInset,
                              24,
                            ),
                            itemCount: _items.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i >= _items.length) {
                                return FxSatelliteListTile(
                                  title:
                                      _carregandoMais
                                          ? 'Carregando…'
                                          : 'Carregar mais',
                                  titleCase: false,
                                  onTap:
                                      _carregandoMais ? null : _carregarMais,
                                  leading: FxIcon(
                                    name: 'plus',
                                    size: 18,
                                    color: primary,
                                  ),
                                );
                              }
                              final item = _items[i];
                              final overdue = item.status == 'ATRASADO';
                              final selected = _selecionados.contains(
                                item.alunoId,
                              );
                              return FxSatelliteListTile(
                                title: item.alunoNome,
                                subtitle: Text(
                                  financeiroMensalidadeSubtitle(
                                    item.status,
                                    item.mesReferencia,
                                  ),
                                ),
                                onTap: () => _modoSelecao
                                    ? _toggleLote(item)
                                    : _abrirAcoes(item),
                                accent: overdue ? EagleTokens.bad : primary,
                                leading: FxIcon(
                                  name:
                                      _modoSelecao && selected
                                          ? 'circle-check'
                                          : overdue
                                          ? 'alert-triangle'
                                          : item.status == 'PAGO'
                                          ? 'circle-check'
                                          : 'coin',
                                  size: 18,
                                  color:
                                      overdue ? EagleTokens.bad : primary,
                                ),
                                trailing: Text(
                                  item.valor.format(showDecimals: false),
                                  style: TextStyle(
                                    color: chrome.ink,
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              FxSettingsLayout.pageInset,
                              TokensStrip.s2,
                              FxSettingsLayout.pageInset,
                              TokensStrip.s3,
                            ),
                            child: FxLiquidPrimaryButton(
                              label: 'Nova mensalidade',
                              onPressed: _abrirFormularioNovaMensalidade,
                            ),
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}
