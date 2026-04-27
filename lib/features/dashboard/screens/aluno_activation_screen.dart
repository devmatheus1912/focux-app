import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/design_tokens.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../chat/data/chat_repository.dart';
import '../../checkin/data/checkin_repository.dart';
import '../../checkin/providers/checkin_provider.dart';
import '../../evolucao/data/evolucao_repository.dart';
import 'aluno_dashboard_screen.dart';

class AlunoActivationScreen extends ConsumerWidget {
  const AlunoActivationScreen({super.key});

  Future<void> _markSeen(int alunoId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('aluno_activation_seen_$alunoId', true);
  }

  int _profileCompletion(Aluno aluno) {
    final filled = [
      aluno.telefone,
      aluno.whatsapp,
      aluno.objetivo,
      aluno.genero,
      aluno.peso?.toString(),
      aluno.altura?.toString(),
      aluno.dataNascimento,
      aluno.fotoUrl,
    ].where((value) => value != null && value.toString().trim().isNotEmpty).length;
    return (filled / 8 * 100).round();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alunoAsync = ref.watch(alunoMeProvider);
    final medidasAsync = ref.watch(minhasMedidasDashboardProvider);
    final historicoAsync = ref.watch(historicoCheckinProvider);
    final chatAsync = ref.watch(chatAlunoDashboardProvider);

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        title: const Text('Boas-vindas'),
        automaticallyImplyLeading: false,
        actions: [
          alunoAsync.when(
            data: (aluno) => TextButton(
              onPressed: () async {
                await _markSeen(aluno.id);
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
      body: alunoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (aluno) {
          final medidas = medidasAsync.valueOrNull ?? const <MedidaCorporal>[];
          final historico = historicoAsync.valueOrNull ?? const <ExecucaoTreino>[];
          final mensagens = chatAsync.valueOrNull ?? const <ChatMsg>[];
          final profileCompletion = _profileCompletion(aluno);

          final steps = <_ActivationStep>[
            _ActivationStep(
              title: 'Completar seu perfil',
              description: 'Foto, objetivo, dados corporais e contato deixam o acompanhamento mais inteligente.',
              done: profileCompletion >= 80,
              icon: Icons.person_outline,
              cta: 'Ir para perfil',
              route: '/aluno/perfil',
            ),
            _ActivationStep(
              title: 'Registrar a primeira medida',
              description: 'Seu corpo precisa de um ponto de partida para mostrar evolucao de verdade.',
              done: medidas.isNotEmpty,
              icon: Icons.straighten_outlined,
              cta: 'Registrar medida',
              route: '/aluno/perfil',
            ),
            _ActivationStep(
              title: 'Fazer o primeiro treino',
              description: 'Quando voce treina pelo app, o personal ganha historico para ajustar carga e frequencia.',
              done: historico.any((item) => item.status.toUpperCase() == 'CONCLUIDO'),
              icon: Icons.play_circle_outline,
              cta: 'Abrir treinos',
              route: '/checkin/treinos',
            ),
            _ActivationStep(
              title: 'Abrir seu chat com o personal',
              description: 'Duvidas, feedback e alinhamento precisam acontecer no mesmo lugar do treino.',
              done: mensagens.isNotEmpty,
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
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
                        'Vamos organizar seu app para o personal acompanhar melhor seu progresso desde o primeiro dia.',
                        style: TextStyle(
                          color: Colors.white70,
                          height: 1.45,
                        ),
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? EagleTokens.darkCard : EagleTokens.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doneCount == steps.length
                            ? 'Tudo pronto para comecar'
                            : 'Proximo melhor passo',
                        style: TextStyle(
                          color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        doneCount == steps.length
                            ? 'Sua base inicial esta fechada. Agora o app consegue te acompanhar melhor.'
                            : nextStep.title,
                        style: TextStyle(
                          color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        doneCount == steps.length
                            ? 'Voce pode seguir para a home e usar o app normalmente.'
                            : nextStep.description,
                        style: TextStyle(
                          color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
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
                              icon: const Icon(Icons.arrow_forward),
                              label: Text(
                                doneCount == steps.length
                                    ? 'Entrar no app'
                                    : nextStep.cta,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...steps.map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ActivationStepCard(
                      step: step,
                      isDark: isDark,
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
  final bool isDark;
  final VoidCallback onTap;

  const _ActivationStepCard({
    required this.step,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCard : EagleTokens.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: step.done
                  ? EagleTokens.good.withValues(alpha: 0.14)
                  : EagleTokens.brand.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              step.done ? Icons.check_rounded : step.icon,
              color: step.done ? EagleTokens.good : EagleTokens.brand,
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
                    color: ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  step.description,
                  style: TextStyle(
                    color: mute,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              : TextButton(
                  onPressed: onTap,
                  child: Text(step.cta),
                ),
        ],
      ),
    );
  }
}
