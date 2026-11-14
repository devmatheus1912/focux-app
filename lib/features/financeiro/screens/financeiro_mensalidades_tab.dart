import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/money/fx_money_input.dart';
import '../utils/vencimento_atalhos.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/fx_choice_strip.dart';
import '../../../core/widgets/fx_form_chrome.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../utils/financeiro_do_aluno.dart';
import '../../../l10n/app_localizations.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../data/financeiro_repository.dart';
import '../providers/financeiro_provider.dart';
import '../utils/financeiro_hub_display.dart';
import '../utils/financeiro_numeros.dart';
import '../utils/mensalidade_surface_actions.dart';
import '../../../core/utils/fx_utils.dart';
import '../widgets/financeiro_aluno_etapa.dart';
import '../../../core/theme/fx_icons.dart';

part 'financeiro_mensalidades_tab_actions.part.dart';
part 'financeiro_mensalidades_tab_forms.part.dart';
part 'financeiro_mensalidades_tab_widgets.part.dart';
part 'financeiro_mensalidades_tab_aluno.part.dart';

class FinanceiroMensalidadesTab extends ConsumerStatefulWidget {
  const FinanceiroMensalidadesTab({
    super.key,
    this.initialAlunoId,
    this.novaMensalidadeToken = 0,
    this.filtroPedido,
    this.filtroToken = 0,
    this.loteToken = 0,
  });

  final int? initialAlunoId;

  /// Quando incrementa, abre o formulário de nova mensalidade (hub empty CTA).
  final int novaMensalidadeToken;

  /// Filtro pedido de fora (toque num dos números do mês); vale quando
  /// [filtroToken] muda.
  final MensalidadeFiltro? filtroPedido;
  final int filtroToken;

  /// Quando muda, entra no modo "marcar várias como pagas" (o "⋯" do topo).
  final int loteToken;

  @override
  ConsumerState<FinanceiroMensalidadesTab> createState() =>
      _FinanceiroMensalidadesTabState();
}

