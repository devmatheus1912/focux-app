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

  test('real exceptions stay fatal', () {
    expect(isNonFatalFlutterFrameworkError(StateError('bad')), isFalse);
  });
}
