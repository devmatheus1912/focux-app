import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Layout / inherited-widget noise that Flutter reports as [FlutterError]
/// but does not kill the isolate. Sending these to Crashlytics as fatal
/// (or at all) inflates the dashboard.
bool isNonFatalFlutterFrameworkError(Object exception, [StackTrace? stack]) {
  final msg = '$exception\n${stack ?? ''}';
  const needles = <String>[
    'overflowed by',
    'RenderFlex children have non-zero flex',
    'Incorrect use of ParentDataWidget',
    'debugDeactivated',
    'Looking up a deactivated widget',
    'deactivated widget\'s ancestor',
    '_debugDoingThisLayout',
    'S.of',
    'app_localizations.dart',
    'google_fonts was unable to load font',
    '_httpFetchFontAndSaveToDevice',
  ];
  return needles.any(msg.contains);
}

Future<void> reportFlutterErrorToCrashlytics(FlutterErrorDetails details) {
  if (isNonFatalFlutterFrameworkError(details.exception, details.stack)) {
    debugPrint('[Focux] framework noise (not sent): ${details.exception}');
    return Future.value();
  }
  return FirebaseCrashlytics.instance.recordError(
    details.exception,
    details.stack,
    reason: details.context?.toString(),
    fatal: true,
  );
}

void reportUncaughtZoneError(Object error, StackTrace stack) {
  debugPrint('[Focux] Uncaught async error: $error');
  debugPrint('$stack');
  if (isNonFatalFlutterFrameworkError(error, stack)) return;
  try {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  } catch (_) {}
}
