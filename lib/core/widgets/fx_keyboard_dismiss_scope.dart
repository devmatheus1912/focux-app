import 'package:flutter/widgets.dart';

/// Tap fora do campo fecha o teclado (§14.2). Uso canônico em S5/S6/S7.
class FxKeyboardDismissScope extends StatelessWidget {
  const FxKeyboardDismissScope({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  static void dismiss() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: dismiss,
      child: child,
    );
  }
}
