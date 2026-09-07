import 'package:flutter/material.dart';

import '../theme/fx_settings_layout.dart';
import '../theme/tokens_strip.dart';
import 'fx_keyboard_dismiss_scope.dart';

/// Footer sticky de S5: sobe com o teclado (§14.2).
class FxFormStickyBar extends StatelessWidget {
  const FxFormStickyBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          FxSettingsLayout.pageInset,
          TokensStrip.s3 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: child,
      ),
    );
  }
}

/// Back do SO: fecha teclado, depois confirma descarte se o form está sujo.
class FxFormPopGuard extends StatelessWidget {
  const FxFormPopGuard({
    super.key,
    required this.dirty,
    required this.onCancel,
    required this.child,
  });

  final bool dirty;
  final Future<void> Function() onCancel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return PopScope(
      canPop: !keyboardOpen && !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (keyboardOpen) {
          FxKeyboardDismissScope.dismiss();
          return;
        }
        await onCancel();
      },
      child: child,
    );
  }
}
