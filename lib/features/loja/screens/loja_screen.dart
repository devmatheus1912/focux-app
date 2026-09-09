import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pacotes/data/pacote_repository.dart';
import '../../planos/data/planos_repository.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/loja_repository.dart';
import '../models/loja_pedido.dart';
import '../utils/loja_hub_display.dart';

part 'loja_screen_actions.part.dart';

final lojaRepositoryProvider = Provider(
  (ref) => LojaRepository(ref.read(apiClientProvider)),
);

class LojaScreen extends ConsumerStatefulWidget {
  const LojaScreen({super.key});

  @override
  ConsumerState<LojaScreen> createState() => _LojaScreenState();
}

class _LojaScreenState extends ConsumerState<LojaScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  LojaHubView _view = LojaHubView.vitrine;
  List<Pacote> _pacotes = const [];
  List<LojaPedido> _pedidos = const [];
  PlanoFeatures? _planoFromHome;
  var _loading = true;
  String? _error;
  DateTime? _fetchedAt;
  var _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _query = value);
    });
  }

  void _clearQuery() {
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    setState(() => _query = '');
  }

  void _leave() {
    FxKeyboardDismissScope.dismiss();
    safePopOrGo(context, '/perfil/ferramentas');
  }

  List<Pacote> get _visiblePacotes => _pacotes
      .where(
        (p) => lojaPacoteMatches(
          titulo: p.titulo,
          descricao: p.descricao,
          query: _query,
        ),
      )
      .toList();

  List<LojaPedido> get _visiblePedidos => _pedidos
      .where(
        (p) => lojaPedidoMatches(
          buyerNome: p.buyerNome,
          buyerEmail: p.buyerEmail,
          status: p.status,
          query: _query,
        ),
      )
      .toList();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final home = await ref.read(lojaRepositoryProvider).getHome();
      if (!mounted) return;
      setState(() {
        _pacotes = home.pacotes;
        _pedidos = home.pedidos;
        _planoFromHome = home.planoFeatures;
        _fetchedAt = DateTime.now();
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
    final scheme = Theme.of(context).colorScheme;
    final chrome = ShellChrome.of(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final visibleCount = _view == LojaHubView.vitrine
        ? _visiblePacotes.length
        : _visiblePedidos.length;
    final planoFromHome = _planoFromHome;
    if (planoFromHome != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(planoFeaturesProvider.notifier).seedFromHome(planoFromHome);
      });
    }

    return fxScreenA11yScope(
      label: 'Loja digital',
      child: FeatureGate(
        featureName: 'Loja Digital',
        requiredPlan: SubscriptionPlan.ENTERPRISE,
        capability: 'lojaDigital',
        child: PopScope(
          canPop: !keyboardOpen && !_searchFocus.hasFocus,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (keyboardOpen || _searchFocus.hasFocus) {
              FxKeyboardDismissScope.dismiss();
              return;
            }
            _leave();
          },
          child: FxShellScaffold(
            useMesh: true,
            dismissKeyboard: true,
            constrainWidth: false,
            appBar: FxShellAppBar(
              title: 'Loja digital',
              subtitle: FxHubFreshness.joinCount(
                lojaCountLabel(view: _view, count: visibleCount),
                FxHubFreshness.fromFetchedAt(_fetchedAt),
              ),
              onBack: _leave,
              actions: [
                FxHelpIconButton(
                  tooltip: 'Como usar a loja',
                  onTap: () => showFxHelpSheet(
                    context,
                    title: 'Loja digital',
                    subtitle: 'Vitrine com PIX e pedidos do comprador.',
                    tips: const [
                      FxHelpTip(
                        'Vitrine',
                        'Toque no pacote para gerar um PIX.',
                      ),
                      FxHelpTip(
                        'Pedidos',
                        'Toque para copiar o código ou marcar pago.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TokensStrip.s4,
                    TokensStrip.s2,
                    TokensStrip.s4,
                    TokensStrip.s2,
                  ),
                  child: DecoratedBox(
                    decoration: fxStripCardDecoration(
                      context,
                      accent: scheme.primary,
                      radius: TokensStrip.rCard,
                      glowStrength: 0.03,
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      onChanged: _onQueryChanged,
                      onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: _view == LojaHubView.vitrine
                            ? 'Buscar pacote'
                            : 'Buscar pedido',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: scheme.primary,
                          size: 20,
                        ),
                        suffixIcon: _query.trim().isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Limpar busca',
                                onPressed: _clearQuery,
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: chrome.mute,
                                  size: 18,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TokensStrip.s4,
                    0,
                    TokensStrip.s4,
                    TokensStrip.s2,
                  ),
                  child: Wrap(
                    spacing: TokensStrip.s2,
                    runSpacing: TokensStrip.s2,
                    children: [
                      for (final view in LojaHubView.values)
                        FxToggleChip(
                          label: lojaHubViewLabel(view),
                          selected: _view == view,
                          isDark: chrome.isDark,
                          onTap: () {
                            if (_view == view) return;
                            setState(() => _view = view);
                          },
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                          child: SkeletonList(count: 5),
                        )
                      : _error != null
                      ? FxErrorState(
                          chromeOnDark: chrome.isDark,
                          primary: scheme.primary,
                          message: _error!,
                          onRetry: _load,
                        )
                      : FxContentWidthLimiter(
                          child: IndexedStack(
                            index: _view.index,
                            children: [_buildVitrine(), _buildPedidos()],
                          ),
                        ),
                ),
                if (!_loading && _error == null)
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
                        label: 'Ir para planos',
                        onPressed: () => context.push('/pacotes'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVitrine() {
    final visible = _visiblePacotes;
    final primary = Theme.of(context).colorScheme.primary;
    if (visible.isEmpty) {
      final filtered = _query.trim().isNotEmpty;
      return RefreshIndicator(
        color: primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            FxEmptyState(
              icon: filtered ? 'search' : 'spark',
              title: filtered
                  ? 'Nenhum pacote encontrado'
                  : 'Nenhum pacote na vitrine',
              subtitle: filtered
                  ? 'Ajuste a busca.'
                  : 'Crie planos em Planos & link de vendas para vender pela loja.',
              action: filtered
                  ? FxEmptyAction(label: 'Limpar busca', onTap: _clearQuery)
                  : FxEmptyAction(
                      label: 'Ir para pacotes',
                      onTap: () => context.push('/pacotes'),
                    ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primary,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          FxSettingsLayout.pageInset,
          TokensStrip.s6 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        itemCount: visible.length,
        itemBuilder: (context, index) {
          final pacote = visible[index];
          return FxSatelliteListTile(
            title: pacote.titulo,
            subtitle: Text(
              lojaPacoteSubtitle(
                descricao: pacote.descricao,
                duracaoMeses: pacote.duracaoMeses,
              ),
            ),
            trailing: Text(
              formatBrlCurrency(pacote.valor, showDecimals: false),
              style: FocuxHubTypography.bodyMuted(
                color: fxScreenMute(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () => _checkoutPacote(pacote),
          );
        },
      ),
    );
  }

  Widget _buildPedidos() {
    final visible = _visiblePedidos;
    final primary = Theme.of(context).colorScheme.primary;
    if (visible.isEmpty) {
      final filtered = _query.trim().isNotEmpty;
      return RefreshIndicator(
        color: primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            FxEmptyState(
              icon: filtered ? 'search' : 'article',
              title: filtered
                  ? 'Nenhum pedido encontrado'
                  : 'Nenhum pedido ainda',
              subtitle: filtered
                  ? 'Ajuste a busca.'
                  : 'Gere um PIX na vitrine para ver pedidos aqui.',
              action: filtered
                  ? FxEmptyAction(label: 'Limpar busca', onTap: _clearQuery)
                  : null,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primary,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          FxSettingsLayout.pageInset,
          TokensStrip.s6 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        itemCount: visible.length,
        itemBuilder: (context, index) {
          final pedido = visible[index];
          return FxSatelliteListTile(
            title: lojaPedidoLabel(
              buyerNome: pedido.buyerNome,
              buyerEmail: pedido.buyerEmail,
            ),
            subtitle: Text(
              lojaPedidoSubtitle(
                buyerNome: pedido.buyerNome,
                buyerEmail: pedido.buyerEmail,
                status: pedido.status,
              ),
            ),
            trailing: Text(
              formatBrlCurrency(pedido.valor),
              style: FocuxHubTypography.bodyMuted(
                color: fxScreenMute(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () => _abrirPedido(pedido),
          );
        },
      ),
    );
  }
}
