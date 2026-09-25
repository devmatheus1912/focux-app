import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/ranking_repository.dart';
import '../utils/ranking_display.dart';

final _repoProvider = Provider(
  (ref) => RankingRepository(ref.read(apiClientProvider)),
);

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  var _query = '';
  List<RankingItem> _items = [];
  var _page = 0;
  var _hasMore = false;
  var _total = 0;
  var _loading = true;
  var _carregandoMais = false;
  String? _erro;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final next = value.trim();
      if (next == _query) return;
      _query = next;
      _carregar();
    });
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final page = await ref.read(_repoProvider).listar(q: _query);
      if (!mounted) return;
      setState(() {
        _items = page.content;
        _page = page.page ?? 0;
        _hasMore = page.hasNext;
        _total = page.totalElements ?? page.content.length;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
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
      final next = await ref
          .read(_repoProvider)
          .listar(page: _page + 1, q: _query);
      if (!mounted) return;
      final seen = _items.map((i) => i.personalId).toSet();
      setState(() {
        _items = [
          ..._items,
          ...next.content.where((i) => seen.add(i.personalId)),
        ];
        _page = next.page ?? _page + 1;
        _hasMore = next.hasNext;
        _total = next.totalElements ?? _total;
        _carregandoMais = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregandoMais = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return fxScreenA11yScope(
      label: 'Ranking de personais',
      child: PopScope(
        canPop: !keyboardOpen && !_searchFocus.hasFocus,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (keyboardOpen || _searchFocus.hasFocus) {
            FxKeyboardDismissScope.dismiss();
            return;
          }
          FxKeyboardDismissScope.dismiss();
          safePopOrGo(context, '/dashboard/personal');
        },
        child: FxShellScaffold(
        useMesh: true,
        dismissKeyboard: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Ranking de personais',
          subtitle: FxHubFreshness.joinCount(
            rankingCountLabel(_loading ? 0 : _total),
            FxHubFreshness.fromFetchedAt(_fetchedAt),
          ),
          onBack: () {
            FxKeyboardDismissScope.dismiss();
            safePopOrGo(context, '/dashboard/personal');
          },
          actions: [
            FxHelpIconButton(
              tooltip: 'Como ler o ranking',
              onTap: () => showFxHelpSheet(
                context,
                title: 'Ranking',
                subtitle: 'Quem tem mais alunos ativos neste mês.',
                tips: const [
                  FxHelpTip('Como calculamos', rankingComoCalculamos),
                  FxHelpTip(
                    'Pódio',
                    'Os 3 primeiros levam desconto na assinatura Focux.',
                  ),
                  FxHelpTip(
                    'Como ganhar',
                    'Mais alunos ativos sobem a posição. O desconto do pódio entra na assinatura Focux.',
                  ),
                ],
              ),
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
            : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TokensStrip.s4,
                    TokensStrip.s2,
                    TokensStrip.s4,
                    TokensStrip.s2,
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    textInputAction: TextInputAction.search,
                    onChanged: _onQueryChanged,
                    onSubmitted: (value) {
                      _debounce?.cancel();
                      final next = value.trim();
                      if (next == _query && _items.isNotEmpty) return;
                      _query = next;
                      _carregar();
                    },
                    onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
                    decoration: FxInputDeco.build(context, 'Buscar personal'),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
              color: primary,
              onRefresh: _carregar,
              child: _items.isEmpty
                  ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      const SizedBox(height: 48),
                      FxEmptyState(
                        icon: 'star',
                        title: rankingSearchEmptyTitle(_query),
                        subtitle: rankingSearchEmptySubtitle(_query),
                        action: _query.isEmpty
                            ? FxEmptyAction(
                          label: 'Ver alunos',
                          onTap: () {
                            AnalyticsService.instance.track(
                              ProductEvents.alunosViewed,
                            );
                            goPersonalShellTab(context, '/alunos');
                          },
                        )
                            : null,
                      ),
                    ],
                  )
                  : FxContentWidthLimiter(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        TokensStrip.s4,
                        TokensStrip.s4,
                        TokensStrip.s4,
                        TokensStrip.s4 +
                            MediaQuery.viewInsetsOf(context).bottom,
                      ),
                      itemCount: _items.length + (_hasMore ? 2 : 1),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final first = _items.first;
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: TokensStrip.s3,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _RankingFocusCard(
                                  first: first,
                                  isDark: isDark,
                                  onAlunos: () {
                                    AnalyticsService.instance.track(
                                      ProductEvents.alunosViewed,
                                    );
                                    goPersonalShellTab(context, '/alunos');
                                  },
                                  onAssinatura: () =>
                                      goPersonalShellTab(context, '/assinatura'),
                                ),
                                const SizedBox(height: TokensStrip.s4),
                                const DashboardSectionHeader(
                                  title: 'Classificação',
                                ),
                              ],
                            ),
                          );
                        }
                        if (_hasMore && index == _items.length + 1) {
                          return FxSatelliteListTile(
                            title: _carregandoMais
                                ? 'Carregando…'
                                : 'Carregar mais',
                            onTap: _carregandoMais ? null : _carregarMais,
                          );
                        }
                        final item = _items[index - 1];
                        return FxSatelliteListTile(
                          title: item.nome,
                          subtitle: Text(
                            rankingItemSubtitle(
                              item.totalAlunosAtivos,
                              item.descontoPercentual,
                            ),
                          ),
                          trailing: Text(
                            rankingPosicaoLabel(item.posicao),
                            style: FocuxHubTypography.bodyMuted(
                              color: item.posicao <= 3
                                  ? Theme.of(context).colorScheme.primary
                                  : fxScreenMute(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          accent: item.posicao == 1
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        );
                      },
                    ),
                  ),
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }
}

class _RankingFocusCard extends StatelessWidget {
  const _RankingFocusCard({
    required this.first,
    required this.isDark,
    required this.onAlunos,
    required this.onAssinatura,
  });

  final RankingItem first;
  final bool isDark;
  final VoidCallback onAlunos;
  final VoidCallback onAssinatura;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forBrightness(context, isDark);
    final desconto = rankingDescontoLabel(first.descontoPercentual);
    return FxStripCard(
      emphasize: true,
      semanticsLabel:
          '${rankingPosicaoLabel(first.posicao)} ${first.nome}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pódio', style: FocuxHubTypography.chip(chrome.mute)),
          const SizedBox(height: 6),
          Text(
            rankingPosicaoLabel(first.posicao),
            style: FocuxHubTypography.kpi(
              color: chrome.ink,
              fontSize: FocuxHubTypography.metricLg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            first.nome,
            style: FocuxHubTypography.body(
              color: chrome.ink,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            desconto.isEmpty
                ? rankingAlunosLabel(first.totalAlunosAtivos)
                : '$desconto · ${rankingAlunosLabel(first.totalAlunosAtivos)}',
            style: FocuxHubTypography.body(color: chrome.mute),
          ),
          const SizedBox(height: TokensStrip.s3),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: [
              FxActionChip(
                label: 'Crescer base',
                accent: Theme.of(context).colorScheme.primary,
                isDark: isDark,
                onPressed: onAlunos,
              ),
              FxActionChip(
                label: 'Assinatura',
                accent: Theme.of(context).colorScheme.primary,
                isDark: isDark,
                onPressed: onAssinatura,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
