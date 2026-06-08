import 'dart:ui';

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

/// Screen-reader announcement when no [BuildContext] is available.
void fxAnnounceGlobal(
  String message, {
  TextDirection direction = TextDirection.ltr,
}) {
  final views = PlatformDispatcher.instance.views;
  if (views.isEmpty) return;
  SemanticsService.sendAnnouncement(views.first, message, direction);
}
