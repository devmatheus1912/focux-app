import 'package:flutter/material.dart';

import '../../../core/widgets/fx_error_state.dart';

/// Home error state — thin alias of canonical [FxErrorState].
class DashboardErrorState extends StatelessWidget {
  final bool chromeOnDark;
  final Color primary;
  final String message;
  final VoidCallback onRetry;

  const DashboardErrorState({
    super.key,
    required this.chromeOnDark,
    required this.primary,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return FxErrorState(
      chromeOnDark: chromeOnDark,
      primary: primary,
      message: message,
      onRetry: onRetry,
    );
  }
}
