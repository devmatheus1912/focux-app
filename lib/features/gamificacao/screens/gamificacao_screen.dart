import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/gamificacao_repository.dart';

final _gamificacaoRepoProvider = Provider<GamificacaoRepository>(
  (ref) => GamificacaoRepository(ref.read(apiClientProvider)),
);

final gamificacaoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final data = await ref.read(_gamificacaoRepoProvider).getGamificacao();
  return {
    'streakAtual': data.streak.streakAtual,
    'streakRecorde': data.streak.streakMaximo,
    'totalTreinos': data.totalTreinos,
    'prsEsseMes': 4,
    'aderencia': 92,
  };
});

class GamificacaoScreen extends ConsumerWidget {
  const GamificacaoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? EagleTokens.darkBg : EagleTokens.paper;
    final cardBg = dark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = dark ? EagleTokens.darkLine : EagleTokens.line;
    final brand = Theme.of(context).colorScheme.primary;
    final brandSofter = BrandPalette.softer(brand, dark: dark);

    final async = ref.watch(gamificacaoProvider);

    final badges = [
      {
        'tipo': 'STREAK_10',
        'icon': '🔥',
        'label': 'Sequência 10d',
        'cor': const Color(0xFFE2B46F),
        'earned': true,
      },
      {
        'tipo': 'PR_CARGA',
        'icon': '💪',
        'label': 'PR de carga',
        'cor': brand,
        'earned': true,
      },
      {
        'tipo': 'FREQ_100',
        'icon': '⭐',
        'label': '100% semana',
        'cor': const Color(0xFF2BB673),
        'earned': true,
      },
      {
        'tipo': 'FIRST_AI',
        'icon': '✨',
        'label': 'Usou a IA',
        'cor': const Color(0xFF9B7AFF),
        'earned': true,
      },
      {
        'tipo': 'LOCK1',
        'icon': '🏆',
        'label': '50 treinos',
        'cor': EagleTokens.inkMute,
        'earned': false,
      },
      {
        'tipo': 'LOCK2',
        'icon': '🎯',
        'label': 'Meta atingida',
        'cor': EagleTokens.inkMute,
        'earned': false,
      },
    ];

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 54),

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
                loading:
                    () => _StreakHeroStatic(
                      dark: dark,
                      brand: brand,
                      streak: 12,
                      recorde: 18,
                      totalTreinos: 58,
                      prs: 4,
                      aderencia: 92,
                    ),
                error:
                    (_, __) => _StreakHeroStatic(
                      dark: dark,
                      brand: brand,
                      streak: 12,
                      recorde: 18,
                      totalTreinos: 58,
                      prs: 4,
                      aderencia: 92,
                    ),
                data:
                    (data) => _StreakHeroStatic(
                      dark: dark,
                      brand: brand,
                      streak: (data['streakAtual'] as num?)?.toInt() ?? 12,
                      recorde: (data['streakRecorde'] as num?)?.toInt() ?? 18,
                      totalTreinos:
                          (data['totalTreinos'] as num?)?.toInt() ?? 58,
                      prs: (data['prsEsseMes'] as num?)?.toInt() ?? 4,
                      aderencia: (data['aderencia'] as num?)?.toInt() ?? 92,
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
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: line),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: line),
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
                              ScaffoldMessenger.of(context).showSnackBar(
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
                        ScaffoldMessenger.of(context).showSnackBar(
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
              dark ? [brandDeep, const Color(0xFF0D0F14)] : [brand, brandDeep],
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
