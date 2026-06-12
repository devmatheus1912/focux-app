/// Catálogo de navegação e arquitetura de features — GoRouter + camadas.
abstract final class FocuxNavigation {
  FocuxNavigation._();

  static const String version = '1.0.0';

  static const List<String> coreSources = [
    'lib/core/navigation/focux_navigation.dart',
    'lib/core/router/safe_navigation.dart',
    'lib/core/router/role_home.dart',
    'lib/core/router/fx_page_transition.dart',
    'lib/core/router/app_router.dart',
  ];

  static const List<String> hubNavigationPatterns = [
    'safe_navigation.dart',
    'safePopOrGo',
    'safePopOr',
    'goPersonalShellTab',
    'goToRoleHome',
    'context.push',
    'context.go',
  ];

  static const List<String> hubArchitecturePatterns = [
    'ref.watch',
    'providers/',
  ];

  static const List<String> shellTabPaths = [
    '/dashboard/personal',
    '/alunos',
    '/treinos',
    '/agenda',
    '/ia/copiloto',
  ];

  static const List<String> automatedGates = [
    'test/core/router/routes_pillar_contract_test.dart',
    'test/core/design_system/navigation_architecture_pillar_contract_test.dart',
  ];
}
