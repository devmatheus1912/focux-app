import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/gamificacao_repository.dart';
import '../providers/gamificacao_provider.dart';
import 'package:focux_app/core/widgets/fx_rive_player.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import '../../dashboard/widgets/dashboard_error_state.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

const _badgeCatalog = <String, ({String icon, String label})>{
  'STREAK_10': (icon: '🔥', label: 'Sequencia 10d'),
  'PR_CARGA': (icon: '💪', label: 'PR de carga'),
  'FREQUENCIA_100': (icon: '⭐', label: '100% semana'),
  'FIRST_AI': (icon: '✨', label: 'Usou a IA'),
  'TREINOS_50': (icon: '🏆', label: '50 treinos'),
  'META_ATINGIDA': (icon: '🎯', label: 'Meta atingida'),
};

List<Map<String, dynamic>> _buildBadgeTiles(GamificacaoData data, Color brand) {
  final earnedTypes = data.badges.map((b) => b.tipo).toSet();
  final tiles = <Map<String, dynamic>>[];

  for (final badge in data.badges) {
    final meta = _badgeCatalog[badge.tipo];
    tiles.add({
      'tipo': badge.tipo,
      'icon': meta?.icon ?? '🏅',
      'label': meta?.label ?? badge.descricao,
      'cor': brand,
      'earned': true,
    });
  }

  for (final entry in _badgeCatalog.entries) {
    if (earnedTypes.contains(entry.key)) continue;
    tiles.add({
      'tipo': entry.key,
      'icon': entry.value.icon,
      'label': entry.value.label,
      'cor': TokensStrip.textSecondary,
      'earned': false,
    });
  }

  return tiles;
}

