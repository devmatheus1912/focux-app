import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../dashboard/widgets/dashboard_error_state.dart';
import '../data/ranking_repository.dart';

final rankingProvider = FutureProvider.autoDispose<List<RankingItem>>((
  ref,
) async {
  return RankingRepository(ref.read(apiClientProvider)).listarTop();
});

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(rankingProvider);
    final theme = Theme.of(context);

    return fxScreenA11yScope(
      label: 'Ranking de Personais',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Ranking de Personais',
          subtitle: 'Pódio do mês e classificação geral',
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
        ),
        body: rankingAsync.when(
          loading: () => const SkeletonList(count: 5),
          error:
              (e, _) => DashboardErrorState(
                chromeOnDark: ShellChrome.of(context).isDark,
                primary: Theme.of(context).colorScheme.primary,
                message: friendlyError(e),
                onRetry: () => ref.invalidate(rankingProvider),
              ),
          data: (ranking) {
            final top3 = ranking.where((r) => r.posicao <= 3).toList();
            final demais = ranking.where((r) => r.posicao > 3).toList();

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(rankingProvider),
              child: ListView(
                padding: const EdgeInsets.all(TokensStrip.s4),
                children: [
                  // Pódio
                  if (top3.isNotEmpty) ...[
                    Text('Pódio do Mês', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (top3.length >= 2)
                          _PodioCard(
                            item: top3[1],
                            medalha: '🥈',
                            alturaBase: 80,
                          ),
                        if (top3.isNotEmpty)
                          _PodioCard(
                            item: top3[0],
                            medalha: '🥇',
                            alturaBase: 110,
                          ),
                        if (top3.length >= 3)
                          _PodioCard(
                            item: top3[2],
                            medalha: '🥉',
                            alturaBase: 60,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      margin: EdgeInsets.all(TokensStrip.s4),
                      padding: const EdgeInsets.all(TokensStrip.s4),
                      decoration: BoxDecoration(
                        color: EagleTokens.goldSoft,
                        borderRadius: BorderRadius.circular(TokensStrip.rCard),
                        border: Border.all(color: const Color(0xFFFFE58A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.card_giftcard,
                            color: Color(0xFF8A5A12),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Prêmio do mês',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF8A5A12),
                                  ),
                                ),
                                Text(
                                  '1º lugar: 20% off • 2º lugar: 15% off • 3º lugar: 10% off',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF8A5A12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s4),
                  ],

                  // Lista completa
                  if (demais.isNotEmpty) ...[
                    Text(
                      'Classificação geral',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...demais.map((item) => _RankingTile(item: item)),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PodioCard extends StatelessWidget {
  final RankingItem item;
  final String medalha;
  final double alturaBase;

  const _PodioCard({
    required this.item,
    required this.medalha,
    required this.alturaBase,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final isGold = item.posicao == 1;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Text(medalha, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            CircleAvatar(
              radius: 28,
              backgroundColor: isDark ? EagleTokens.darkCard : primarySoft,
              backgroundImage:
                  item.logoUrl != null ? NetworkImage(item.logoUrl!) : null,
              child:
                  item.logoUrl == null
                      ? Text(
                        item.nome.isNotEmpty ? item.nome[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: isDark ? EagleTokens.darkInk : primary,
                          fontSize: 20,
                        ),
                      )
                      : null,
            ),
            const SizedBox(height: 6),
            Text(
              item.nome,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${item.totalAlunosAtivos} alunos',
              style: theme.textTheme.bodySmall?.copyWith(color: primary),
            ),
            Container(
              height: alturaBase,
              decoration: BoxDecoration(
                color:
                    isGold
                        ? null
                        : (isDark ? EagleTokens.darkCard : primarySoft),
                gradient:
                    isGold
                        ? LinearGradient(
                          colors: [primary, BrandPalette.deep(primary)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                        : null,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${item.posicao}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isGold ? Colors.white : primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  final RankingItem item;
  const _RankingTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primarySoft = BrandPalette.soft(
      Theme.of(context).colorScheme.primary,
      dark: isDark,
    );
    final primary = Theme.of(context).colorScheme.primary;
    return FxSatelliteListTile(
      accent: primary,
      title: item.nome,
      titleCase: false,
      subtitle: Text('${item.totalAlunosAtivos} alunos ativos'),
      leading: CircleAvatar(
        backgroundColor: isDark ? EagleTokens.darkCard : primarySoft,
        child: Text(
          '${item.posicao}',
          style: TextStyle(
            color: isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
