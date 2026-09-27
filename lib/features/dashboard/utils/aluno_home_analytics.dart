import 'dart:async';

import '../../../core/analytics/analytics_service.dart';
import 'aluno_pendencias.dart';
import 'aluno_today_action.dart';

/// Funil da Home do aluno, espelho de `home_viewed` / `home_day_focus_action`.
abstract final class AlunoHomeAnalytics {
  static Map<String, Object?> viewedProps({
    required AlunoTodayAction action,
    required int pendencias,
    required AlunoHomeAviso aviso,
  }) => {
    'mode': action.mode.name,
    'comeback': action.comeback,
    'pendencias': pendencias,
    'aviso': aviso.name,
  };

  static Map<String, Object?> focusActionProps(AlunoTodayAction action) => {
    'mode': action.mode.name,
    'comeback': action.comeback,
    'route': action.route,
  };

  static void viewed({
    required AlunoTodayAction action,
    required int pendencias,
    required AlunoHomeAviso aviso,
  }) => unawaited(
    AnalyticsService.instance.track(
      ProductEvents.alunoHomeViewed,
      props: viewedProps(action: action, pendencias: pendencias, aviso: aviso),
    ),
  );

  static void focusAction(AlunoTodayAction action) => unawaited(
    AnalyticsService.instance.track(
      ProductEvents.alunoHomeFocusAction,
      props: focusActionProps(action),
    ),
  );
}
