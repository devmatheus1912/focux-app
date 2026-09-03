import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
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

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final page = await ref.read(_repoProvider).listar();
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
      final next = await ref.read(_repoProvider).listar(page: _page + 1);
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
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: 'Ranking de personais',
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Ranking de personais',
          subtitle: _loading
              ? freshness
              : '${rankingCountLabel(_total)}${freshness == null ? '' : ' · $freshness'}',
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
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
                    'Lista',
                    'A posição não abre o personal. É um placar, não o 360.',
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
            : RefreshIndicator(
              color: primary,
              onRefresh: _carregar,
              child: _items.isEmpty
                  ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 48),
                      FxEmptyState(
                        icon: 'star',
                        title: 'Ranking ainda sem dados',
                        subtitle:
                            'A classificação aparece quando houver personais com alunos ativos.',
                        action: FxEmptyAction(
                          label: 'Ir para o Hoje',
                          onTap: () => goPersonalShellTab(
                            context,
                            '/dashboard/personal',
                          ),
                        ),
                      ),
                    ],
                  )
                  : FxContentWidthLimiter(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.all(TokensStrip.s4),
                      itemCount: _items.length + (_hasMore ? 2 : 1),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: TokensStrip.s3),
                            child: DashboardSectionHeader(title: 'Classificação'),
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
                          subtitle: Text(rankingAlunosLabel(item.totalAlunosAtivos)),
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
    );
  }
}
