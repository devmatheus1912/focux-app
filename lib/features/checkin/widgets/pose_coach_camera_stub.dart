import 'package:flutter/material.dart';

import '../../../core/widgets/feedback_helper.dart';

Future<void> openPoseCameraCoach(
  BuildContext context, {
  required String exerciseName,
  required Color brand,
  required VoidCallback onRep,
}) async {
  FeedbackHelper.showSnackBar(
    context,
    const SnackBar(content: Text('Coach com camera disponivel apenas no celular.')),
  );
}
