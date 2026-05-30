import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../screens/aluno_shell.dart';
import '../screens/main_shell.dart';
import '../../features/alunos/data/aluno_repository.dart';
import '../../features/dashboard/screens/personal_dashboard_screen.dart';
import '../../features/dashboard/screens/copilot_actions_screen.dart';
import '../../features/dashboard/screens/aluno_dashboard_screen.dart';
import '../../features/dashboard/screens/aluno_activation_screen.dart';
import '../../features/dashboard/screens/perfil_aluno_screen.dart';
import '../../features/alunos/screens/alunos_list_screen.dart';
import '../../features/alunos/screens/add_aluno_screen.dart';
import '../../features/alunos/screens/aluno_detail_screen.dart';
import '../../features/alunos/screens/aluno_equipamentos_screen.dart';
import '../../features/perfil/data/perfil_repository.dart';
import '../../features/perfil/screens/perfil_screen.dart';
import '../../features/perfil/screens/editar_perfil_screen.dart';
import '../../features/assinatura/screens/assinatura_screen.dart';
import '../../features/convites/screens/convites_screen.dart';
import '../../features/checkin/screens/meus_treinos_screen.dart';
import '../../features/checkin/screens/checkin_screen.dart';
import '../../features/checkin/screens/historico_screen.dart';
import '../../features/exercicios/screens/exercicios_list_screen.dart';
import '../../features/exercicios/screens/exercicio_detail_screen.dart';
import '../../features/exercicios/screens/add_exercicio_screen.dart';
import '../../features/exercicios/screens/onboarding_biblioteca_wizard.dart';
import '../../features/treinos/screens/treinos_list_screen.dart';
import '../../features/treinos/screens/treino_detail_screen.dart';
import '../../features/treinos/screens/create_treino_screen.dart';
import '../../features/treinos/screens/add_exercicio_to_treino_screen.dart';
import '../../features/financeiro/screens/financeiro_screen.dart';
import '../../features/agenda/screens/agenda_screen.dart';
import '../../features/relatorio/screens/relatorio_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/feed/screens/feed_aluno_screen.dart';
import '../../features/chat/screens/chat_aluno_screen.dart';
import '../../features/chat/screens/chat_inbox_screen.dart';
import '../../features/ia/screens/ia_chat_screen.dart';
import '../../features/leads/screens/leads_list_screen.dart';
import '../../features/alertas/screens/alertas_screen.dart';
import '../../features/evolucao/screens/evolucao_screen.dart';
import '../../features/evolucao/screens/evolucao_fotos_screen.dart';
import '../../features/health/screens/health_dashboard_screen.dart';
import '../../features/checkin/screens/modo_presencial_screen.dart';
import '../../features/ia/screens/ia_copiloto_screen.dart';
import '../../features/ia/screens/progressao_aceitar_screen.dart';
import '../../features/alunos/screens/editar_aluno_screen.dart';
import '../../features/ranking/screens/ranking_screen.dart';
import '../../features/perfil/screens/identidade_visual_screen.dart';
import '../../features/perfil/screens/white_label_settings_screen.dart';
import '../../features/perfil/screens/landing_editor_screen.dart';
import '../../features/dunning/screens/dunning_ops_screen.dart';
import '../../features/winback/screens/winback_screen.dart';
import '../../features/evolucao/screens/engajamento_screen.dart';
import '../../features/alunos/screens/acoes_massa_screen.dart';
import '../../features/ia/screens/ia_aluno_screen.dart';
import '../../features/financeiro/screens/financeiro_aluno_screen.dart';
import '../../features/suporte/screens/suporte_screen.dart';
import '../../features/broadcasts/screens/broadcast_screen.dart';
import '../../features/plano_sucesso/plano_sucesso_provider.dart';
import '../../features/plano_sucesso/plano_sucesso_screen.dart';
import '../../features/alertas/screens/alerta_detalhe_screen.dart';
import '../../features/alertas/screens/alertas_config_screen.dart';
import '../../features/relatorio/screens/relatorio_global_screen.dart';
import '../../features/avaliacao/screens/evolucao_comparativo_screen.dart';
import '../../features/agenda/screens/agenda_aluno_screen.dart';
import '../../features/feedback/screens/feedback_video_screen.dart';
import '../../features/busca/screens/busca_global_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/trilhas/screens/trilhas_screen.dart';
import '../../features/dashboard/screens/qualidade_operacional_screen.dart';
import '../../features/admin/screens/rbac_screen.dart';
import '../../features/depoimentos/screens/depoimento_aluno_screen.dart';
import '../../features/depoimentos/screens/depoimentos_personal_screen.dart';
import '../../features/galeria/screens/galeria_screen.dart';
import '../../features/planos/screens/enterprise_promo_screen.dart';
import '../../features/referral/screens/referral_screen.dart';
import '../../features/retencao/screens/churn_dashboard_screen.dart';
import '../../features/monetizacao/screens/ofertas_upsell_screen.dart';
import '../../features/monetizacao/screens/cancel_save_screen.dart';
import '../../features/habitos/screens/habitos_personal_screen.dart';
import '../../features/habitos/screens/habitos_aluno_screen.dart';
import '../../features/pacotes/screens/pacotes_screen.dart';
import '../../features/recorrencia/screens/recorrencia_screen.dart';
import '../../features/recorrencia/screens/recorrencia_aluno_screen.dart';
import '../../features/nps/screens/nps_dashboard_screen.dart';
import '../../features/grupos/screens/grupo_aulas_personal_screen.dart';
import '../../features/grupos/screens/grupo_aulas_aluno_screen.dart';
import '../../features/onboarding/screens/onboarding_wizard_screen.dart';
import '../../features/feedback/screens/feedback_aluno_screen.dart';
import '../../features/captura/screens/leads_publicos_screen.dart';
import '../../features/relatorio/screens/business_reports_screen.dart';
import '../../features/growth/screens/migracao_magica_screen.dart';
import '../../features/gamificacao/screens/gamificacao_screen.dart';
import '../../features/anamnese/screens/anamnese_screen.dart';
import '../../features/alimentar/screens/alimentar_screen.dart';
import '../../features/ia/screens/ia_progressao_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/perfil/screens/wallet_screen.dart';
import '../../features/notificacoes/screens/notificacoes_screen.dart';
import 'qa_routes.dart' if (dart.vm.product) 'qa_routes_stub.dart';
import '../auth/session_invalidator.dart';
import '../widgets/fx_route_chrome.dart';
import 'fx_page_transition.dart';
import 'role_home.dart';
import 'app_router_auth_routes.dart';
import 'app_router_redirect.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => const HomeRedirectScreen(),
    refreshListenable: SessionInvalidator.listenable,
    redirect: (context, state) async => authRedirect(state),
    routes: [
      ...buildAuthRoutes(),

      // ── Aluno (student) dashboard — not part of personal trainer shell ────────
      StatefulShellRoute.indexedStack(
        builder:
            (context, state, navigationShell) =>
                AlunoShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard/aluno',
                builder: (context, state) => const AlunoDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/checkin/treinos',
                builder: (context, state) => const MeusTreinosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/saude',
                builder: (context, state) => const HealthDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/aluno/perfil',
                builder: (context, state) => const PerfilAlunoScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/aluno/ativacao',
        builder:
            (context, state) =>
                const FxRouteChrome(child: AlunoActivationScreen()),
      ),
      GoRoute(
        path: '/aluno/habitos',
        builder:
            (context, state) =>
                const FxRouteChrome(child: HabitosAlunoScreen()),
      ),
      GoRoute(
        path: '/aluno/recorrencia',
        builder: (context, state) => const FxRouteChrome(child: RecorrenciaAlunoScreen()),
      ),
      GoRoute(
        path: '/aluno/grupo-aulas',
        builder: (context, state) => const FxRouteChrome(child: GrupoAulasAlunoScreen()),
      ),
      GoRoute(
        path: '/aluno/form-check',
        builder: (context, state) => const FxRouteChrome(child: FeedbackAlunoScreen()),
      ),
      GoRoute(
        path: '/notificacoes',
        builder:
            (context, state) =>
                const FxRouteChrome(child: NotificacoesScreen()),
      ),
      GoRoute(
        path: '/evolucao',
        redirect: (context, state) => '/dashboard/aluno',
      ),

      // ── Personal trainer main shell — 5 tabs with FxDock ─────────────────────
      StatefulShellRoute.indexedStack(
        builder:
            (context, state, navigationShell) =>
                MainShell(navigationShell: navigationShell),
        branches: [
          // Tab 0: Hoje (personal dashboard)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard/personal',
                builder: (context, state) => const PersonalDashboardScreen(),
              ),
            ],
          ),
          // Tab 1: Alunos
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/alunos',
                builder:
                    (context, state) => AlunosListScreen(
                      initialFiltro: alunoFiltroFromQuery(
                        state.uri.queryParameters['filtro'],
                      ),
                    ),
              ),
            ],
          ),
          // Tab 2: Treinos
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/treinos',
                builder: (context, state) => const TreinosListScreen(),
              ),
            ],
          ),
          // Tab 3: Agenda
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/agenda',
                builder: (context, state) => const AgendaScreen(),
              ),
            ],
          ),
          // Tab 4: IA Copiloto
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ia/copiloto',
                builder: (context, state) => const IaCopilotoScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Sub-routes (pushed over the shell, dock hidden) ───────────────────────
      ShellRoute(
        builder: (context, state, child) => FxRouteChrome(child: child),
        routes: [
          GoRoute(
            path: '/dashboard/qualidade',
            builder: (context, state) => const QualidadeOperacionalScreen(),
          ),
          GoRoute(
            path: '/dashboard/command-center/copiloto',
            builder: (context, state) => const CopilotActionsScreen(),
          ),

          // Alunos sub-routes (specific before parameterized)
          GoRoute(
            path: '/alunos/novo',
            builder:
                (context, state) => AddAlunoScreen(
                  initialEmail: state.uri.queryParameters['email'],
                  initialNome: state.uri.queryParameters['nome'],
                ),
          ),
          GoRoute(
            path: '/alunos/acoes-massa',
            builder: (context, state) => const AcoesMassaScreen(),
          ),
          GoRoute(
            path: '/kanban',
            redirect: (context, state) => '/alunos/acoes-massa',
          ),
          GoRoute(
            path: '/alunos/:id',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/alunos' : null,
            builder:
                (context, state) =>
                    AlunoDetailScreen(alunoId: intPathParam(state, 'id')!),
          ),
          GoRoute(
            path: '/alunos/:id/editar',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null
                        ? '/alunos'
                        : state.extra is Aluno
                        ? null
                        : '/alunos/${state.pathParameters['id']}',
            builder:
                (context, state) =>
                    EditarAlunoScreen(aluno: state.extra as Aluno),
          ),
          GoRoute(
            path: '/alunos/:id/equipamentos',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/alunos' : null,
            builder:
                (context, state) => AlunoEquipamentosScreen(
                  alunoId: intPathParam(state, 'id')!,
                ),
          ),
          GoRoute(
            path: '/alunos/:id/relatorio',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/alunos' : null,
            builder:
                (context, state) => RelatorioScreen(
                  alunoId: intPathParam(state, 'id')!,
                  alunoNome: stringRouteExtra(state) ?? 'Aluno',
                ),
          ),
          GoRoute(
            path: '/alunos/:id/evolucao',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/alunos' : null,
            builder:
                (context, state) => EvolucaoScreen(
                  alunoId: intPathParam(state, 'id')!,
                  alunoNome: stringRouteExtra(state) ?? 'Aluno',
                ),
          ),
          GoRoute(
            path: '/alunos/:id/plano-sucesso',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/alunos' : null,
            builder:
                (context, state) => ChangeNotifierProvider(
                  create: (_) => PlanoSucessoProvider(),
                  child: PlanoSucessoScreen(
                    alunoId: intPathParam(state, 'id')!,
                  ),
                ),
          ),
          GoRoute(
            path: '/alunos/:id/fotos',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/alunos' : null,
            builder:
                (context, state) => EvolucaoFotosScreen(
                  alunoId: intPathParam(state, 'id')!,
                  alunoNome: stringRouteExtra(state) ?? 'Aluno',
                ),
          ),
          GoRoute(
            path: '/treino-presencial/:id',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/treinos' : null,
            builder:
                (context, state) =>
                    ModoPresencialScreen(treinoId: intPathParam(state, 'id')!),
          ),
          GoRoute(
            path: '/alunos/:id/anamnese',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/alunos' : null,
            builder:
                (context, state) =>
                    AnamneseScreen(alunoId: intPathParam(state, 'id')!),
          ),
          GoRoute(
            path: '/alunos/:id/alimentar',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/alunos' : null,
            builder:
                (context, state) =>
                    AlimentarScreen(alunoId: intPathParam(state, 'id')!),
          ),
          GoRoute(
            path: '/alunos/:id/treinos-list',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/alunos' : null,
            builder:
                (context, state) => TreinosListScreen(
                  alunoId: intPathParam(state, 'id')!,
                  alunoNome: stringRouteExtra(state),
                ),
          ),
          GoRoute(
            path: '/alunos/:id/ia/progressao',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/alunos' : null,
            builder:
                (context, state) => IaProgressaoScreen(
                  alunoId: intPathParam(state, 'id')!,
                  alunoNome: stringRouteExtra(state) ?? 'Aluno',
                ),
          ),
          GoRoute(
            path: '/alunos/:id/chat',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/alunos' : null,
            builder:
                (context, state) => ChatScreen(
                  alunoId: intPathParam(state, 'id')!,
                  alunoNome: chatAlunoNomeExtra(state) ?? 'Aluno',
                  initialDraft: chatDraftExtra(state),
                ),
          ),
          GoRoute(
            path: '/alunos/:id/feedback-video',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/alunos' : null,
            builder:
                (context, state) => FeedbackVideoScreen(
                  alunoId: intPathParam(state, 'id')!,
                  alunoNome: stringRouteExtra(state) ?? 'Aluno',
                ),
          ),
          GoRoute(
            path: '/alunos/:id/engajamento',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/alunos' : null,
            builder: (context, state) {
              final id = intPathParam(state, 'id')!;
              final nome = stringRouteExtra(state) ?? 'Aluno';
              return EngajamentoScreen(alunoId: id, alunoNome: nome);
            },
          ),
          GoRoute(
            path: '/alunos/:id/evolucao-comparativo',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/alunos' : null,
            builder:
                (context, state) => EvolucaoComparativoScreen(
                  alunoId: intPathParam(state, 'id')!,
                  alunoNome: stringRouteExtra(state) ?? 'Aluno',
                ),
          ),
          GoRoute(
            path: '/alunos/:id/trilhas',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/alunos' : null,
            builder:
                (context, state) => TrilhasScreen(
                  alunoId: intPathParam(state, 'id')!,
                  alunoNome: stringRouteExtra(state) ?? 'Aluno',
                ),
          ),
          GoRoute(
            path: '/alunos/:id/feedback-videos',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/alunos' : null,
            builder:
                (context, state) => FeedbackVideoScreen(
                  alunoId: intPathParam(state, 'id')!,
                  alunoNome: stringRouteExtra(state) ?? 'Aluno',
                ),
          ),

          // Treinos sub-routes
          GoRoute(
            path: '/treinos/novo',
            builder: (context, state) {
              final extra = state.extra;
              int? alunoId;
              String? alunoNome;
              if (extra is Map) {
                final rawAlunoId = extra['alunoId'];
                alunoId =
                    rawAlunoId is int
                        ? rawAlunoId
                        : int.tryParse(rawAlunoId?.toString() ?? '');
                alunoNome = extra['alunoNome']?.toString();
              }
              return CreateTreinoScreen(alunoId: alunoId, alunoNome: alunoNome);
            },
          ),
          GoRoute(
            path: '/treinos/:id',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/treinos' : null,
            builder: (context, state) {
              final extra = state.extra;
              int? alunoId;
              String? alunoNome;
              if (extra is Map) {
                final rawAlunoId = extra['alunoId'];
                alunoId =
                    rawAlunoId is int
                        ? rawAlunoId
                        : int.tryParse(rawAlunoId?.toString() ?? '');
                alunoNome = extra['alunoNome']?.toString();
              }
              return TreinoDetailScreen(
                treinoId: intPathParam(state, 'id')!,
                alunoId: alunoId,
                alunoNome: alunoNome,
              );
            },
          ),
          GoRoute(
            path: '/treinos/:id/exercicios/add',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/treinos' : null,
            builder: (context, state) {
              int? alunoId;
              if (state.extra is Map) {
                final extra = state.extra as Map;
                final raw = extra['alunoId'];
                alunoId =
                    raw is int ? raw : int.tryParse(raw?.toString() ?? '');
              }
              return AddExercicioToTreinoScreen(
                treinoId: intPathParam(state, 'id')!,
                alunoId: alunoId,
              );
            },
          ),

          // Exercícios
          GoRoute(
            path: '/exercicios',
            builder: (context, state) => const ExerciciosListScreen(),
          ),
          GoRoute(
            path: '/exercicios/novo',
            builder: (context, state) => const AddExercicioScreen(),
          ),
          GoRoute(
            path: '/exercicios/biblioteca-wizard',
            builder: (context, state) => const OnboardingBibliotecaWizard(),
          ),
          GoRoute(
            path: '/exercicios/:id',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/exercicios' : null,
            builder:
                (context, state) => ExercicioDetailScreen(
                  exercicioId: intPathParam(state, 'id')!,
                ),
          ),

          // Check-in
          GoRoute(
            path: '/checkin/executar',
            redirect:
                (context, state) =>
                    treinoIdFromState(state) == null
                        ? '/checkin/treinos'
                        : null,
            builder:
                (context, state) =>
                    CheckinScreen(treinoId: treinoIdFromState(state)!),
          ),
          GoRoute(
            path: '/checkin/historico',
            builder: (context, state) => const HistoricoCheckinScreen(),
          ),

          // Agenda sub-routes (tab stays in shell)
          GoRoute(
            path: '/agenda/novo',
            builder: (context, state) => const NovoAgendamentoScreen(),
          ),
          GoRoute(
            path: '/agenda/aluno',
            builder: (context, state) => const AgendaAlunoScreen(),
          ),

          // Financeiro (moved out of dock — accessible via push)
          GoRoute(
            path: '/financeiro',
            builder: (context, state) => const FinanceiroScreen(),
          ),

          // Perfil
          GoRoute(
            path: '/perfil',
            builder: (context, state) => const PerfilScreen(),
          ),
          GoRoute(
            path: '/configuracoes',
            builder: (context, state) => const PerfilScreen(),
          ),
          GoRoute(
            path: '/perfil/editar',
            redirect:
                (context, state) =>
                    state.extra is PerfilPersonal ? null : '/perfil',
            pageBuilder:
                (context, state) => fxTransitionPage(
                  state: state,
                  child: EditarPerfilScreen(
                    perfil: state.extra as PerfilPersonal,
                  ),
                ),
          ),
          GoRoute(
            path: '/perfil/wallet',
            builder: (context, state) => const WalletScreen(),
          ),
          GoRoute(
            path: '/identidade-visual',
            pageBuilder:
                (context, state) => fxTransitionPage(
                  state: state,
                  child: const IdentidadeVisualScreen(),
                ),
          ),
          GoRoute(
            path: '/white-label',
            pageBuilder:
                (context, state) => fxTransitionPage(
                  state: state,
                  child: const WhiteLabelSettingsScreen(),
                ),
          ),
          GoRoute(
            path: '/perfil/white-label',
            redirect: (context, state) => '/white-label',
          ),
          GoRoute(
            path: '/setup/identidade',
            builder:
                (context, state) => const IdentidadeVisualScreen(isSetup: true),
          ),

          // IA sub-routes
          GoRoute(
            path: '/ia/chat',
            builder: (context, state) => const IaChatScreen(),
          ),
          GoRoute(
            path: '/ia/aluno',
            builder: (context, state) => const IaAlunoScreen(),
          ),
          GoRoute(
            path: '/ia/checkin',
            redirect: (context, state) => '/ia/copiloto',
          ),
          GoRoute(
            path: '/ia/progressao/aceitar',
            builder: (context, state) => const ProgressaoAceitarScreen(),
          ),

          // Chat
          GoRoute(
            path: '/chat/inbox',
            builder: (context, state) => const ChatInboxScreen(),
          ),
          GoRoute(
            path: '/chat/aluno',
            builder: (context, state) => const ChatAlunoScreen(),
          ),

          // Financeiro sub-routes
          GoRoute(
            path: '/financeiro/aluno',
            builder: (context, state) => const FinanceiroAlunoScreen(),
          ),

          // Feed
          GoRoute(
            path: '/feed',
            builder: (context, state) => const FeedScreen(),
          ),
          GoRoute(
            path: '/feed/aluno',
            builder: (context, state) => const FeedAlunoScreen(),
          ),

          // Leads
          GoRoute(
            path: '/leads',
            builder: (context, state) => const LeadsListScreen(),
          ),

          // Alertas
          GoRoute(
            path: '/alertas',
            builder: (context, state) => const AlertasScreen(),
          ),
          GoRoute(
            path: '/alertas/aluno/:id',
            redirect:
                (context, state) =>
                    intPathParam(state, 'id') == null ? '/alertas' : null,
            builder:
                (context, state) => AlertaDetalheScreen(
                  alunoId: intPathParam(state, 'id')!,
                  alunoNome: stringRouteExtra(state) ?? 'Aluno',
                ),
          ),
          GoRoute(
            path: '/alertas/config',
            builder: (context, state) => const AlertasConfigScreen(),
          ),

          // Relatórios
          GoRoute(
            path: '/relatorios/global',
            builder: (context, state) => const RelatorioGlobalScreen(),
          ),

          // Subscription / plans
          GoRoute(
            path: '/convites',
            builder: (context, state) => const ConvitesScreen(),
          ),
          GoRoute(
            path: '/planos',
            redirect: (context, state) {
              final plano = state.uri.queryParameters['plano'];
              if (plano != null && plano.trim().isNotEmpty) {
                return '/assinatura?plano=${Uri.encodeComponent(plano.trim())}';
              }
              return '/assinatura';
            },
          ),
          GoRoute(
            path: '/paywall',
            redirect: (context, state) {
              final plano = state.uri.queryParameters['plano'];
              if (plano != null && plano.trim().isNotEmpty) {
                return '/assinatura?plano=${Uri.encodeComponent(plano.trim())}';
              }
              return '/assinatura';
            },
          ),
          GoRoute(
            path: '/assinatura',
            builder:
                (context, state) => AssinaturaScreen(
                  initialPlan:
                      stringRouteExtra(state) ??
                      state.uri.queryParameters['plano'] ??
                      state.uri.queryParameters['plan'],
                  source: state.uri.queryParameters['source'],
                  blockedFeature: state.uri.queryParameters['feature'],
                ),
          ),
          GoRoute(
            path: '/referral',
            builder: (context, state) => const ReferralScreen(),
          ),
          GoRoute(
            path: '/retencao',
            builder: (context, state) => const ChurnDashboardScreen(),
          ),
          GoRoute(
            path: '/ofertas-upsell',
            builder: (context, state) => const OfertasUpsellScreen(),
          ),
          GoRoute(
            path: '/cancel-save',
            builder: (context, state) => const CancelSaveScreen(),
          ),
          GoRoute(
            path: '/habitos',
            builder: (context, state) => const HabitosPersonalScreen(),
          ),
          GoRoute(
            path: '/pacotes',
            builder: (context, state) => const PacotesScreen(),
          ),
          GoRoute(
            path: '/leads-publicos',
            builder: (context, state) => const LeadsPublicosScreen(),
          ),
          GoRoute(
            path: '/perfil/landing-editor',
            builder: (context, state) => const LandingEditorScreen(),
          ),
          GoRoute(
            path: '/dunning',
            builder: (context, state) => const DunningOpsScreen(),
          ),
          GoRoute(
            path: '/winback',
            builder: (context, state) => const WinbackScreen(),
          ),
          GoRoute(
            path: '/relatorio/business',
            builder: (context, state) => const BusinessReportsScreen(),
          ),
          GoRoute(
            path: '/recorrencia',
            builder: (context, state) => const RecorrenciaScreen(),
          ),
          GoRoute(
            path: '/nps',
            builder: (context, state) => const NpsDashboardScreen(),
          ),
          GoRoute(
            path: '/grupo-aulas',
            builder: (context, state) => const GrupoAulasPersonalScreen(),
          ),
          GoRoute(
            path: '/onboarding/wizard',
            builder: (context, state) => const OnboardingWizardScreen(),
          ),
          GoRoute(
            path: '/migracao-magica',
            builder: (context, state) => const MigracaoMagicaScreen(),
          ),
          GoRoute(
            path: '/migracao-focux',
            redirect: (context, state) => '/migracao-magica',
          ),
          GoRoute(
            path: '/growth/migracao',
            redirect: (context, state) => '/migracao-magica',
          ),
          GoRoute(
            path: '/promo-enterprise',
            builder: (context, state) => const EnterprisePromoScreen(),
          ),

          // Misc
          GoRoute(
            path: '/ranking',
            builder: (context, state) => const RankingScreen(),
          ),
          GoRoute(
            path: '/suporte',
            builder: (context, state) => const SuporteScreen(),
          ),
          GoRoute(
            path: '/broadcasts',
            builder: (context, state) => const BroadcastScreen(),
          ),
          GoRoute(
            path: '/depoimentos-aluno',
            builder: (context, state) => const DepoimentoAlunoScreen(),
          ),
          GoRoute(
            path: '/depoimentos',
            builder: (context, state) => const DepoimentosPersonalScreen(),
          ),
          GoRoute(
            path: '/galeria',
            builder: (context, state) => const GaleriaScreen(),
          ),
          GoRoute(
            path: '/feedback-videos',
            builder: (context, state) => const FeedbackVideoScreen(),
          ),
          GoRoute(
            path: '/busca',
            builder: (context, state) => const BuscaGlobalScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/admin/rbac',
            builder: (context, state) => const RbacScreen(),
          ),
          GoRoute(
            path: '/gamificacao',
            pageBuilder:
                (context, state) => fxTransitionPage(
                  state: state,
                  child: const GamificacaoScreen(),
                ),
          ),
        ],
      ),

      // QA — fora do ShellRoute; stub vazio em release (dart.vm.product).
      ...buildQaRoutes(),
    ],
  );
}
