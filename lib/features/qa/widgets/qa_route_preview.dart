import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/mesh_scope.dart';
import '../data/qa_smoke_catalog.dart';
import '../../agenda/screens/agenda_screen.dart';
import '../../alertas/screens/alertas_screen.dart';
import '../../alunos/screens/add_aluno_screen.dart';
import '../../alunos/screens/alunos_list_screen.dart';
import '../../analytics/screens/analytics_screen.dart';
import '../../auth/screens/esqueci_senha_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/register_aluno_screen.dart';
import '../../auth/screens/register_screen.dart';
import '../../broadcasts/screens/broadcast_screen.dart';
import '../../chat/screens/chat_aluno_screen.dart';
import '../../chat/screens/chat_inbox_screen.dart';
import '../../checkin/screens/meus_treinos_screen.dart';
import '../../dashboard/screens/aluno_dashboard_screen.dart';
import '../../dashboard/screens/personal_dashboard_screen.dart';
import '../../dashboard/screens/qualidade_operacional_screen.dart';
import '../../exercicios/screens/exercicios_list_screen.dart';
import '../../feed/screens/feed_aluno_screen.dart';
import '../../feed/screens/feed_screen.dart';
import '../../financeiro/screens/financeiro_screen.dart';
import '../../gamificacao/screens/gamificacao_screen.dart';
import '../../growth/screens/migracao_magica_screen.dart';
import '../../ia/screens/ia_copiloto_screen.dart';
import '../../notificacoes/screens/notificacoes_screen.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../../perfil/screens/perfil_screen.dart';
import '../../assinatura/screens/assinatura_screen.dart';
import '../../suporte/screens/suporte_web_redirect_screen.dart';
import '../../treinos/screens/treinos_list_screen.dart';
import 'qa_preview_session.dart';

/// Builds smoke-test screen previews with GoRouter + mesh for QA pumps.
Widget buildQaRoutePreview(String path) => buildQaRoutePreviewApp(path);

/// Router harness for widget tests — screens de auth leem [GoRouterState].
GoRouter buildQaPreviewRouter(String initialLocation) {
  final normalized =
      initialLocation.startsWith('/') ? initialLocation : '/$initialLocation';
  final paths = {
    for (final route in qaSmokeRoutes) route.path.split('?').first,
  };

  return GoRouter(
    initialLocation: normalized,
    routes: [
      for (final path in paths)
        GoRoute(
          path: path,
          builder:
              (context, state) => MeshScope(
                active: true,
                child: _buildQaRouteScreen(state.uri),
              ),
        ),
    ],
  );
}

Widget buildQaRoutePreviewApp(String path) {
  return MaterialApp.router(routerConfig: buildQaPreviewRouter(path));
}

Widget _buildQaRouteScreen(Uri uri) {
  return switch (uri.path) {
    '/login' => const LoginScreen(),
    '/register' => const RegisterScreen(),
    '/register/aluno' => RegisterAlunoScreen(
      personalSlug: uri.queryParameters['p'],
    ),
    '/esqueci-senha' => const EsqueciSenhaScreen(),
    '/onboarding' => const OnboardingScreen(),
    '/dashboard/personal' => const PersonalDashboardScreen(),
    '/perfil' => const PerfilScreen(),
    '/configuracoes' => const PerfilScreen(),
    '/alunos' => AlunosListScreen(
      initialFiltro: _alunoFiltroFromQuery(uri.queryParameters['filtro']),
    ),
    '/alunos/novo' => const AddAlunoScreen(),
    '/treinos' => const TreinosListScreen(),
    '/financeiro' => const FinanceiroScreen(),
    '/chat/inbox' => const ChatInboxScreen(),
    '/ia/copiloto' => const IaCopilotoScreen(),
    '/ia/checkin' => const IaCopilotoScreen(),
    '/feed' => const FeedScreen(),
    '/exercicios' => const ExerciciosListScreen(),
    '/broadcasts' => const BroadcastScreen(),
    '/suporte' => const SuporteWebRedirectScreen(),
    '/growth/migracao' => const MigracaoMagicaScreen(),
    '/notificacoes' => const NotificacoesScreen(),
    '/analytics' => const AnalyticsScreen(),
    '/agenda' => const AgendaScreen(),
    '/gamificacao' => const GamificacaoScreen(),
    '/dashboard/qualidade' => const QualidadeOperacionalScreen(),
    '/planos' => const AssinaturaScreen(),
    '/paywall' => const AssinaturaScreen(),
    '/assinatura' => const AssinaturaScreen(),
    '/kanban' => const AlunosListScreen(),
    '/alertas' => const AlertasScreen(),
    '/dashboard/aluno' => const AlunoDashboardScreen(),
    '/checkin/treinos' => const MeusTreinosScreen(),
    '/feed/aluno' => const FeedAlunoScreen(),
    '/chat/aluno' => const ChatAlunoScreen(),
    '/evolucao' => const AlunoDashboardScreen(),
    _ => throw UnsupportedError('QA preview nao mapeado: ${uri.path}'),
  };
}

/// Full-screen QA preview — isolated from GoRouter stack.
class QaRoutePreviewDialog extends StatelessWidget {
  const QaRoutePreviewDialog({
    required this.path,
    super.key,
  });

  final String path;

  static Future<String?> show(BuildContext context, String path) async {
    QaPreviewSession.begin();
    try {
      await showFxHomeSheet<void>(
        context,
        builder: (dialogContext) => QaRoutePreviewDialog(path: path),
      );
    } finally {
      QaPreviewSession.end();
    }
    return QaPreviewSession.firstErrorOrNull();
  }

  /// Auto-closes after [hold] — used by batch smoke runner.
  static Future<String?> showTimed(
    BuildContext context,
    String path, {
    Duration hold = const Duration(milliseconds: 1200),
  }) async {
    QaPreviewSession.begin();
    try {
      await showFxHomeSheet<void>(
        context,
        builder: (dialogContext) {
          Future<void>.delayed(hold, () {
            if (dialogContext.mounted &&
                Navigator.of(dialogContext, rootNavigator: true).canPop()) {
              FxHomeSheetChrome.dismissAndPop(dialogContext);
            }
          });
          return QaRoutePreviewDialog(path: path);
        },
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    } finally {
      QaPreviewSession.end();
    }
    return QaPreviewSession.firstErrorOrNull();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preview = MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(size: Size(430, MediaQuery.sizeOf(context).height)),
      child: ClipRect(child: buildQaRoutePreview(path)),
    );

    return FxHomeSheetSurface(
      isDark: isDark,
      expand: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            title: 'Testando',
            subtitle: path,
            leading: const Icon(Icons.bug_report_outlined, size: 18),
          ),
          SizedBox(height: TokensStrip.s3),
          Expanded(child: preview),
        ],
      ),
    );
  }
}

AlunoFiltro _alunoFiltroFromQuery(String? value) {
  return switch (value?.trim().toLowerCase()) {
    'ativos' => AlunoFiltro.ativos,
    'inadimplentes' => AlunoFiltro.inadimplentes,
    'risco' => AlunoFiltro.risco,
    'contato' || 'contato-hoje' || 'contatohoje' => AlunoFiltro.contatoHoje,
    'novos' => AlunoFiltro.novos,
    _ => AlunoFiltro.todos,
  };
}
