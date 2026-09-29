import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../navigation/focux_navigation.dart';

void safePopOrGo(
  BuildContext context,
  String fallbackLocation, {
  Object? result,
}) {
  if (!context.mounted) return;
  if (context.canPop()) {
    context.pop(result);
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

/// Dock tabs of the personal shell (query string ignored).
bool isPersonalShellTabLocation(String location) {
  final path = Uri.tryParse(location)?.path ?? location;
  return FocuxNavigation.shellTabPaths.contains(path);
}

/// Switches a MainShell tab. Never `push` these paths from overlay routes
/// (/perfil, /convites, etc.) — that duplicates Navigator page keys.
/// Stacked screens (/financeiro, /assinatura…) go through [openPersonalRoute].
void goPersonalShellTab(BuildContext context, String location) {
  assert(
    isPersonalShellTabLocation(location),
    'goPersonalShellTab só troca aba do dock; use openPersonalRoute: $location',
  );
  openPersonalRoute(context, location);
}

/// Dock tab → `go`; any other screen → `push`, so Voltar returns to origin.
void openPersonalRoute(BuildContext context, String location) {
  if (!context.mounted) return;
  if (isPersonalShellTabLocation(location)) {
    context.go(location);
  } else {
    context.push(location);
  }
}
