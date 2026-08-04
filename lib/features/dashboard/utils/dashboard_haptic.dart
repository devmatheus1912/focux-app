import 'package:flutter/services.dart';

/// Feedback tátil leve em colapsáveis e toggles da Home.
void dashboardHapticCollapseToggle() {
  HapticFeedback.selectionClick();
}

/// Feedback ao ligar/desligar modo foco.
void dashboardHapticFocusToggle() {
  HapticFeedback.lightImpact();
}
