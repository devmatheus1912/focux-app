import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../data/pacote_repository.dart';
import '../providers/pacotes_provider.dart';
import '../utils/pacote_display.dart';
import '../widgets/novo_pacote_sheet.dart';
import '../widgets/pacotes_storefront_widgets.dart';

class PacotesScreen extends ConsumerStatefulWidget {
  const PacotesScreen({super.key});

  @override
  ConsumerState<PacotesScreen> createState() => _PacotesScreenState();
}

class _PacotesScreenState extends ConsumerState<PacotesScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  List<Pacote> _pacotes = const [];
  var _loading = true;
  String? _erro;
  String? _slug;
  DateTime? _fetchedAt;
  var _query = '';
  var _chip = PacoteChip.todos;

  @override
  void initState() {
    super.initState();
    _carregar();
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
    safePopOrGo(context, '/financeiro');
  }

  List<Pacote> get _visible => _pacotes
      .where(
        (p) => pacoteMatches(
          titulo: p.titulo,
          descricao: p.descricao,
          destaque: p.destaque,
          query: _query,
          chip: _chip,
        ),
      )
      .toList();

  Future<void> _carregar({bool force = false}) async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      if (force) invalidatePacotesCaches(ref);
      final home = await ref.read(pacotesHomeProvider.future);
      if (!mounted) return;
      setState(() {
        _pacotes = home.pacotes;
        _slug = home.perfil?.slug;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = friendlyError(e);
        });
      }
    }
  }

  Future<void> _novoPacote() async {
    HapticFeedback.selectionClick();
    final created = await showNovoPacoteSheet(
      context,
      repo: ref.read(pacoteRepositoryProvider),
    );
    if (!mounted || !created) return;
    FeedbackHelper.showSuccess(context, 'Plano criado!');
    await _carregar(force: true);
  }

  Future<void> _desativar(Pacote pacote) async {
    final ok = await confirmDesativarPacote(context, pacote.titulo);
    if (!ok || !mounted) return;
    try {
      await ref.read(pacoteRepositoryProvider).desativar(pacote.id);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      FeedbackHelper.showSuccess(context, 'Plano desativado.');
      await _carregar(force: true);
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  void _copiarLink() => copyStorefrontLink(context, _slug);

  void _verVitrine() => openStorefrontPreview(context, _slug);

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final visible = _visible;

    return fxScreenA11yScope(
      label: 'Planos & link de vendas',
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
            title: 'Planos & link de vendas',
            subtitle: FxHubFreshness.joinCount(
              pacoteCountLabel(visible.length),
              FxHubFreshness.fromFetchedAt(_fetchedAt),
            ),
            onBack: _leave,
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar planos',
                onTap: () => showFxHelpSheet(
                  context,
                  title: 'Planos',
                  subtitle: 'Preço e link para o aluno comprar no WhatsApp.',
                  tips: const [
                    FxHelpTip(
                      'Novo plano',
                      'O botão de baixo publica na sua página de vendas.',
                    ),
                    FxHelpTip(
                      'Link',
                      'Copie o link do card da vitrine, não do topo.',
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
                      hintText: 'Buscar plano',
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
                    for (final chip in PacoteChip.values)
                      FxToggleChip(
                        label: pacoteChipLabel(chip),
                        selected: _chip == chip,
                        isDark: chrome.isDark,
                        onTap: () {
                          if (_chip == chip) return;
                          setState(() => _chip = chip);
                        },
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const PacotesStorefrontSkeleton()
                    : _erro != null
                    ? PacotesLoadErrorState(
                        message: _erro,
                        onRetry: () => _carregar(force: true),
                      )
                    : FxContentWidthLimiter(child: _buildList(visible)),
              ),
              if (!_loading && _erro == null)
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
                      label: 'Novo plano',
                      onPressed: _novoPacote,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<Pacote> visible) {
    final primary = Theme.of(context).colorScheme.primary;
    final slug = _slug;
    final hasLink = slug != null && slug.isNotEmpty;
    final filtered =
        _query.trim().isNotEmpty || _chip != PacoteChip.todos;
    final linkCount = hasLink ? 1 : 0;
    final overviewCount = visible.isNotEmpty ? 2 : 0;
    final base = 1 + linkCount + overviewCount;
    final itemCount = base + (visible.isEmpty ? 1 : visible.length);

    return RefreshIndicator(
      color: primary,
      onRefresh: () => _carregar(force: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          FxSettingsLayout.pageInset,
          TokensStrip.s6 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == 0) return const PacotesComoFuncionaCard();
          if (hasLink && index == 1) {
            return StorefrontLinkCard(
              slug: slug,
              onCopy: _copiarLink,
              onPreview: _verVitrine,
            );
          }
          if (visible.isNotEmpty) {
            final overviewIndex = 1 + linkCount;
            if (index == overviewIndex) {
              return PacotesOverviewStrip(pacotes: visible);
            }
            if (index == overviewIndex + 1) {
              return Padding(
                padding: const EdgeInsets.only(
                  left: 2,
                  bottom: TokensStrip.s2,
                ),
                child: Text(
                  'Seus planos (aparecem no link acima)',
                  style: TextStyle(
                    color: fxScreenMute(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              );
            }
          }
          if (visible.isEmpty) {
            return filtered
                ? FxEmptyState(
                    icon: 'search',
                    title: 'Nenhum plano encontrado',
                    subtitle: 'Ajuste a busca ou o filtro.',
                    action: FxEmptyAction(
                      label: 'Limpar filtros',
                      onTap: _clearQuery,
                    ),
                  )
                : PacotesEmptyState(onCreate: _novoPacote);
          }
          final pacote = visible[index - base];
          return PacoteStorefrontCard(
            pacote: pacote,
            entranceIndex: index - base,
            onDelete: () => _desativar(pacote),
          );
        },
      ),
    );
  }
}
