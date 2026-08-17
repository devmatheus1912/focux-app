import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/brand/focux_brand_copy.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../alunos/data/aluno_repository.dart';
import '../providers/dashboard_provider.dart';

class AlunoActivationScreen extends ConsumerWidget {
  const AlunoActivationScreen({super.key});

  Future<void> _markSeen(int alunoId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('aluno_activation_seen_$alunoId', true);
  }

  int _profileCompletion(Aluno aluno) {
    final filled =
        [
              aluno.telefone,
              aluno.whatsapp,
              aluno.objetivo,
              aluno.genero,
              aluno.peso?.toString(),
              aluno.altura?.toString(),
              aluno.dataNascimento,
              aluno.fotoUrl,
            ]
            .where(
              (value) => value != null && value.toString().trim().isNotEmpty,
            )
            .length;
    return (filled / 8 * 100).round();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chrome = ShellChrome.forDark(isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final homeAsync = ref.watch(alunoDashboardHomeProvider);

    return fxScreenA11yScope(
      label: 'Boas-vindas',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Boas-vindas',
          leading: const SizedBox(width: 8),
          actions: [
            homeAsync.when(
              data:
                  (home) => TextButton(
                    onPressed: () async {
                      await _markSeen(home.aluno.id);
                      if (context.mounted) {
                        context.go('/dashboard/aluno');
                      }
                    },
                    child: const Text('Pular'),
                  ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        body: homeAsync.when(
          loading: () => const FxLoading(),
          error:
              (e, _) => FxErrorState(
                chromeOnDark: isDark,
                primary: primary,
                title: FocuxMicrocopy.naoFoiPossivelCarregar,
                message: friendlyError(e),
                onRetry: () => ref.invalidate(alunoDashboardHomeProvider),
              ),
          data: (home) {
            final aluno = home.aluno;
            final profileCompletion = _profileCompletion(aluno);

            final steps = <_ActivationStep>[
              _ActivationStep(
                title: 'Completar seu perfil',
                description:
                    'Foto, objetivo, dados corporais e contato deixam o acompanhamento mais inteligente.',
                done: profileCompletion >= 80,
                icon: Icons.person_outline,
                cta: 'Ir para perfil',
                route: '/aluno/perfil',
              ),
              _ActivationStep(
                title: 'Registrar a primeira medida',
                description:
                    'Seu corpo precisa de um ponto de partida para mostrar evolucao de verdade.',
                done: home.medidas.isNotEmpty,
                icon: Icons.straighten_outlined,
                cta: 'Registrar medida',
                route: '/aluno/perfil',
              ),
              _ActivationStep(
                title: 'Fazer o primeiro treino',
                description:
                    'Quando voce treina pelo app, o personal ganha historico para ajustar carga e frequencia.',
                done: home.historico.any(
                  (item) => item.status.toUpperCase() == 'CONCLUIDO',
                ),
                icon: Icons.play_circle_outline,
                cta: 'Abrir treinos',
                route: '/checkin/treinos',
              ),
              _ActivationStep(
                title: 'Abrir seu chat com o personal',
                description:
                    'Duvidas, feedback e alinhamento precisam acontecer no mesmo lugar do treino.',
                done: home.chat.possuiMensagemDoAluno,
                icon: Icons.chat_bubble_outline,
                cta: 'Abrir chat',
                route: '/chat/aluno',
              ),
            ];

            final doneCount = steps.where((item) => item.done).length;
            final percentage = (doneCount / steps.length * 100).round();
            final nextStep = steps.firstWhere(
              (item) => !item.done,
              orElse: () => steps.last,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                TokensStrip.s4,
                TokensStrip.s4,
                TokensStrip.s4,
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.tertiary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bem-vindo, ${aluno.nome.split(' ').first}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          FocuxBrandCopy.alunoActivationHeroSubtitle,
                          style: TextStyle(color: Colors.white70, height: 1.45),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Base inicial pronta',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$doneCount de ${steps.length} marcos concluidos',
                                      style: FocuxHubTypography.pageTitle(
                                        context,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 58,
                                height: 58,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$percentage%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: chrome.listCard(primary: primary),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doneCount == steps.length
                              ? FocuxBrandCopy.alunoActivationReadyTitle
                              : 'Proximo melhor passo',
                          style: TextStyle(
                            color: chrome.mute,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          doneCount == steps.length
                              ? FocuxBrandCopy.alunoActivationReadyBody
                              : nextStep.title,
                          style: FocuxHubTypography.pageTitle(
                            context,
                            color: chrome.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          doneCount == steps.length
                              ? 'Voce pode seguir para a home e usar o app normalmente.'
                              : nextStep.description,
                          style: TextStyle(
                            color: chrome.mute,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s4),
                        Row(
                          children: [
                            Expanded(
                              child: FxLiquidPrimaryButton(
                                icon: Icons.arrow_forward,
                                label:
                                    doneCount == steps.length
                                        ? 'Entrar no app'
                                        : nextStep.cta,
                                onPressed: () async {
                                  await _markSeen(aluno.id);
                                  if (context.mounted) {
                                    context.go(
                                      doneCount == steps.length
                                          ? '/dashboard/aluno'
                                          : nextStep.route,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  ...steps.map(
                    (step) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ActivationStepCard(
                        step: step,
                        chrome: chrome,
                        onTap: () async {
                          await _markSeen(aluno.id);
                          if (context.mounted) {
                            context.go(step.route);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ActivationStep {
  final String title;
  final String description;
  final bool done;
  final IconData icon;
  final String cta;
  final String route;

  const _ActivationStep({
    required this.title,
    required this.description,
    required this.done,
    required this.icon,
    required this.cta,
    required this.route,
  });
}

class _ActivationStepCard extends StatelessWidget {
  final _ActivationStep step;
  final ShellPalette chrome;
  final VoidCallback onTap;

  const _ActivationStepCard({
    required this.step,
    required this.chrome,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = chrome.isDark;

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: chrome.listCard(primary: primary),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  step.done
                      ? EagleTokens.good.withValues(alpha: 0.14)
                      : BrandPalette.soft(primary, dark: isDark),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              step.done ? Icons.check_rounded : step.icon,
              color: step.done ? EagleTokens.good : primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    color: chrome.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  step.description,
                  style: TextStyle(
                    color: chrome.mute,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          step.done
              ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: EagleTokens.good.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Feito',
                  style: TextStyle(
                    color: EagleTokens.good,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
              : TextButton(onPressed: onTap, child: Text(step.cta)),
        ],
      ),
    );
  }
}