class _FinanceiroMensalidadesTabState
    extends ConsumerState<FinanceiroMensalidadesTab> {
  List<Mensalidade> _homeItems = [];

  /// Visão de um aluno: todas as cobranças dele, para o resumo somar tudo e
  /// não só as páginas carregadas. `null` enquanto não chega (ou se falhar).
  List<Mensalidade>? _todasDoAluno;

  Future<void> _carregarTodasDoAluno() async {
    final alunoId = widget.initialAlunoId;
    if (alunoId == null) return;
    try {
      final todas = await FinanceiroRepository(
        ref.read(apiClientProvider),
      ).listarPorAluno(alunoId, size: 200);
      if (mounted) setState(() => _todasDoAluno = todas);
    } catch (_) {
      // Sem a lista completa o resumo usa o que carregou, com o aviso.
    }
  }
  List<Mensalidade> _items = [];
  var _page = 0;
  var _homePage = 0;
  var _hasMore = false;
  var _homeHasMore = false;
  MensalidadeFiltro? _homeFiltro;
  var _loading = true;
  var _carregandoMais = false;
  String? _erro;
  var _buscaAtiva = '';
  var _modoSelecao = false;
  final _selecionados = <int>{};
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  int _handledNovaToken = 0;

  /// Sem escolha do usuário, o filtro inicial segue o atraso do mês.
  var _filtroDefinido = false;
  late var _filtro =
      widget.initialAlunoId == null
          ? MensalidadeFiltro.abertas
          : MensalidadeFiltro.todas;

  /// Primeira página em aberto já vem no BFF da home; os outros chips paginam direto.
  bool get _usaHome =>
      widget.initialAlunoId == null && _filtro == MensalidadeFiltro.abertas;

  void _trocarFiltro(MensalidadeFiltro f) {
    _filtroDefinido = true;
    if (f == _filtro) return;
    setState(() => _filtro = f);
    if (_searchCtrl.text.trim().isEmpty) {
      _load();
    } else {
      _buscar(_searchCtrl.text.trim());
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearchChanged);
    _scheduleNovaMensalidadeIfNeeded();
  }

  @override
  void didUpdateWidget(covariant FinanceiroMensalidadesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.novaMensalidadeToken != oldWidget.novaMensalidadeToken) {
      _scheduleNovaMensalidadeIfNeeded();
    }
    final pedido = widget.filtroPedido;
    if (pedido != null && widget.filtroToken != oldWidget.filtroToken) {
      _trocarFiltro(pedido);
    }
    if (widget.loteToken != oldWidget.loteToken && !_modoSelecao) {
      _entrarModoLote();
    }
  }

  void _scheduleNovaMensalidadeIfNeeded() {
    final token = widget.novaMensalidadeToken;
    if (token <= 0 || token == _handledNovaToken) return;
    _handledNovaToken = token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _abrirFormularioNovaMensalidade();
    });
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
      if (_homeFiltro != _filtro) {
        _buscaAtiva = '';
        _load();
        return;
      }
      setState(() {
        _buscaAtiva = '';
        _items = _homeItems;
        _page = _homePage;
        _hasMore = _homeHasMore;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _buscar(query));
  }

  bool _buscaMudou(String query, MensalidadeFiltro filtro) =>
      filtro != _filtro || _searchCtrl.text.trim() != query;

  Future<void> _buscar(String query) async {
    final filtro = _filtro;
    try {
      final results = await FinanceiroRepository(
        ref.read(apiClientProvider),
      ).listarPagina(
        nomeAluno: query,
        alunoId: widget.initialAlunoId,
        filtro: filtro,
      );
      if (!mounted || _buscaMudou(query, filtro)) return;
      setState(() {
        _buscaAtiva = query;
        _items = results.mensalidades;
        _page = results.page;
        _hasMore = results.hasMore;
      });
    } catch (e) {
      if (!mounted || _buscaMudou(query, filtro)) return;
      setState(() {
        _buscaAtiva = query;
        _items =
            _homeItems
                .where(
                  (m) =>
                      m.alunoNome.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
        _hasMore = false;
      });
    }
  }

  Future<void> _applyPage(MensalidadesPage page) async {
    setState(() {
      _items = page.mensalidades;
      _page = page.page;
      _hasMore = page.hasMore;
      _homeItems = page.mensalidades;
      _homePage = page.page;
      _homeHasMore = page.hasMore;
      _homeFiltro = _filtro;
      _buscaAtiva = '';
      _loading = false;
    });
  }

  Future<void> _load({bool force = false, bool silent = false}) async {
    unawaited(_carregarTodasDoAluno());
    if (!silent) {
      setState(() {
        _loading = true;
        _erro = null;
      });
    }
    try {
      if (force) {
        invalidateFinanceiroCaches(ref);
      }
      if (!_filtroDefinido) {
        _filtroDefinido = true;
        if (widget.initialAlunoId == null) {
          final home = await ref.read(financeiroHomeProvider.future);
          if (!mounted) return;
          final inicial = financeiroFiltroInicial(
            quantidadeAtrasadas: home.resumoMesAtual.quantidadeAtrasadas,
          );
          if (inicial != _filtro) setState(() => _filtro = inicial);
        }
      }
      if (!_usaHome) {
        final filtro = _filtro;
        final page = await FinanceiroRepository(
          ref.read(apiClientProvider),
        ).listarPagina(alunoId: widget.initialAlunoId, filtro: filtro);
        if (!mounted || filtro != _filtro) return;
        await _applyPage(page);
        return;
      }
      final home = await ref.read(financeiroHomeProvider.future);
      if (!mounted || !_usaHome) return;
      await _applyPage(
        MensalidadesPage(
          mensalidades: home.mensalidades,
          page: home.page,
          size: home.size,
          hasMore: home.hasMore,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _onPullRefresh() async {
    await _load(force: true, silent: true);
  }

  Future<void> _carregarMais() async {
    if (_carregandoMais || !_hasMore) return;
    setState(() => _carregandoMais = true);
    final filtro = _filtro;
    final busca = _buscaAtiva;
    try {
      final next = await FinanceiroRepository(
        ref.read(apiClientProvider),
      ).listarPagina(
        page: _page + 1,
        nomeAluno: busca.isEmpty ? null : busca,
        alunoId: widget.initialAlunoId,
        filtro: filtro,
      );
      if (!mounted) return;
      if (filtro != _filtro || busca != _buscaAtiva) {
        setState(() => _carregandoMais = false);
        return;
      }
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
    if (widget.initialAlunoId != null) return _buildDoAluno(context);
    final chrome = ShellChrome.of(context);
    final mute = chrome.mute;
    final primary = Theme.of(context).colorScheme.primary;
    // Atraso é estado, não erro: âmbar, como no resto do app.
    final alerta = chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn;
    // Busca só ajuda com lista grande; com poucas cobranças é ruído.
    final mostrarBusca = _searchCtrl.text.isNotEmpty ||
        _homeItems.length >= 6 ||
        _homeHasMore ||
        _items.length >= 6;
    final atrasoNoMes = (ref
                .watch(financeiroHomeProvider)
                .value
                ?.resumoMesAtual
                .quantidadeAtrasadas ??
            0) >
        0;
    // "Marcar lote" só faz sentido com 2 ou mais para marcar.
    final mostrarLote =
        !_modoSelecao &&
        financeiroMostrarMarcarLote(
          _items.where((m) => financeiroStatusAberto(m.status)).length,
        );
    // Com atraso, "Atrasadas" vem primeiro.
    final filtros = [
      if (atrasoNoMes) MensalidadeFiltro.atrasadas,
      for (final f in MensalidadeFiltro.values)
        if (!(atrasoNoMes && f == MensalidadeFiltro.atrasadas)) f,
    ];
    return fxScreenA11yScope(
      label: 'Mensalidades',
      child: FxKeyboardPopScope(
        child: FxKeyboardDismissScope(
          child: Column(
            children: [
              if (widget.initialAlunoId == null && mostrarBusca)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    8,
                    FxSettingsLayout.pageInset,
                    4,
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome do aluno',
                      hintStyle: TextStyle(
                        color: mute,
                        fontSize: TokensStrip.fontBodySm,
                        fontWeight: FontWeight.w600,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(FxIcons.buscar, size: 18, color: mute),
                      ),
                      suffixIcon:
                          _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                tooltip: 'Limpar busca',
                                icon: Icon(FxIcons.fecharPequeno, size: 16, color: mute),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s2,
                  FxSettingsLayout.pageInset,
                  0,
                ),
                // Filtros à esquerda, como o resto da tela; rolam de lado se
                // não couberem. "Marcar lote" é o último item da faixa.
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in filtros) ...[
                          FxToggleChip(
                            label: mensalidadeFiltroLabel(f, S.of(context)),
                            selected: _filtro == f,
                            isDark: chrome.isDark,
                            onTap: () => _trocarFiltro(f),
                          ),
                          const SizedBox(width: TokensStrip.s2),
                        ],
                        if (mostrarLote)
                          FxActionChip(
                            label: financeiroListaToolLabel(
                              FinanceiroListaToolId.marcarLote,
                              modoSelecao: false,
                              selecionados: 0,
                            ),
                            accent: primary,
                            isDark: chrome.isDark,
                            onPressed: _entrarModoLote,
                          ),
                      ],
                    ),
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
                        : Column(
                          children: [
                            // A barra do lote só existe durante a seleção.
                            if (_items.isNotEmpty && _modoSelecao)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  FxSettingsLayout.pageInset,
                                  TokensStrip.s2,
                                  FxSettingsLayout.pageInset,
                                  TokensStrip.s2,
                                ),
                                child: Builder(
                                  builder: (context) {
                                    final tools = financeiroListaToolsDoLote();
                                    Future<void> runTool(
                                      FinanceiroListaToolId id,
                                    ) async {
                                      switch (id) {
                                        case FinanceiroListaToolId.marcarLote:
                                          if (_modoSelecao) {
                                            await _confirmarLotePago();
                                          } else {
                                            _entrarModoLote();
                                          }
                                        case FinanceiroListaToolId.cancelarLote:
                                          _sairModoLote();
                                      }
                                    }

                                    Future<void> openMais() async {
                                      final chosen =
                                          await showFxInsetPickerSheet<
                                            FinanceiroListaToolId
                                          >(
                                            context,
                                            title: 'Mais na lista',
                                            items: [
                                              for (final id in tools.mais)
                                                FxInsetPickerSheetItem(
                                                  value: id,
                                                  label:
                                                      financeiroListaToolLabel(
                                                        id,
                                                        modoSelecao:
                                                            _modoSelecao,
                                                        selecionados:
                                                            _selecionados
                                                                .length,
                                                      ),
                                                ),
                                            ],
                                          );
                                      if (chosen == null || !mounted) return;
                                      await runTool(chosen);
                                    }

                                    return Wrap(
                                      spacing: TokensStrip.s2,
                                      runSpacing: TokensStrip.s2,
                                      children: [
                                        if (tools.foldChip != null)
                                          FxActionChip(
                                            label: financeiroListaToolLabel(
                                              tools.foldChip!,
                                              modoSelecao: _modoSelecao,
                                              selecionados:
                                                  _selecionados.length,
                                            ),
                                            accent: primary,
                                            isDark: chrome.isDark,
                                            onPressed:
                                                () => runTool(tools.foldChip!),
                                          ),
                                        if (tools.mais.isNotEmpty)
                                          FxActionChip(
                                            label: 'Mais',
                                            accent: chrome.mute,
                                            isDark: chrome.isDark,
                                            onPressed: openMais,
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            Expanded(
                              child:
                                  _items.isEmpty
                                      ? RefreshIndicator(
                                        onRefresh: _onPullRefresh,
                                        child: ListView(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          padding: const EdgeInsets.fromLTRB(
                                            FxSettingsLayout.pageInset,
                                            0,
                                            FxSettingsLayout.pageInset,
                                            24,
                                          ),
                                          children: [
                                            SizedBox(
                                              height:
                                                  MediaQuery.sizeOf(
                                                    context,
                                                  ).height *
                                                  0.45,
                                              child: _buildMensalidadesEmpty(
                                                context,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      : RefreshIndicator(
                                        onRefresh: _onPullRefresh,
                                        child: ListView.builder(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          padding: const EdgeInsets.fromLTRB(
                                            FxSettingsLayout.pageInset,
                                            0,
                                            FxSettingsLayout.pageInset,
                                            24,
                                          ),
                                          itemCount:
                                              _items.length +
                                              (_hasMore ? 1 : 0),
                                          itemBuilder: (context, i) {
                                            if (i >= _items.length) {
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
                                                leading: Icon(
                                                  FxIcons.adicionar,
                                                  size: 20,
                                                  color: primary,
                                                ),
                                              );
                                            }
                                            final item = _items[i];
                                            final overdue =
                                                item.status == 'ATRASADO';
                                            final cancelada =
                                                item.status == 'CANCELADO';
                                            final selected = _selecionados
                                                .contains(item.id);
                                            final aberto =
                                                financeiroStatusAberto(
                                                  item.status,
                                                );
                                            final cabecalho =
                                                financeiroMesCabecalho(
                                                  item.mesReferencia,
                                                );
                                            final novoMes =
                                                i == 0 ||
                                                financeiroMesCabecalho(
                                                      _items[i - 1]
                                                          .mesReferencia,
                                                    ) !=
                                                    cabecalho;
                                            final tile = FxSatelliteListTile(
                                              title: item.alunoNome,
                                              subtitle: Text(
                                                financeiroMensalidadeEstado(
                                                  item,
                                                  hoje: DateTime.now(),
                                                ),
                                              ),
                                              onTap:
                                                  () =>
                                                      _modoSelecao
                                                          ? _toggleLote(item)
                                                          : _abrirAcoes(item),
                                              onLongPress:
                                                  aberto
                                                      ? () {
                                                        if (!_modoSelecao) {
                                                          _entrarModoLote();
                                                        }
                                                        _toggleLote(item);
                                                      }
                                                      : null,
                                              accent:
                                                  overdue
                                                      ? alerta
                                                      : cancelada
                                                      ? mute
                                                      : primary,
                                              leading: Icon(
                                                _modoSelecao && selected
                                                    ? FxIcons.concluidoAtivo
                                                    : _modoSelecao
                                                    ? FxIcons.circulo
                                                    : overdue
                                                    ? FxIcons.alerta
                                                    : item.status == 'PAGO'
                                                    ? FxIcons.concluido
                                                    : cancelada
                                                    ? FxIcons.fechar
                                                    : FxIcons.relogio,
                                                size: 20,
                                                color:
                                                    overdue
                                                        ? alerta
                                                        : cancelada
                                                        ? mute
                                                        : primary,
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    item.valor.formatCobranca(),
                                                    style: TextStyle(
                                                      color: chrome.ink,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontFeatures: const [
                                                        FontFeature
                                                            .tabularFigures(),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    FxIcons.chevronDireitaPequeno,
                                                    size: 16,
                                                    color: mute,
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (!novoMes) return tile;
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.fromLTRB(
                                                    4,
                                                    i == 0
                                                        ? TokensStrip.s2
                                                        : TokensStrip.s4,
                                                    4,
                                                    TokensStrip.s2,
                                                  ),
                                                  child: Semantics(
                                                    header: true,
                                                    child: Text(
                                                      cabecalho,
                                                      style: TextStyle(
                                                        color: mute,
                                                        fontSize: TokensStrip.fontBodySm,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                tile,
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                            ),
                            if (!_modoSelecao)
                              SafeArea(
                                top: false,
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    FxSettingsLayout.pageInset,
                                    TokensStrip.s2,
                                    FxSettingsLayout.pageInset,
                                    TokensStrip.s3 +
                                        MediaQuery.viewInsetsOf(context).bottom,
                                  ),
                                  child: FxLiquidPrimaryButton(
                                    label: 'Nova mensalidade',
                                    icon: FxIcons.adicionar,
                                    onPressed: () {
                                      FxKeyboardDismissScope.dismiss();
                                      _abrirFormularioNovaMensalidade();
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
