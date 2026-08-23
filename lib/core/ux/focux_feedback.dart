/// Catálogo de UX & feedback — fonte única para gates de mensagens e estados.
abstract final class FocuxFeedback {
  FocuxFeedback._();

  static const String version = '1.0.0';
  static const String defaultFallback = 'Algo deu errado. Tente novamente.';

  static const List<String> uxSources = [
    'lib/core/ux/focux_feedback.dart',
    'lib/core/widgets/feedback_helper.dart',
    'lib/core/widgets/fx_empty_state.dart',
    'lib/core/utils/friendly_error.dart',
  ];

  static const List<String> toastMethods = [
    'showSuccess',
    'showError',
    'showWarn',
    'showInfo',
    'showOperacaoSuccess',
    'showOperacaoWarn',
    'showOperacaoError',
  ];

  static const List<String> hubFeedbackPatterns = [
    'FeedbackHelper',
    'friendlyError',
    'FxEmptyState',
    'DashboardErrorState',
    '_erroIaTexto',
  ];
}
