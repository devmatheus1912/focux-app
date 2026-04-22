import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/dashboard/screens/personal_dashboard_screen.dart';
import '../../features/dashboard/screens/aluno_dashboard_screen.dart';
import '../../features/alunos/screens/alunos_list_screen.dart';
import '../../features/alunos/screens/add_aluno_screen.dart';
import '../../features/alunos/screens/aluno_detail_screen.dart';
import '../../features/perfil/data/perfil_repository.dart';
import '../../features/perfil/screens/perfil_screen.dart';
import '../../features/perfil/screens/editar_perfil_screen.dart';
import '../../features/convites/screens/convites_screen.dart';
import '../../features/assinatura/screens/assinatura_screen.dart';
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
import '../../features/ia/screens/ia_chat_screen.dart';
import '../../features/leads/screens/leads_list_screen.dart';
import '../../features/alertas/screens/alertas_screen.dart';
import '../../features/evolucao/screens/evolucao_screen.dart';
import '../../features/ia/screens/ia_copiloto_screen.dart';
import '../../features/ia/screens/progressao_aceitar_screen.dart';
import '../../features/alunos/screens/editar_aluno_screen.dart';
import '../../features/alunos/data/aluno_repository.dart';
import '../../features/auth/screens/esqueci_senha_screen.dart';
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

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
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
        path: '/dashboard/personal',
        builder: (context, state) => const PersonalDashboardScreen(),
      ),
      GoRoute(
        path: '/dashboard/aluno',
        builder: (context, state) => const AlunoDashboardScreen(),
      ),
      GoRoute(
        path: '/dashboard/qualidade',
        builder: (context, state) => const QualidadeOperacionalScreen(),
      ),
      GoRoute(
        path: '/alunos',
        builder: (context, state) => const AlunosListScreen(),
      ),
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
        path: '/convites',
        builder: (context, state) => const ConvitesScreen(),
      ),
      GoRoute(
        path: '/planos',
        builder: (context, state) => const AssinaturaScreen(),
      ),
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
      GoRoute(
        path: '/treinos',
        builder: (context, state) => const TreinosListScreen(),
      ),
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
      GoRoute(
        path: '/checkin/treinos',
        builder: (context, state) => const MeusTreinosScreen(),
      ),
      GoRoute(
        path: '/checkin/executar',
        builder: (context, state) => CheckinScreen(treinoId: state.extra as int),
      ),
      GoRoute(
        path: '/checkin/historico',
        builder: (context, state) => const HistoricoCheckinScreen(),
      ),
      GoRoute(
        path: '/financeiro',
        builder: (context, state) => const FinanceiroScreen(),
      ),
      GoRoute(
        path: '/agenda',
        builder: (context, state) => const AgendaScreen(),
      ),
      GoRoute(
        path: '/alunos/:id/relatorio',
        builder: (context, state) => RelatorioScreen(
          alunoId: int.parse(state.pathParameters['id']!),
          alunoNome: state.extra as String? ?? 'Aluno',
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/feed',
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: '/feed/aluno',
        builder: (context, state) => const FeedAlunoScreen(),
      ),
      GoRoute(
        path: '/register/aluno',
        builder: (context, state) => const RegisterAlunoScreen(),
      ),
      GoRoute(
        path: '/chat/aluno',
        builder: (context, state) => const ChatAlunoScreen(),
      ),
      GoRoute(
        path: '/ia/chat',
        builder: (context, state) => const IaChatScreen(),
      ),
      GoRoute(
        path: '/leads',
        builder: (context, state) => const LeadsListScreen(),
      ),
      GoRoute(
        path: '/alertas',
        builder: (context, state) => const AlertasScreen(),
      ),
      GoRoute(
        path: '/alunos/:id/evolucao',
        builder: (context, state) => EvolucaoScreen(
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
        path: '/ia/aluno',
        builder: (context, state) => const IaAlunoScreen(),
      ),
      GoRoute(
        path: '/ia/copiloto',
        builder: (context, state) => const IaCopilotoScreen(),
      ),
      GoRoute(
        path: '/ia/progressao/aceitar',
        builder: (context, state) => const ProgressaoAceitarScreen(),
      ),
      GoRoute(
        path: '/alunos/:id/editar',
        builder: (context, state) => EditarAlunoScreen(
          aluno: state.extra as Aluno,
        ),
      ),
      GoRoute(
        path: '/esqueci-senha',
        builder: (context, state) => const EsqueciSenhaScreen(),
      ),
      GoRoute(
        path: '/ranking',
        builder: (context, state) => const RankingScreen(),
      ),
      GoRoute(
        path: '/identidade-visual',
        builder: (context, state) => const IdentidadeVisualScreen(),
      ),
      GoRoute(
        path: '/setup/identidade',
        builder: (context, state) => const IdentidadeVisualScreen(isSetup: true),
      ),
      GoRoute(
        path: '/financeiro/aluno',
        builder: (context, state) => const FinanceiroAlunoScreen(),
      ),
      GoRoute(
        path: '/suporte',
        builder: (context, state) => const SuporteScreen(),
      ),
      GoRoute(
        path: '/alertas/aluno/:id',
        builder: (context, state) => AlrtaDetalheScreen(
          alunoId: int.parse(state.pathParameters['id']!),
          alunoNome: state.extra as String? ?? 'Aluno',
        ),
      ),
      GoRoute(
        path: '/alertas/config',
        builder: (context, state) => const AlertasConfigScreen(),
      ),
      GoRoute(
        path: '/relatorios/global',
        builder: (context, state) => const RelatorioGlobalScreen(),
      ),
      GoRoute(
        path: '/alunos/:id/evolucao-comparativo',
        builder: (context, state) => EvolucaoComparativoScreen(
          alunoId: int.parse(state.pathParameters['id']!),
          alunoNome: state.extra as String? ?? 'Aluno',
        ),
      ),
      GoRoute(
        path: '/agenda/aluno',
        builder: (context, state) => const AgendaAlunoScreen(),
      ),
      GoRoute(
        path: '/feedback-videos',
        builder: (context, state) => const FeedbackVideoScreen(),
      ),
      GoRoute(
        path: '/alunos/:id/feedback-videos',
        builder: (context, state) => FeedbackVideoScreen(
          alunoId: int.parse(state.pathParameters['id']!),
          alunoNome: state.extra as String? ?? 'Aluno',
        ),
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
        path: '/alunos/:id/trilhas',
        builder: (context, state) => TrilhasScreen(
          alunoId: int.parse(state.pathParameters['id']!),
          alunoNome: state.extra as String? ?? 'Aluno',
        ),
      ),
      GoRoute(
        path: '/admin/rbac',
        builder: (context, state) => const RbacScreen(),
      ),
    ],
  );
}
