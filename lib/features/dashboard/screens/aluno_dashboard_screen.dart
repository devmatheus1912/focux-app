import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/providers/personal_brand_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../chat/data/chat_repository.dart';
import '../../checkin/providers/checkin_provider.dart';
import '../../checkin/data/checkin_repository.dart';
import '../data/aluno_autonomy_plan.dart';
import '../../evolucao/data/evolucao_repository.dart';
import '../../notificacoes/widgets/notificacao_badge_button.dart';
import '../../health/widgets/aluno_recovery_card.dart';
import '../../coach/widgets/coach_proativo_card.dart';
import '../../nps/widgets/nps_prompt_dialog.dart';
import '../../monetizacao/widgets/aluno_upsell_carousel.dart';
import 'progresso_semanal_widget.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

part 'aluno_dashboard_screen_header.part.dart';
part 'aluno_dashboard_screen_cards.part.dart';
part 'aluno_dashboard_screen_tools.part.dart';

final minhasMedidasDashboardProvider = FutureProvider<List<MedidaCorporal>>((
  ref,
) async {
  final repo = EvolucaoRepository(ref.read(apiClientProvider));
  return repo.listarMinhasMedidas();
});

final chatAlunoDashboardProvider = FutureProvider<List<ChatMsg>>((ref) async {
  final repo = ChatRepository(ref.read(apiClientProvider));
  return repo.historicoAluno();
});

class AlunoDashboardScreen extends ConsumerStatefulWidget {
  const AlunoDashboardScreen({super.key});

  @override
  ConsumerState<AlunoDashboardScreen> createState() =>
      _AlunoDashboardScreenState();
}

class _AlunoDashboardScreenState extends ConsumerState<AlunoDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showNpsPromptIfNeeded(context, ref);
      ref.invalidate(alunoRecoveryProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alunoAsync = ref.watch(alunoMeProvider);
    final brandAsync = ref.watch(personalBrandProvider);
    final treinosAsync = ref.watch(meusTreinosProvider);
    final medidasAsync = ref.watch(minhasMedidasDashboardProvider);
    final historicoAsync = ref.watch(historicoCheckinProvider);
    final chatAsync = ref.watch(chatAlunoDashboardProvider);

    return fxScreenA11yScope(
      label: 'Meu Treino',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Meu Treino',
          leading: const SizedBox(width: 8),
          actions: [
            NotificacaoBadgeButton(),
            alunoAsync.when(
              data:
                  (aluno) => _AlunoAppBarProfileMenu(
                    aluno: aluno,
                    isDark: isDark,
                    onProfile: () => context.push('/aluno/perfil'),
                    onLogout: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
              loading:
                  () => const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: CircleAvatar(radius: 17),
                  ),
              error: (_, __) => const SizedBox(width: 8),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(TokensStrip.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              treinosAsync.when(
                data:
                    (treinos) => alunoAsync.when(
                      data:
                          (aluno) => _TodayFocusCard(
                            experience: buildAlunoHomeExperience(
                              aluno: aluno,
                              medidas: medidasAsync.valueOrNull ?? const [],
                              treinos: treinos,
                              historico: historicoAsync.valueOrNull ?? const [],
                              mensagens: chatAsync.valueOrNull ?? const [],
                            ),
                            isDark: isDark,
                          ),
                      loading: () => _FocusCardSkeleton(isDark: isDark),
                      error: (_, __) => _FocusCardSkeleton(isDark: isDark),
                    ),
                loading: () => _FocusCardSkeleton(isDark: isDark),
                error: (_, __) => _FocusCardSkeleton(isDark: isDark),
              ),
              const SizedBox(height: 12),
              AlunoRecoveryCard(isDark: isDark),
              const SizedBox(height: 12),
              CoachProativoCard(isDark: isDark),
              const SizedBox(height: 12),
              const AlunoUpsellCarousel(),
              const SizedBox(height: 12),
              brandAsync.when(
                data:
                    (brand) => alunoAsync.when(
                      data:
                          (aluno) => _AlunoHeroCard(
                            aluno: aluno,
                            brand: brand,
                            isDark: isDark,
                          ),
                      loading: () => _HeroCardSkeleton(isDark: isDark),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                loading: () => _HeroCardSkeleton(isDark: isDark),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              const ProgressoSemanalWidget(),
              const SizedBox(height: TokensStrip.s4),
              _PerformanceEvolutionCard(
                historicoAsync: historicoAsync,
                isDark: isDark,
              ),
              const SizedBox(height: TokensStrip.s4),
              alunoAsync.when(
                data:
                    (aluno) => _StudentJourneyCard(
                      aluno: aluno,
                      treinos: treinosAsync.valueOrNull ?? const [],
                      medidasAsync: medidasAsync,
                      historicoAsync: historicoAsync,
                      chatAsync: chatAsync,
                      isDark: isDark,
                    ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: TokensStrip.s5),
              _StudentToolsSection(isDark: isDark),
              const SizedBox(height: 20),
              alunoAsync.when(
                data:
                    (aluno) => _AlunoProfileCard(aluno: aluno, isDark: isDark),
                loading: () => _ProfileCardSkeleton(isDark: isDark),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AlunoHeaderAction { profile, logout }
