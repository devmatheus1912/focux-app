import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'fx_confirm_sheet.dart';

/// S8: tela acesa enquanto a execução está montada (§9).
class FxExecutionKeepAwake extends StatefulWidget {
  const FxExecutionKeepAwake({super.key, required this.child});

  final Widget child;

  @override
  State<FxExecutionKeepAwake> createState() => _FxExecutionKeepAwakeState();
}

class _FxExecutionKeepAwakeState extends State<FxExecutionKeepAwake> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Back do SO não descarta a execução sem o caller decidir.
class FxExecutionPopGuard extends StatelessWidget {
  const FxExecutionPopGuard({
    super.key,
    required this.onLeave,
    required this.child,
  });

  final Future<void> Function() onLeave;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        onLeave();
      },
      child: child,
    );
  }
}

Future<bool> fxConfirmLeaveExecution(
  BuildContext context, {
  required bool hasProgress,
}) async {
  if (!hasProgress) return true;
  return showFxConfirmSheet(
    context,
    title: 'Sair do treino?',
    message: 'O tempo e as séries já marcadas ficam salvos.',
    confirmLabel: 'Sair',
  );
}
