import 'package:flutter/material.dart';

import 'fx_home_sheet.dart';

/// Alias estável — mesmo contrato da Home ([showFxHomeSheet]).
Future<T?> showFxBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showFxHomeSheet<T>(
    context,
    builder: builder,
    isScrollControlled: isScrollControlled,
  );
}
