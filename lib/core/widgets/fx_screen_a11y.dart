import 'package:flutter/material.dart';

/// Root accessibility scope for feature screens (VoiceOver / TalkBack).
Widget fxScreenA11yScope({
  required String label,
  required Widget child,
  bool explicitChildNodes = true,
}) {
  return Semantics(
    container: true,
    label: label,
    explicitChildNodes: explicitChildNodes,
    child: child,
  );
}
