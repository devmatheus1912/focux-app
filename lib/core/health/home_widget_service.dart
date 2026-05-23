import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Updates iOS/Android home screen widget data after recovery sync.
class HomeWidgetService {
  HomeWidgetService._();

  static const _androidName = 'FocuxRecoveryWidgetProvider';
  static const _iosName = 'FocuxRecoveryWidget';
  static const _appGroupId = 'group.com.focux.focuxApp';

  static Future<void> init() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (_) {
      // Native widget extensions may not be configured yet.
    }
  }

  static Future<void> updateRecovery({
    required int recoveryScore,
    required String recoveryLabel,
    required String recoveryHint,
    required int steps,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    try {
      await HomeWidget.saveWidgetData<int>('recovery_score', recoveryScore);
      await HomeWidget.saveWidgetData<String>('recovery_label', recoveryLabel);
      await HomeWidget.saveWidgetData<String>('recovery_hint', recoveryHint);
      await HomeWidget.saveWidgetData<int>('steps', steps);
      await HomeWidget.updateWidget(
        name: _androidName,
        iOSName: _iosName,
      );
    } catch (_) {}
  }
}
