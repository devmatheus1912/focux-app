import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/ux/focux_feedback.dart';

void main() {
  test('UX feedback sources exist', () {
    for (final path in FocuxFeedback.uxSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
  });

  test('toast API catalog is complete', () {
    final helper =
        File('lib/core/widgets/feedback_helper.dart').readAsStringSync();
    for (final method in FocuxFeedback.toastMethods) {
      expect(helper, contains(method), reason: 'FeedbackHelper.$method ausente');
    }
  });
}
