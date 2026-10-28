import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/brand_style.dart';
import '../../../core/theme/brand_tint.dart';
import '../../../core/theme/curated_brand_palettes.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../dashboard/utils/aluno_today_action.dart';
import '../../dashboard/widgets/aluno_capa_banner.dart';
import '../../dashboard/widgets/aluno_personal_card.dart';
import '../../dashboard/widgets/aluno_today_focus_card.dart';

/// Prévia da Home do aluno com os mesmos widgets do app, na paleta e no estilo
/// escolhidos. Muda ao vivo enquanto o personal mexe nas opções.
class IdentidadePreviaApp extends StatelessWidget {
  const IdentidadePreviaApp({
    super.key,
    required this.palette,
    required this.estilo,
    required this.escuro,
    required this.nomePersonal,
    this.slogan,
    this.logoUrl,
    this.capaUrl,
  });

  final CuratedBrandPalette palette;
  final BrandStyle estilo;
  final bool escuro;
  final String nomePersonal;
  final String? slogan;
  final String? logoUrl;
  final String? capaUrl;

  @override
  Widget build(BuildContext context) {
    final brilho = escuro ? Brightness.dark : Brightness.light;
    final tema = ThemeData(
      useMaterial3: true,
      brightness: brilho,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.primary,
        primary: palette.primary,
        secondary: palette.secondary,
        brightness: brilho,
      ),
    );
    final fundo =
        escuro
            ? BrandPalette.fundoEscuroReferencia
            : BrandPalette.fundoClaroReferencia;

    return Semantics(
      label: 'Prévia da home do aluno',
      excludeSemantics: true,
      child: ExcludeFocus(
        child: IgnorePointer(
          child: Theme(
            data: tema,
            child: BrandTint(
              estilo: estilo,
              primaria: palette.primary,
              secundaria: palette.secondary,
              child: Builder(
                builder: (context) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(TokensStrip.rCard),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        // Tom sólido da marca, sem degradê.
                        color:
                            estilo.tingeFundo
                                ? Color.lerp(
                                  fundo,
                                  palette.primary,
                                  escuro ? 0.10 : 0.04,
                                )
                                : fundo,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if ((capaUrl ?? '').trim().isNotEmpty) ...[
                              AlunoCapaBanner(url: capaUrl, altura: 72),
                              const SizedBox(height: 10),
                            ],
                            AlunoTodayFocusCard(
                              action: const AlunoTodayAction(
                                mode: AlunoTodayMode.workoutReady,
                                route: '/',
                                treinoNome: 'Peito e tríceps',
                                exerciseCount: 6,
                              ),
                              hoje: DateTime(2026, 10, 27),
                              isDark: escuro,
                              onAction: () {},
                              assinatura: nomePersonal,
                              fundoMarca:
                                  estilo.usaGradiente
                                      ? BrandPalette.gradient(
                                        palette.primary,
                                        palette.secondary,
                                        dark: escuro,
                                      )
                                      : null,
                            ),
                            const SizedBox(height: 8),
                            AlunoPersonalCard(
                              nome:
                                  nomePersonal.trim().isEmpty
                                      ? 'Seu nome'
                                      : nomePersonal,
                              slogan: slogan,
                              logoUrl: logoUrl,
                              onConversar: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
