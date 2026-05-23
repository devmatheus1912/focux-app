import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void safePopOrGo(BuildContext context, String fallbackLocation) {
  if (!context.mounted) return;
  if (context.canPop()) {
    context.pop();
    return;
  }
  final currentLocation = GoRouterState.of(context).uri.toString();
  if (_sameLocation(currentLocation, fallbackLocation)) {
    return;
  }
  context.go(fallbackLocation);
}

void safePopOr(BuildContext context, VoidCallback fallback) {
  if (!context.mounted) return;
  if (context.canPop()) {
    context.pop();
    return;
  }
  fallback();
}

bool _sameLocation(String currentLocation, String targetLocation) {
  final current = Uri.tryParse(currentLocation);
  final target = Uri.tryParse(targetLocation);
  if (current == null || target == null) {
    return currentLocation == targetLocation;
  }
  return current.path == target.path &&
      current.query == target.query &&
      current.fragment == target.fragment;
}

/// Switches a MainShell tab. Never `push` these paths from overlay routes
/// (/perfil, /convites, etc.) — that duplicates Navigator page keys.
void goPersonalShellTab(BuildContext context, String location) {
  if (!context.mounted) return;
  context.go(location);
}
