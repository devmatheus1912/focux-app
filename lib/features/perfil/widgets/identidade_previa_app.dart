import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/brand_style.dart';
import '../../../core/theme/brand_tint.dart';
import '../../../core/theme/curated_brand_palettes.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_dock.dart';
import '../../../core/widgets/fx_week_strip.dart';
import '../../../l10n/app_localizations.dart';
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

  static const _semana = [
    FxWeekDay(dia: 1, estado: FxWeekDayState.concluido),
    FxWeekDay(dia: 2, estado: FxWeekDayState.treino, hoje: true),
    FxWeekDay(dia: 3, estado: FxWeekDayState.descanso),
    FxWeekDay(dia: 4, estado: FxWeekDayState.treino),
    FxWeekDay(dia: 5, estado: FxWeekDayState.descanso),
    FxWeekDay(dia: 6, estado: FxWeekDayState.treino),
    FxWeekDay(dia: 7, estado: FxWeekDayState.descanso),
  ];

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
    final s = S.of(context);

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
                  final chrome = ShellChrome.forBrightness(context, escuro);
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(TokensStrip.rCard),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: fundo,
                        gradient:
                            estilo.tingeFundo
                                ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color.lerp(
                                      fundo,
                                      palette.primary,
                                      escuro ? 0.32 : 0.10,
                                    )!,
                                    fundo,
                                  ],
                                )
                                : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if ((capaUrl ?? '').trim().isNotEmpty) ...[
                              AlunoCapaBanner(url: capaUrl, altura: 92),
                              const SizedBox(height: 10),
                            ],
                            Text(
                              s.alunoHomeSaudacao('Ana'),
                              style: FocuxHubTypography.sectionTitle(
                                context,
                                color: chrome.ink,
                              ),
                            ),
                            const SizedBox(height: 8),
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
                              semana: _semana,
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
                            const SizedBox(height: 10),
                            FxDock(
                              items: FxDockItems.aluno(s),
                              currentIndex: 0,
                              onTap: (_) {},
                              isDark: escuro,
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