class GamificacaoScreen extends ConsumerWidget {
  const GamificacaoScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(gamificacaoProvider);
    await ref.read(gamificacaoProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = dark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final brand = Theme.of(context).colorScheme.primary;
    final async = ref.watch(gamificacaoProvider);

    return fxScreenA11yScope(
      label: 'Minha evolução',
      child: FxShellScaffold(
        constrainWidth: false,
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Minha evolução',
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
        ),
        body: FxContentWidthLimiter(
          child: async.when(
            loading: () => Center(child: FxLoading(color: brand)),
            error:
                (e, _) => RefreshIndicator(
                  color: brand,
                  onRefresh: () => _refresh(ref),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.55,
                        child: DashboardErrorState(
                          chromeOnDark: dark,
                          primary: brand,
                          message: friendlyError(e),
                          onRetry: () => _refresh(ref),
                        ),
                      ),
                    ],
                  ),
                ),
            data:
                (data) => RefreshIndicator(
                  color: brand,
                  onRefresh: () => _refresh(ref),
                  child: _GamificacaoBody(
                    data: data,
                    dark: dark,
                    ink: ink,
                    mute: mute,
                    brand: brand,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

class _GamificacaoBody extends StatelessWidget {
  final GamificacaoData data;
  final bool dark;
  final Color ink;
  final Color mute;
  final Color brand;

  const _GamificacaoBody({
    required this.data,
    required this.dark,
    required this.ink,
    required this.mute,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    final badges = _buildBadgeTiles(data, brand);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensStrip.s5,
              10,
              TokensStrip.s5,
              TokensStrip.s5,
            ),
            child: Text(
              'Minha Evolução',
              style: TextStyle(
                color: ink,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensStrip.s4,
              0,
              TokensStrip.s4,
              TokensStrip.s4,
            ),
            child: _StreakHeroStatic(
              dark: dark,
              brand: brand,
              streak: data.streak.streakAtual,
              recorde: data.streak.streakMaximo,
              totalTreinos: data.totalTreinos,
              prs: data.prsEsseMes,
              aderencia: data.aderenciaPercent,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensStrip.s5,
              0,
              TokensStrip.s5,
              TokensStrip.s3,
            ),
            child: Text(
              'Conquistas',
              style: TextStyle(
                color: ink,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s4),
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.9,
              children:
                  badges.map((b) {
                    final earned = b['earned'] as bool;
                    final cor = b['cor'] as Color;
                    return AnimatedOpacity(
                      opacity: earned ? 1.0 : 0.45,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        decoration: fxListCardDecoration(
                          context,
                          accent: earned ? cor : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (earned)
                                    Positioned.fill(
                                      child: FxRiveBadgeGlow(size: 48),
                                    ),
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color:
                                          earned
                                              ? cor.withValues(alpha: 0.13)
                                              : (dark
                                                  ? const Color(0x0AFFFFFF)
                                                  : TokensStrip.borderDefault),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: ColorFiltered(
                                        colorFilter:
                                            earned
                                                ? const ColorFilter.mode(
                                                  Colors.transparent,
                                                  BlendMode.saturation,
                                                )
                                                : const ColorFilter.matrix([
                                                  0.2126,
                                                  0.7152,
                                                  0.0722,
                                                  0,
                                                  0,
                                                  0.2126,
                                                  0.7152,
                                                  0.0722,
                                                  0,
                                                  0,
                                                  0.2126,
                                                  0.7152,
                                                  0.0722,
                                                  0,
                                                  0,
                                                  0,
                                                  0,
                                                  0,
                                                  1,
                                                  0,
                                                ]),
                                        child: Text(
                                          b['icon'] as String,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Text(
                                b['label'] as String,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s4),
            child: Container(
              padding: const EdgeInsets.all(TokensStrip.s4),
              decoration: fxListCardDecoration(context, accent: brand),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🎁', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Text(
                        'Indique um amigo',
                        style: TextStyle(
                          color: ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Indique outro personal. Quando ele assinar, você ganha 30 dias extras no plano.',
                    style: TextStyle(color: mute, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => context.push('/referral'),
                    child: const Text('Ver meu código de indicação'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakHeroStatic extends StatelessWidget {
  final bool dark;
  final Color brand;
  final int streak, recorde, totalTreinos, prs, aderencia;
  const _StreakHeroStatic({
    required this.dark,
    required this.brand,
    required this.streak,
    required this.recorde,
    required this.totalTreinos,
    required this.prs,
    required this.aderencia,
  });

  @override
  Widget build(BuildContext context) {
    final brandDeep = BrandPalette.deep(brand);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final heroInk = dark ? EagleTokens.darkInk : onPrimary;
    final heroInkMute =
        dark ? EagleTokens.darkInkMute : onPrimary.withValues(alpha: 0.75);
    final heroInkSubtle =
        dark
            ? EagleTokens.darkInkMute.withValues(alpha: 0.72)
            : onPrimary.withValues(alpha: 0.6);
    final heroDivider =
        dark ? EagleTokens.darkLine : onPrimary.withValues(alpha: 0.24);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              dark ? [brandDeep, const Color(0xFF080C10)] : [brand, brandDeep],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: CustomPaint(
                painter: _GridPainter(
                  gridColor:
                      dark
                          ? EagleTokens.darkInk.withValues(alpha: 0.06)
                          : onPrimary.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 52)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$streak dias',
                          style: AppTypography.inter(
                            color: heroInk,
                            fontSize: 44,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                        Text(
                          'Sequência ativa!',
                          style: TextStyle(color: heroInkMute, fontSize: 14),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'RECORDE',
                          style: TextStyle(
                            color: heroInkSubtle,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '${recorde}d',
                          style: TextStyle(
                            color: heroInk,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    for (final item in [
                      ('Total treinos', '$totalTreinos'),
                      ('PRs esse mês', '$prs'),
                      ('Aderência', '$aderencia%'),
                    ]) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$1.toUpperCase(),
                            style: TextStyle(
                              color: heroInkSubtle,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            item.$2,
                            style: TextStyle(
                              color: heroInk,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (item.$1 != 'Aderência')
                        Container(
                          width: 1,
                          height: 36,
                          color: heroDivider,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color gridColor;

  const _GridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = gridColor
          ..strokeWidth = 0.5;
    const step = 26.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.gridColor != gridColor;
}
