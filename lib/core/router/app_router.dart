import 'package:go_router/go_router.dart';
import '../screens/main_shell.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/dashboard/screens/personal_dashboard_screen.dart';
import '../../features/dashboard/screens/aluno_dashboard_screen.dart';
import '../../features/dashboard/screens/aluno_activation_screen.dart';
import '../../features/dashboard/screens/perfil_aluno_screen.dart';
import '../../features/alunos/screens/alunos_list_screen.dart';
import '../../features/alunos/screens/add_aluno_screen.dart';
import '../../features/alunos/screens/aluno_detail_screen.dart';
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
import '../../features/treinos/screens/treinos_list_screen.dart';
import '../../features/treinos/screens/treino_detail_screen.dart';
import '../../features/treinos/screens/create_treino_screen.dart';
import '../../features/treinos/screens/add_exercicio_to_treino_screen.dart';
import '../../features/financeiro/screens/financeiro_screen.dart';
import '../../features/agenda/screens/agenda_screen.dart';
import '../../features/relatorio/screens/relatorio_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/feed/screens/feed_aluno_screen.dart';
import '../../features/auth/screens/register_aluno_screen.dart';
import '../../features/chat/screens/chat_aluno_screen.dart';
import '../../features/chat/screens/chat_inbox_screen.dart';
import '../../features/ia/screens/ia_chat_screen.dart';
import '../../features/leads/screens/leads_list_screen.dart';
import '../../features/alertas/screens/alertas_screen.dart';
import '../../features/evolucao/screens/evolucao_screen.dart';
import '../../features/ia/screens/ia_copiloto_screen.dart';
import '../../features/ia/screens/progressao_aceitar_screen.dart';
import '../../features/alunos/screens/editar_aluno_screen.dart';
import '../../features/alunos/data/aluno_repository.dart';
import '../../features/auth/screens/esqueci_senha_screen.dart';
import '../../features/auth/screens/definir_senha_aluno_screen.dart';
import '../../features/auth/screens/resetar_senha_screen.dart';
import '../../features/ranking/screens/ranking_screen.dart';
import '../../features/perfil/screens/identidade_visual_screen.dart';
import '../../features/evolucao/screens/engajamento_screen.dart';
import '../../features/alunos/screens/acoes_massa_screen.dart';
import '../../features/ia/screens/ia_aluno_screen.dart';
import '../../features/financeiro/screens/financeiro_aluno_screen.dart';
import '../../features/suporte/screens/suporte_screen.dart';
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
import '../../features/landing/screens/personal_public_landing_screen.dart';
import '../../features/depoimentos/screens/depoimento_aluno_screen.dart';
import '../../features/depoimentos/screens/depoimentos_personal_screen.dart';
import '../../features/galeria/screens/galeria_screen.dart';
import '../../features/planos/screens/planos_screen.dart';
import '../../features/planos/screens/enterprise_promo_screen.dart';
import '../../features/subscription/screens/paywall_screen.dart';
import '../../features/growth/screens/migracao_magica_screen.dart';
import '../../features/growth/screens/landing_page_config_screen.dart';
import '../../features/gamificacao/screens/gamificacao_screen.dart';
import '../../features/anamnese/screens/anamnese_screen.dart';
import '../../features/alimentar/screens/alimentar_screen.dart';
import '../../features/ia/screens/ia_progressao_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/perfil/screens/wallet_screen.dart';
import 'role_home.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => const HomeRedirectScreen(),
    routes: [
      // ── Auth / public ────────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeRedirectScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const HomeRedirectScreen(),
      ),
      GoRoute(
        path: '/dashboard/home',
        builder: (context, state) => const HomeRedirectScreen(),
      ),
      GoRoute(
        path: '/aluno',
        redirect: (context, state) => '/dashboard/aluno',
      ),
      GoRoute(
        path: '/personal',
        redirect: (context, state) => '/dashboard/personal',
      ),
      GoRoute(
        path: '/ia',
        redirect: (context, state) => '/ia/copiloto',
      ),
      GoRoute(
        path: '/p/:slug',
        builder: (context, state) => PersonalPublicLandingScreen(
          slug: state.pathParameters['slug']!,
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/register/aluno',
        builder: (context, state) => RegisterAlunoScreen(
          personalSlug: state.uri.queryParameters['p'],
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/esqueci-senha',
        builder: (context, state) => const EsqueciSenhaScreen(),
      ),
      GoRoute(
        path: '/resetar-senha',
        builder: (context, state) => ResetarSenhaScreen(
          token: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: '/aluno/definir-senha',
        builder: (context, state) => const DefinirSenhaAlunoScreen(),
      ),

      // ── Aluno (student) dashboard — not part of personal trainer shell ────────
      GoRoute(
        path: '/dashboard/aluno',
        builder: (context, state) => const AlunoDashboardScreen(),
      ),
      GoRoute(
        path: '/aluno/ativacao',
        builder: (context, state) => const AlunoActivationScreen(),
      ),
      GoRoute(
        path: '/aluno/perfil',
        builder: (context, state) => const PerfilAlunoScreen(),
      ),

      // ── Personal trainer main shell — 5 tabs with FxDock ─────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Tab 0: Hoje (personal dashboard)
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dashboard/personal',
              builder: (context, state) => const PersonalDashboardScreen(),
            ),
          ]),
          // Tab 1: Alunos
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/alunos',
              builder: (context, state) => const AlunosListScreen(),
            ),
          ]),
          // Tab 2: Treinos
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/treinos',
              builder: (context, state) => const TreinosListScreen(),
            ),
          ]),
          // Tab 3: Agenda
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/agenda',
              builder: (context, state) => const AgendaScreen(),
            ),
          ]),
          // Tab 4: IA Copiloto
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/ia/copiloto',
              builder: (context, state) => const IaCopilotoScreen(),
            ),
          ]),
        ],
      ),

      // ── Sub-routes (pushed over the shell, dock hidden) ───────────────────────
      GoRoute(
        path: '/dashboard/qualidade',
        builder: (context, state) => const QualidadeOperacionalScreen(),
      ),

      // Alunos sub-routes (specific before parameterized)
      GoRoute(
        path: '/alunos/novo',
        builder: (context, state) => const AddAlunoScreen(),
      ),
      GoRoute(
        path: '/alunos/acoes-massa',
        builder: (context, state) => const AcoesMassaScreen(),
      ),
      GoRoute(
        path: '/alunos/:id',
        builder: (context, state) => AlunoDetailScreen(
          alunoId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/alunos/:id/editar',
        builder: (context, state) => EditarAlunoScreen(
          aluno: state.extra as Aluno,
        ),
      ),
      GoRoute(
        path: '/alunos/:id/relatorio',
        builder: (context, state) => RelatorioScreen(
          alunoId: int.parse(state.pathParameters['id']!),
          alunoNome: state.extra as String? ?? 'Aluno',
        ),
      ),
      GoRoute(
        path: '/alunos/:id/evolucao',
        builder: (context, state) => EvolucaoScreen(
          alunoId: int.parse(state.pathParameters['id']!),
          alunoNome: state.extra as String? ?? 'Aluno',
        ),
      ),
      GoRoute(
        path: '/alunos/:id/anamnese',
        builder: (context, state) => AnamneseScreen(
          alunoId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/alunos/:id/alimentar',
        builder: (context, state) => AlimentarScreen(
          alunoId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/alunos/:id/treinos-list',
        builder: (context, state) => TreinosListScreen(
          alunoId: int.parse(state.pathParameters['id']!),
          alunoNome: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/alunos/:id/ia/progressao',
        builder: (context, state) => IaProgressaoScreen(
          alunoId: int.parse(state.pathParameters['id']!),
          alunoNome: state.extra as String? ?? 'Aluno',
        ),
      ),
      GoRoute(
        path: '/alunos/:id/chat',
        builder: (context, state) => ChatScreen(
          alunoId: int.parse(state.pathParameters['id']!),
          alunoNome: state.extra as String? ?? 'Aluno',
        ),
      ),
      GoRoute(
        path: '/alunos/:id/feedback-video',
        builder: (context, state) => FeedbackVideoScreen(
          alunoId: int.parse(state.pathParameters['id']!),
          alunoNome: state.extra as String? ?? 'Aluno',
        ),
      ),
      GoRoute(
        path: '/alunos/:id/engajamento',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final nome = state.extra as String? ?? 'Aluno';
          return EngajamentoScreen(alunoId: id, alunoNome: nome);
        },
      ),
      GoRoute(
        path: '/alunos/:id/evolucao-comparativo',
        builder: (context, state) => EvolucaoComparativoScreen(
          alunoId: int.parse(state.pathParameters['id']!),
          alunoNome: state.extra as String? ?? 'Aluno',
        ),
      ),
      GoRoute(
        path: '/alunos/:id/trilhas',
        builder: (context, state) => TrilhasScreen(
          alunoId: int.parse(state.pathParameters['id']!),
          alunoNome: state.extra as String? ?? 'Aluno',
        ),
      ),
      GoRoute(
        path: '/alunos/:id/feedback-videos',
        builder: (context, state) => FeedbackVideoScreen(
          alunoId: int.parse(state.pathParameters['id']!),
          alunoNome: state.extra as String? ?? 'Aluno',
        ),
      ),

      // Treinos sub-routes
      GoRoute(
        path: '/treinos/novo',
        builder: (context, state) => const CreateTreinoScreen(),
      ),
      GoRoute(
        path: '/treinos/:id',
        builder: (context, state) => TreinoDetailScreen(
          treinoId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/treinos/:id/exercicios/add',
        builder: (context, state) => AddExercicioToTreinoScreen(
          treinoId: int.parse(state.pathParameters['id']!),
        ),
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
        path: '/exercicios/:id',
        builder: (context, state) => ExercicioDetailScreen(
          exercicioId: int.parse(state.pathParameters['id']!),
        ),
      ),

      // Check-in
      GoRoute(
        path: '/checkin/treinos',
        builder: (context, state) => const MeusTreinosScreen(),
      ),
      GoRoute(
        path: '/checkin/executar',
        builder: (context, state) =>
            CheckinScreen(treinoId: state.extra as int),
      ),
      GoRoute(
        path: '/checkin/historico',
        builder: (context, state) => const HistoricoCheckinScreen(),
      ),

      // Agenda aluno sub-route (agenda tab is now in shell)
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
        path: '/perfil/editar',
        builder: (context, state) => EditarPerfilScreen(
          perfil: state.extra as PerfilPersonal,
        ),
      ),
      GoRoute(
        path: '/perfil/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/identidade-visual',
        builder: (context, state) => const IdentidadeVisualScreen(),
      ),
      GoRoute(
        path: '/white-label',
        redirect: (context, state) => '/identidade-visual',
      ),
      GoRoute(
        path: '/setup/identidade',
        builder: (context, state) =>
            const IdentidadeVisualScreen(isSetup: true),
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
        builder: (context, state) => AlertaDetalheScreen(
          alunoId: int.parse(state.pathParameters['id']!),
          alunoNome: state.extra as String? ?? 'Aluno',
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
        builder: (context, state) => const PlanosScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/assinatura',
        builder: (context, state) => AssinaturaScreen(
          initialPlan: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/migracao-magica',
        builder: (context, state) => const MigracaoMagicaScreen(),
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
        builder: (context, state) => const GamificacaoScreen(),
      ),
      GoRoute(
        path: '/landing-config',
        builder: (context, state) => const LandingPageConfigScreen(),
      ),
    ],
  );
}
