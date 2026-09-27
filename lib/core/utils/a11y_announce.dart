import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// Screen-reader announcement with a [BuildContext] (preferred).
void fxAnnounce(BuildContext context, String message) {
  SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    Directionality.of(context),
  );
}
