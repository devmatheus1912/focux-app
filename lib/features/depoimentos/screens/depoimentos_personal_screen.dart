import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/widgets/aluno_avatar.dart';
import '../data/depoimento_repository.dart';
import '../utils/depoimento_display.dart';

class DepoimentosPersonalScreen extends ConsumerStatefulWidget {
  const DepoimentosPersonalScreen({super.key});
  @override
  ConsumerState<DepoimentosPersonalScreen> createState() => _State();
}

class _State extends ConsumerState<DepoimentosPersonalScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  List<DepoimentoModel> _items = const [];
  var _loading = true;
  String? _erro;
  DateTime? _fetchedAt;
  var _query = '';
  var _chip = DepoimentoChip.todos;
  var _page = 0;
  var _hasMore = false;
  var _total = 0;
  var _loadingMore = false;

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
      _load();
    });
  }

  void _clearQuery() {
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    setState(() => _query = '');
    _load();
  }

  void _leave() {
    FxKeyboardDismissScope.dismiss();
    safePopOrGo(context, '/perfil/ferramentas');
  }

  bool? get _aprovadoFiltro => switch (_chip) {
    DepoimentoChip.todos => null,
    DepoimentoChip.pendentes => false,
    DepoimentoChip.aprovados => true,
  };

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final pagina = await DepoimentoRepository(
        ref.read(apiClientProvider),
      ).listarParaPersonalPagina(
        q: _query,
        aprovado: _aprovadoFiltro,
      );
      if (!mounted) return;
      setState(() {
        _items = pagina.content;
        _page = pagina.page ?? 0;
        _hasMore = pagina.hasNext;
        _total = pagina.totalElements ?? pagina.content.length;
        _loading = false;
        _fetchedAt = DateTime.now();
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
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final pagina = await DepoimentoRepository(
        ref.read(apiClientProvider),
      ).listarParaPersonalPagina(
        page: _page + 1,
        q: _query,
        aprovado: _aprovadoFiltro,
      );
      if (!mounted) return;
      final seen = _items.map((d) => d.id).toSet();
      setState(() {
        _items = [
          ..._items,
          ...pagina.content.where((d) => seen.add(d.id)),
        ];
        _page = pagina.page ?? (_page + 1);
        _hasMore = pagina.hasNext;
        _total = pagina.totalElements ?? _items.length;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _action(DepoimentoModel item, {required bool aprovado}) async {
    if (!aprovado) {
      final ok = await showFxConfirmSheet(
        context,
        title: item.aprovado ? 'Remover depoimento?' : 'Rejeitar depoimento?',
        message: item.aprovado
            ? 'Ele some da prova social do perfil.'
            : 'O aluno não vê este texto publicado.',
        icon: Icons.close_rounded,
        confirmLabel: item.aprovado ? 'Remover' : 'Rejeitar',
        destructive: true,
      );
      if (!ok || !mounted) return;
    }
    try {
      await DepoimentoRepository(
        ref.read(apiClientProvider),
      ).aprovar(item.id, aprovado: aprovado);
      await _load();
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  List<DepoimentoModel> get _visible => _items;

  void _openItem(DepoimentoModel item) {
    final chrome = ShellChrome.of(context);
    showFxHomeSheet<void>(
      context,
      builder: (sheetContext) => FxHomeSheetSurface(
        isDark: chrome.isDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FxHomeSheetHandle(isDark: chrome.isDark),
            FxHomeSheetHeader(
              isDark: chrome.isDark,
              leading: Icon(
                Icons.star_outline_rounded,
                color: Theme.of(sheetContext).colorScheme.primary,
                size: 18,
              ),
              title: item.nomeAluno,
              subtitle: depoimentoStatusLabel(aprovado: item.aprovado),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                0,
                FxSettingsLayout.pageInset,
                TokensStrip.s2,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < 5; i++)
                    Icon(
                      i < item.nota.clamp(1, 5)
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 18,
                      color: EagleTokens.goldStar,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    depoimentoNotaLabel(item.nota),
                    style: FocuxHubTypography.bodyMuted(
                      color: chrome.mute,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                0,
                FxSettingsLayout.pageInset,
                TokensStrip.s3,
              ),
              child: Text(item.texto, style: TextStyle(color: chrome.ink)),
            ),
            if (!item.aprovado)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  0,
                  FxSettingsLayout.pageInset,
                  TokensStrip.s2,
                ),
                child: FxLiquidPrimaryButton(
                  label: 'Aprovar',
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _action(item, aprovado: true);
                  },
                ),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(sheetContext);
                _action(item, aprovado: false);
              },
              child: Text(item.aprovado ? 'Remover' : 'Rejeitar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final visible = _visible;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return fxScreenA11yScope(
      label: 'Depoimentos',
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
          appBar: FxShellAppBar(
            title: 'Depoimentos',
            subtitle: FxHubFreshness.joinCount(
              depoimentoCountLabel(_total),
              FxHubFreshness.fromFetchedAt(_fetchedAt),
            ),
            onBack: _leave,
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar depoimentos',
                onTap: () => showFxHelpSheet(
                  context,
                  title: 'Depoimentos',
                  subtitle: 'Prova social que o aluno envia pelo app dele.',
                  tips: const [
                    FxHelpTip(
                      'Aprovar',
                      'Toque no depoimento. Pendentes entram no perfil público.',
                    ),
                    FxHelpTip(
                      'Filtro',
                      'Pendentes primeiro quando você precisa decidir.',
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
                    accent: primary,
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
                      hintText: 'Buscar aluno ou texto',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: primary,
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
                    for (final chip in DepoimentoChip.values)
                      FxToggleChip(
                        label: depoimentoChipLabel(chip),
                        selected: _chip == chip,
                        isDark: chrome.isDark,
                        onTap: () {
                          if (_chip == chip) return;
                          setState(() => _chip = chip);
                          _load();
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
                    : _erro != null
                    ? FxErrorState(
                        chromeOnDark: chrome.isDark,
                        primary: primary,
                        message: _erro!,
                        onRetry: _load,
                        title: 'Não conseguimos carregar os depoimentos',
                      )
                    : FxContentWidthLimiter(child: _buildList(visible)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<DepoimentoModel> visible) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    if (visible.isEmpty) {
      final filtered = _query.trim().isNotEmpty || _chip != DepoimentoChip.todos;
      return RefreshIndicator(
        color: primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            FxEmptyState(
              icon: filtered ? 'search' : 'star',
              title: filtered
                  ? 'Nenhum depoimento encontrado'
                  : 'Nenhum depoimento ainda',
              subtitle: filtered
                  ? 'Ajuste a busca ou o filtro.'
                  : 'Quando os alunos enviarem, eles aparecem aqui para aprovação.',
              action: filtered
                  ? FxEmptyAction(label: 'Limpar filtros', onTap: _clearQuery)
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
        itemCount: visible.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (_hasMore && i == visible.length) {
            return FxSatelliteListTile(
              title: _loadingMore ? 'Carregando…' : 'Carregar mais',
              onTap: _loadingMore ? null : _carregarMais,
            );
          }
          final d = visible[i];
          return FxStaggerItem(
            index: i,
            child: FxSatelliteListTile(
              title: d.nomeAluno,
              subtitle: Text(
                d.texto,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              leading: AlunoAvatar(
                name: d.nomeAluno,
                photoUrl: d.fotoAluno,
                variant: AlunoAvatarVariant.strip,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: EagleTokens.goldStar,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        depoimentoNotaLabel(d.nota),
                        style: FocuxHubTypography.bodyMuted(
                          color: chrome.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    depoimentoStatusLabel(aprovado: d.aprovado),
                    style: FocuxHubTypography.bodyMuted(
                      color: d.aprovado ? EagleTokens.good : chrome.mute,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              accent: d.aprovado ? null : primary,
              onTap: () => _openItem(d),
            ),
          );
        },
      ),
    );
  }
}
