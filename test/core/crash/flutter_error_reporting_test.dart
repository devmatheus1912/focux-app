import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/crash/flutter_error_reporting.dart';

void main() {
  test('layout overflow is not fatal Crashlytics noise', () {
    expect(
      isNonFatalFlutterFrameworkError(
        FlutterError('A RenderFlex overflowed by 16 pixels on the bottom.'),
      ),
      isTrue,
    );
  });

  test('unbounded flex and ParentData are not fatal', () {
    expect(
      isNonFatalFlutterFrameworkError(
        FlutterError(
          'RenderFlex children have non-zero flex but incoming constraints are unbounded.',
        ),
      ),
      isTrue,
    );
    expect(
      isNonFatalFlutterFrameworkError(
        FlutterError(
          'Incorrect use of ParentDataWidget. The ParentDataWidget Expanded wants to apply ParentData of type FlexParentData.',
        ),
      ),
      isTrue,
    );
  });

  test('deactivated inherited lookup is not fatal', () {
    expect(
      isNonFatalFlutterFrameworkError(
        FlutterError(
          'Looking up a deactivated widget\'s ancestor is unsafe.\n'
          'At this point the state of the widget\'s element tree is no longer stable.',
        ),
      ),
      isTrue,
    );
  });

  test('re-entrant layout debug assert is not fatal', () {
    expect(
      isNonFatalFlutterFrameworkError(
        FlutterError(
          "'package:flutter/src/rendering/object.dart': Failed assertion: "
          "line 2841 pos 12: '!_debugDoingThisLayout': is not true.",
        ),
      ),
      isTrue,
    );
  });

  test('S.of null-check is not fatal when stack points at l10n', () {
    expect(
      isNonFatalFlutterFrameworkError(
        FlutterError('Null check operator used on a null value.'),
        StackTrace.fromString(
          '#0      S.of (package:focux_app/l10n/app_localizations.dart:72:44)',
        ),
      ),
      isTrue,
    );
    expect(
      isNonFatalFlutterFrameworkError(
        FlutterError('Null check operator used on a null value.'),
      ),
      isFalse,
    );
  });

  test('real exceptions stay fatal', () {
    expect(isNonFatalFlutterFrameworkError(StateError('bad')), isFalse);
  });
}
