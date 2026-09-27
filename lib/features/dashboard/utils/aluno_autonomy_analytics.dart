import 'dart:async';

import '../../../core/analytics/analytics_service.dart';
import '../../alunos/data/aluno_repository.dart';
import 'aluno_pendencias.dart';
import 'aluno_today_action.dart';

/// Evento do contrato `POST /api/aluno/autonomia/eventos`. O backend abre ação
/// no Centro de Comando do personal com `taskTitle` (pt fixo, não traduzir).
typedef AlunoAutonomyTask =
    ({String taskId, String taskTitle, String route, String priority});

class AlunoAutonomyAnalytics {
  AlunoAutonomyAnalytics._();

  static final Set<String> _vistosNaSessao = {};

  /// Só os modos em que o toque no P0 pede ação do personal.
  static AlunoAutonomyTask? forToday(AlunoTodayAction action) {
    final taskId = alunoAutonomyTaskIdForToday(action.mode);
    if (taskId == null) return null;
    final title = switch (action.mode) {
      AlunoTodayMode.financialHold => 'Regularizar financeiro',
      AlunoTodayMode.profileSetup => 'Completar perfil base',
      _ => 'Solicitar treino ativo',
    };
    return (
      taskId: taskId,
      taskTitle: title,
      route: action.route,
      priority: 'ALTA',
    );
  }

  static AlunoAutonomyTask forPendencia(AlunoPendencia p) => (
    taskId: p.tipo.taskId,
    taskTitle: p.tipo.taskTitlePt,
    route: p.tipo.route,
    priority: switch (p.tipo) {
      AlunoPendenciaTipo.foto => 'ALTA',
      AlunoPendenciaTipo.medida => p.primeiraVez ? 'ALTA' : 'MEDIA',
      AlunoPendenciaTipo.perfil || AlunoPendenciaTipo.chat => 'MEDIA',
      AlunoPendenciaTipo.agenda => 'BAIXA',
    },
  );

  /// `false` quando o `taskId` já foi registrado nesta sessão.
  static bool viewed(AlunoRepository repo, AlunoAutonomyTask task) {
    if (!_vistosNaSessao.add(task.taskId)) return false;
    _send(repo, task, 'VIEWED', ProductEvents.alunoAutonomyTaskViewed);
    return true;
  }

  static void clicked(AlunoRepository repo, AlunoAutonomyTask task) =>
      _send(repo, task, 'CLICKED', ProductEvents.alunoAutonomyTaskClicked);

  static void resetSessao() => _vistosNaSessao.clear();

  static void _send(
    AlunoRepository repo,
    AlunoAutonomyTask task,
    String action,
    String event,
  ) {
    unawaited(
      AnalyticsService.instance.track(
        event,
        props: {
          'taskId': task.taskId,
          'taskTitle': task.taskTitle,
          'route': task.route,
          'priority': task.priority.toLowerCase(),
          'done': false,
        },
      ),
    );
    unawaited(
      repo
          .registrarEventoAutonomia(
            taskId: task.taskId,
            taskTitle: task.taskTitle,
            action: action,
            route: task.route,
            priority: task.priority,
            done: false,
          )
          .catchError((_) {}),
    );
  }
}
