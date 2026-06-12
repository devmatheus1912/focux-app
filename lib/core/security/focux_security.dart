/// Catálogo de segurança — tokens, transporte, erros seguros e disclaimers IA.
abstract final class FocuxSecurity {
  FocuxSecurity._();

  static const String version = '1.0.0';

  static const List<String> coreSources = [
    'lib/core/security/focux_security.dart',
    'lib/core/storage/secure_storage.dart',
    'lib/core/api/api_client.dart',
    'lib/core/api/tls_certificate_pinning.dart',
    'lib/core/auth/session_invalidator.dart',
    'lib/core/utils/friendly_error.dart',
    'lib/core/widgets/ia_safety_disclaimer.dart',
    'lib/features/assinatura/services/subscription_device_guard.dart',
  ];

  static const List<String> hubSecurityPatterns = [
    'friendlyError',
    'fxScreenA11yScope',
    'FeedbackHelper',
    '.when(',
    'IaSafetyDisclaimer',
  ];

  static const List<String> automatedGates = [
    'test/core/design_system/security_pillar_contract_test.dart',
    'test/core/design_system/ux_feedback_pillar_contract_test.dart',
    'test/core/router/routes_pillar_contract_test.dart',
    'test/core/ux/friendly_error_test.dart',
    '.github/workflows/security.yml',
    '.github/workflows/semgrep.yml',
  ];

  static const List<String> forbiddenHubPatterns = [
    'FlutterSecureStorage',
    r'FeedbackHelper.showError(context, $e)',
    r"FeedbackHelper.showError(context, '$e')",
  ];
}
