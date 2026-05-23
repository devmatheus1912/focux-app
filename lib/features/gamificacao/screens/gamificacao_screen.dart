import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/gamificacao_repository.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import 'package:focux_app/core/widgets/fx_rive_player.dart';

final _gamificacaoRepoProvider = Provider<GamificacaoRepository>(
  (ref) => GamificacaoRepository(ref.read(apiClientProvider)),
);

final gamificacaoProvider = FutureProvider<GamificacaoData>((ref) async {
  return ref.read(_gamificacaoRepoProvider).getGamificacao();
});

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
      'cor': EagleTokens.inkMute,
      'earned': false,
    });
  }

  return tiles;
}

class GamificacaoScreen extends ConsumerWidget {
  const GamificacaoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = dark ? EagleTokens.darkLine : EagleTokens.line;
    final brand = Theme.of(context).colorScheme.primary;
    final brandSofter = BrandPalette.softer(brand, dark: dark);

    final async = ref.watch(gamificacaoProvider);
    final badges = async.maybeWhen(
      data: (data) => _buildBadgeTiles(data, brand),
      orElse: () => _buildBadgeTiles(
        GamificacaoData(
          streak: Streak(streakAtual: 0, streakMaximo: 0),
          badges: const [],
          totalTreinos: 0,
        ),
        brand,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: FxShellAppBar(
        title: 'Minha evolução',
        onBack: () => safePopOrGo(context, '/dashboard/personal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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

            // Streak hero card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: async.when(
                loading: () => _StreakHeroStatic(
                  dark: dark,
                  brand: brand,
                  streak: 0,
                  recorde: 0,
                  totalTreinos: 0,
                  prs: 0,
                  aderencia: 0,
                ),
                error: (_, __) => _StreakHeroStatic(
                  dark: dark,
                  brand: brand,
                  streak: 0,
                  recorde: 0,
                  totalTreinos: 0,
                  prs: 0,
                  aderencia: 0,
                ),
                data: (data) => _StreakHeroStatic(
                  dark: dark,
                  brand: brand,
                  streak: data.streak.streakAtual,
                  recorde: data.streak.streakMaximo,
                  totalTreinos: data.totalTreinos,
                  prs: data.prsEsseMes,
                  aderencia: data.aderenciaPercent,
                ),
              ),
            ),

            // Conquistas title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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

            // Badges grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                                    : EagleTokens.lineSoft),
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

            // Referral card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: fxListCardDecoration(
                  context,
                  accent: brand,
                  radius: 20,
                ),
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
                      'Seu amigo ganha 20% de desconto no primeiro mês!',
                      style: TextStyle(color: mute, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            dark ? brand.withValues(alpha: 0.14) : brandSofter,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: brand.withValues(alpha: dark ? 0.26 : 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'FOCUX20',
                            style: GoogleFonts.jetBrainsMono(
                              color: brand,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 16 * 0.12,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                const ClipboardData(text: 'FOCUX20'),
                              );
                              FeedbackHelper.showSnackBar(
                                context,
                                const SnackBar(
                                  content: Text('Código copiado!'),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: brand,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Copiar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                          const ClipboardData(
                            text:
                                'Use meu código FOCUX20 e ganhe 20% de desconto no primeiro mês do Focux Personal! https://focux.app',
                          ),
                        );
                        FeedbackHelper.showSnackBar(
                          context,
                          const SnackBar(
                            content: Text(
                              'Convite copiado! Cole em qualquer app pra compartilhar.',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color:
                              dark
                                  ? const Color(0x0FFFFFFF)
                                  : EagleTokens.lineSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: line),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share_outlined, color: mute, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Compartilhar',
                              style: TextStyle(
                                color: ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          // subtle grid bg
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: CustomPaint(painter: _GridPainter()),
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
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                        const Text(
                          'Sequência ativa!',
                          style: TextStyle(
                            color: Color(0xBFFFFFFF),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'RECORDE',
                          style: TextStyle(
                            color: Color(0x99FFFFFF),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '${recorde}d',
                          style: const TextStyle(
                            color: Colors.white,
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
                            style: const TextStyle(
                              color: Color(0x99FFFFFF),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            item.$2,
                            style: const TextStyle(
                              color: Colors.white,
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
                          color: Colors.white24,
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
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
  bool shouldRepaint(_) => false;
}
