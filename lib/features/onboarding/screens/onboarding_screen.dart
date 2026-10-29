import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/brand/brand_pulse.dart';
import '../../../core/brand/focux_brand_copy.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/hero_teal.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/focux_official_logo.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../auth/widgets/auth_shell.dart';
import '../../auth/widgets/auth_text_link.dart';
import '../data/brand_pulse_repository.dart';

/// Primeira abertura: uma tela por perfil (Personal ou Aluno), com o que o app
/// faz em três linhas e uma ação principal. Sem carrossel.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.socialProofLoader});

  /// Override em testes; null usa [BrandPulseRepository].
  final Future<List<BrandSocialProofItem>> Function()? socialProofLoader;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _personaKey = 'onboarding_persona_v3';

  OnboardingPersona _persona = OnboardingPersona.personal;
  String _socialProofLine = FocuxBrandCopy.onboardingSocialProofFallback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _restoreProgress();
      _loadSocialProof();
    });
  }

  Future<void> _restoreProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_personaKey);
    if (!mounted) return;
    setState(() {
      _persona =
          raw == OnboardingPersona.aluno.name
              ? OnboardingPersona.aluno
              : OnboardingPersona.personal;
    });
  }

  Future<void> _persistPersona() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_personaKey, _persona.name);
  }

  Future<void> _loadSocialProof() async {
    try {
      final loader =
          widget.socialProofLoader ??
          () => BrandPulseRepository(ApiClient()).fetchSocialProof();
      final items = await loader().timeout(const Duration(milliseconds: 2500));
      final line = formatBrandSocialProofLine(items);
      if (!mounted) return;
      if (line != _socialProofLine) {
        setState(() => _socialProofLine = line);
      }
    } catch (_) {
      // Mantém o fallback neutro: a primeira abertura não depende de rede.
    }
  }

  Future<void> _markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done_v3', true);
    await prefs.remove('onboarding_done_v2');
    await prefs.remove('onboarding_done');
    await prefs.remove('onboarding_slide_v3');
  }

  Future<void> _finish() async {
    await _markDone();
    if (!mounted) return;
    context.go(
      _persona == OnboardingPersona.aluno ? '/register/aluno' : '/register',
    );
  }

  Future<void> _goLogin() async {
    await _markDone();
    if (!mounted) return;
    final role = _persona == OnboardingPersona.aluno ? 'aluno' : 'personal';
    context.go('/login?role=$role');
  }

  void _setPersona(OnboardingPersona persona) {
    if (_persona == persona) return;
    HapticFeedback.selectionClick();
    setState(() => _persona = persona);
    _persistPersona();
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = clampedTextScaler(context);
    final reduceMotion = reduceMotionOf(context);
    final aluno = _persona == OnboardingPersona.aluno;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _goLogin();
      },
      child: fxScreenA11yScope(
        label: 'Boas-vindas Focux',
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: Scaffold(
            body: AuthShell(
              child: AuthFormEntrance(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s5,
                          TokensStrip.s3,
                          TokensStrip.s5,
                          TokensStrip.s4,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthRoleToggle(
                              isAluno: aluno,
                              personalLabel:
                                  FocuxBrandCopy.onboardingSouPersonal,
                              alunoLabel: FocuxBrandCopy.onboardingSouAluno,
                              onPersonalTap:
                                  () => _setPersona(OnboardingPersona.personal),
                              onAlunoTap:
                                  () => _setPersona(OnboardingPersona.aluno),
                            ),
                            const SizedBox(height: TokensStrip.s6),
                            Center(
                              child: Semantics(
                                label: 'Focux',
                                image: true,
                                child: FocuxOfficialLogo.full(
                                  width: authLogoWidthFor(
                                    context,
                                    withTagline: true,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: TokensStrip.s5),
                            AnimatedSwitcher(
                              duration:
                                  reduceMotion
                                      ? Duration.zero
                                      : const Duration(milliseconds: 220),
                              child: _Conteudo(
                                key: ValueKey(_persona),
                                persona: _persona,
                                socialProofLine: _socialProofLine,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _Rodape(
                      persona: _persona,
                      onPrimary: _finish,
                      onLogin: _goLogin,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({
    super.key,
    required this.persona,
    required this.socialProofLine,
  });

  final OnboardingPersona persona;
  final String socialProofLine;

  static IconData _icone(OnboardingIcone icone) => switch (icone) {
    OnboardingIcone.treino => Icons.fitness_center_rounded,
    OnboardingIcone.cobranca => Icons.payments_outlined,
    OnboardingIcone.atencao => Icons.notifications_active_outlined,
    OnboardingIcone.video => Icons.play_circle_outline_rounded,
    OnboardingIcone.evolucao => Icons.trending_up_rounded,
    OnboardingIcone.chat => Icons.chat_bubble_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            FocuxBrandCopy.onboardingTitulo(persona),
            textAlign: TextAlign.center,
            style: FocuxHubTypography.pageTitle(
              context,
              color: heroTealInk(),
            ).copyWith(fontSize: 26, height: 1.2, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: TokensStrip.s5),
        for (final beneficio in FocuxBrandCopy.onboardingBeneficios(persona))
          Padding(
            padding: const EdgeInsets.only(bottom: TokensStrip.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.16),
                  ),
                  child: Icon(
                    _icone(beneficio.icone),
                    size: 22,
                    color: heroTealInk(),
                  ),
                ),
                const SizedBox(width: TokensStrip.s3),
                Expanded(
                  child: Text(
                    beneficio.texto,
                    style: FocuxHubTypography.body(
                      color: heroTealInk(),
                    ).copyWith(fontWeight: FontWeight.w600, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: TokensStrip.s2),
        Text(
          socialProofLine,
          textAlign: TextAlign.center,
          style: FocuxHubTypography.bodyMuted(color: heroTealSurface(0.78)),
        ),
      ],
    );
  }
}

class _Rodape extends StatelessWidget {
  const _Rodape({
    required this.persona,
    required this.onPrimary,
    required this.onLogin,
  });

  final OnboardingPersona persona;
  final VoidCallback onPrimary;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s5,
        TokensStrip.s2,
        TokensStrip.s5,
        TokensStrip.s3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxLiquidPrimaryButton(
            label: FocuxBrandCopy.onboardingFinishCta(persona),
            onPressed: onPrimary,
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            FocuxBrandCopy.onboardingFinishHint(persona),
            textAlign: TextAlign.center,
            style: FocuxHubTypography.bodyMuted(color: heroTealSurface(0.78)),
          ),
          const SizedBox(height: TokensStrip.s1),
          AuthFraseComLink(
            frase: FocuxBrandCopy.authExistingAccountLead,
            acao: FocuxBrandCopy.authExistingAccountAction,
            onTap: onLogin,
          ),
        ],
      ),
    );
  }
}
