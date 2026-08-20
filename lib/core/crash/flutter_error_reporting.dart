import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Layout / inherited-widget noise that Flutter reports as [FlutterError]
/// but does not kill the isolate. Recording these as fatal inflates Crashlytics.
bool isNonFatalFlutterFrameworkError(Object exception) {
  final msg = exception.toString();
  const needles = <String>[
    'overflowed by',
    'RenderFlex children have non-zero flex',
    'Incorrect use of ParentDataWidget',
    'debugDeactivated',
    'Looking up a deactivated widget',
    'deactivated widget\'s ancestor',
  ];
  return needles.any(msg.contains);
}

Future<void> reportFlutterErrorToCrashlytics(FlutterErrorDetails details) {
  return FirebaseCrashlytics.instance.recordError(
    details.exception,
    details.stack,
    reason: details.context?.toString(),
    fatal: !isNonFatalFlutterFrameworkError(details.exception),
  );
}

void reportUncaughtZoneError(Object error, StackTrace stack) {
  debugPrint('[Focux] Uncaught async error: $error');
  debugPrint('$stack');
  try {
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: !isNonFatalFlutterFrameworkError(error),
    );
  } catch (_) {}
}
