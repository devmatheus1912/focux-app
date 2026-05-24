import 'package:flutter/material.dart';

import '../../../core/widgets/mesh_scope.dart';
import '../../agenda/screens/agenda_screen.dart';
import '../../alertas/screens/alertas_screen.dart';
import '../../alunos/screens/acoes_massa_screen.dart';
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
import '../../planos/screens/planos_screen.dart';
import '../../suporte/screens/suporte_screen.dart';
import '../../treinos/screens/treinos_list_screen.dart';
import 'qa_preview_session.dart';

/// Builds smoke-test screen previews without GoRouter push/pop.
Widget buildQaRoutePreview(String path) {
  final uri = Uri.parse(path.startsWith('/') ? path : '/$path');
  final screen = _buildQaRouteScreen(uri);

  // MeshScope evita GoRouterState em FxRouteChrome e simula shell mesh.
  return MeshScope(active: true, child: screen);
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
    '/suporte' => const SuporteScreen(),
    '/growth/migracao' => const MigracaoMagicaScreen(),
    '/notificacoes' => const NotificacoesScreen(),
    '/analytics' => const AnalyticsScreen(),
    '/agenda' => const AgendaScreen(),
    '/gamificacao' => const GamificacaoScreen(),
    '/dashboard/qualidade' => const QualidadeOperacionalScreen(),
    '/planos' => const PlanosScreen(),
    '/kanban' => const AcoesMassaScreen(),
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
    this.showClose = true,
    super.key,
  });

  final String path;
  final bool showClose;

  static Future<String?> show(BuildContext context, String path) async {
    QaPreviewSession.begin();
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        useSafeArea: false,
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
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        useSafeArea: false,
        builder: (dialogContext) {
          Future<void>.delayed(hold, () {
            if (dialogContext.mounted &&
                Navigator.of(dialogContext, rootNavigator: true).canPop()) {
              Navigator.of(dialogContext, rootNavigator: true).pop();
            }
          });
          return QaRoutePreviewDialog(path: path, showClose: false);
        },
      );
      // Aguarda erros assíncronos de layout após fechar.
      await Future<void>.delayed(const Duration(milliseconds: 100));
    } finally {
      QaPreviewSession.end();
    }
    return QaPreviewSession.firstErrorOrNull();
  }

  @override
  Widget build(BuildContext context) {
    final preview = MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: Size(
          430,
          MediaQuery.sizeOf(context).height,
        ),
      ),
      child: ClipRect(child: buildQaRoutePreview(path)),
    );

    if (!showClose) {
      return Dialog.fullscreen(
        child: Stack(
          children: [
            Positioned.fill(child: preview),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.72),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'Testando: $path',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(path, style: const TextStyle(fontSize: 14)),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: preview,
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
