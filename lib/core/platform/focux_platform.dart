import 'package:flutter/material.dart';

/// Catálogo de adaptação de plataforma — breakpoints, safe area e shell.
abstract final class FocuxPlatform {
  FocuxPlatform._();

  static const String version = '1.0.0';

  /// Largura abaixo da qual o dock/shell usa layout compacto.
  static const double compactWidth = 390;

  /// Largura máxima do conteúdo em tablet/desktop.
  static const double desktopMaxContent = 960;

  /// Breakpoint para empilhar métricas em cards estreitos.
  static const double stackBreakpoint = 340;

  static const List<String> coreSources = [
    'lib/core/platform/focux_platform.dart',
    'lib/core/widgets/fx_content_width_limiter.dart',
    'lib/core/widgets/fx_shell_scaffold.dart',
    'lib/core/theme/shell_chrome.dart',
    'lib/core/screens/main_shell.dart',
    'lib/core/screens/aluno_shell.dart',
    'lib/core/theme/fx_page_transitions_builder.dart',
  ];

  static const List<String> moduleLayouts = [
    'lib/features/dashboard/constants/dashboard_layout.dart',
    'lib/features/alunos/constants/aluno_360_layout.dart',
  ];

  static const List<String> hubPlatformPatterns = [
    'ShellChrome',
    'MediaQuery',
    'FxContentWidthLimiter',
    'FxShellScaffold',
    'SafeArea',
    'FocuxPlatform',
    'DashboardLayout',
    'Aluno360Layout',
  ];

  static const List<String> automatedGates = [
    'test/core/design_system/platform_adaptation_pillar_contract_test.dart',
    'test/core/design_system/spacing_layout_pillar_contract_test.dart',
  ];

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactWidth;

  static bool shouldStackMetrics(BuildContext context) =>
      MediaQuery.sizeOf(context).width < stackBreakpoint;

  static double safeBottomInset(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom;

  static double safeTopInset(BuildContext context) =>
      MediaQuery.paddingOf(context).top;

  static double keyboardInset(BuildContext context) =>
      MediaQuery.viewInsetsOf(context).bottom;
}
