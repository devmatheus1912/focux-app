import 'package:flutter/material.dart';

import '../../../core/theme/brand_style.dart';
import '../../../core/theme/brand_tint.dart';
import '../../../core/theme/chao_da_marca.dart';
import '../../../core/theme/curated_brand_palettes.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_chao.dart';
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
      // Superfícies do escuro na matiz da marca, como no app do aluno.
      extensions: [tonsEscurosDa(palette.primary)],
    );
    // O mesmo chão do app: matiz da marca no escuro, tinta do Cinematográfico.
    final fundo = FxChao.corPara(
      escuro: escuro,
      primaria: palette.primary,
      tinta: estilo.tingeFundo ? palette.primary : null,
    );

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
                        color: fundo,
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
                              estilo: estilo,
                              primaria: palette.primary,
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
