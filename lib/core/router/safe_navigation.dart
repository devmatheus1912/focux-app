import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void safePopOrGo(BuildContext context, String fallbackLocation) {
  if (!context.mounted) return;
  if (context.canPop()) {
    context.pop();
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
