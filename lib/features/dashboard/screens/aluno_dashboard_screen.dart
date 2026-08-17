import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/providers/personal_brand_provider.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/data/chat_repository.dart';
import '../../checkin/data/checkin_repository.dart';
import '../../checkin/data/meus_treinos_mem_cache.dart';
import '../../coach/widgets/coach_proativo_card.dart';
import '../../evolucao/data/evolucao_repository.dart';
import '../../health/widgets/aluno_recovery_card.dart';
import '../../monetizacao/widgets/aluno_upsell_carousel.dart';
import '../../notificacoes/widgets/notificacao_badge_button.dart';
import '../../nps/widgets/nps_prompt_dialog.dart';
import '../data/aluno_autonomy_plan.dart';
import '../providers/dashboard_provider.dart';
import 'progresso_semanal_widget.dart';

part 'aluno_dashboard_screen_header.part.dart';
part 'aluno_dashboard_screen_cards.part.dart';
part 'aluno_dashboard_screen_tools.part.dart';

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
    final primary = Theme.of(context).colorScheme.primary;
    final homeAsync = ref.watch(alunoDashboardHomeProvider);

    return fxScreenA11yScope(
      label: 'Meu Treino',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Meu Treino',
          leading: const SizedBox(width: 8),
          actions: [
            homeAsync.when(
              data:
                  (home) => NotificacaoBadgeButton(
                    countOverride: home.notificacoesNaoLidas,
                  ),
              loading: () => const NotificacaoBadgeButton(),
              error: (_, __) => const NotificacaoBadgeButton(),
            ),
            homeAsync.when(
              data:
                  (home) => _AlunoAppBarProfileMenu(
                    aluno: home.aluno,
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
        body: homeAsync.when(
          loading: () => const Center(child: FxLoading()),
          error:
              (e, _) => FxErrorState(
                chromeOnDark: isDark,
                primary: primary,
                message: friendlyError(e),
                onRetry: () => ref.invalidate(alunoDashboardHomeProvider),
              ),
          data: (home) {
            MeusTreinosMemCache.save(home.treinos);
            final experience = buildAlunoHomeExperience(
              aluno: home.aluno,
              medidas: home.medidas,
              treinos: home.treinos,
              historico: home.historico,
              mensagens: home.chat.toSyntheticMessages(),
            );
            final freshness = FxHubFreshness.fromFetchedAt(home.fetchedAt);

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(alunoDashboardHomeProvider);
                await ref.read(alunoDashboardHomeProvider.future);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(TokensStrip.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FxHubHeader(
                      title: 'Meu Treino',
                      freshnessLabel: freshness,
                      quietChrome: true,
                    ),
                    const SizedBox(height: 12),
                    _TodayFocusCard(
                      experience: experience,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    AlunoRecoveryCard(isDark: isDark),
                    const SizedBox(height: 12),
                    CoachProativoCard(isDark: isDark),
                    const SizedBox(height: 12),
                    const AlunoUpsellCarousel(),
                    const SizedBox(height: 12),
                    _AlunoHeroCard(
                      aluno: home.aluno,
                      brand: home.personalBrand,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    const ProgressoSemanalWidget(),
                    const SizedBox(height: TokensStrip.s4),
                    _PerformanceEvolutionCard(
                      historicoAsync: AsyncValue.data(home.historico),
                      isDark: isDark,
                    ),
                    const SizedBox(height: TokensStrip.s4),
                    _StudentJourneyCard(
                      aluno: home.aluno,
                      treinos: home.treinos,
                      medidasAsync: AsyncValue.data(home.medidas),
                      historicoAsync: AsyncValue.data(home.historico),
                      chatAsync: AsyncValue.data(
                        home.chat.toSyntheticMessages(),
                      ),
                      isDark: isDark,
                    ),
                    const SizedBox(height: TokensStrip.s5),
                    _StudentToolsSection(isDark: isDark),
                    const SizedBox(height: 20),
                    _AlunoProfileCard(aluno: home.aluno, isDark: isDark),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _AlunoHeaderAction { profile, logout }
