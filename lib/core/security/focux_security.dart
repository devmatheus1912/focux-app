/// Catálogo de segurança — tokens, transporte, erros seguros, disclaimers IA e
/// Hardening mobile & web. Gate: security_pillar_contract_test.
abstract final class FocuxSecurity {
  FocuxSecurity._();

  static const String version = '1.1.0';

  static const List<String> coreSources = [
    'lib/core/security/focux_security.dart',
    'lib/core/storage/secure_storage.dart',
    'lib/core/api/api_client.dart',
    'lib/core/api/tls_certificate_pinning.dart',
    'lib/core/auth/session_invalidator.dart',
    'lib/core/utils/friendly_error.dart',
    'lib/core/utils/clipboard_sensitive.dart',
    'lib/core/widgets/ia_safety_disclaimer.dart',
    'lib/features/assinatura/services/subscription_device_guard.dart',
  ];

  /// Artefatos Android/ProGuard no repo `focux-app` — CI sempre valida.
  static const List<String> androidHardeningSources = [
    'android/app/src/main/AndroidManifest.xml',
    'android/app/src/main/res/xml/network_security_config.xml',
    'android/app/src/main/res/xml/backup_rules.xml',
    'android/app/src/main/res/xml/data_extraction_rules.xml',
    'android/app/proguard-rules.pro',
  ];

  /// Docs e website no monorepo — testes rodam só se o path existir.
  static const List<String> monorepoHardeningSources = [
    'docs/FOCUX_DESIGN_REFERENCE.md',
    '../focux-website/vercel.json',
    '../focux-website/client/public/.well-known/assetlinks.json',
  ];

  static const List<String> androidManifestInvariants = [
    'android:usesCleartextTraffic="false"',
    'android:allowBackup="false"',
    'android:networkSecurityConfig="@xml/network_security_config"',
    'android:host="focuxpersonal.com"',
    'android:taskAffinity=""',
  ];

  static const List<String> networkSecurityInvariants = [
    'cleartextTrafficPermitted="false"',
  ];

  static const List<String> vercelHeaderInvariants = [
    'Strict-Transport-Security',
    'Content-Security-Policy',
    'Cross-Origin-Embedder-Policy',
    'credentialless',
    'https://focuxpersonal.com',
  ];

  static const List<String> assetLinksInvariants = [
    '"package_name": "com.focux.focux_app"',
    'sha256_cert_fingerprints',
    '3B:F3:A7:B9:2D:CF:0B:83:C4:89:25:78:36:BE:8B:49:2A:E9:20:28:36:EF:4C:96:51:F2:57:3D:07:5F:1E:F3',
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
    'test/core/api/tls_certificate_pinning_test.dart',
    'test/core/auth/session_invalidator_tenant_cache_test.dart',
    '.github/workflows/security.yml',
    '.github/workflows/semgrep.yml',
  ];

  static const List<String> forbiddenHubPatterns = [
    'FlutterSecureStorage',
    r'FeedbackHelper.showError(context, $e)',
    r"FeedbackHelper.showError(context, '$e')",
  ];
}
