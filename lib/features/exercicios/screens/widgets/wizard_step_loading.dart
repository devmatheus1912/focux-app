import 'package:flutter/material.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';

class WizardStepLoading extends StatelessWidget {
  const WizardStepLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FxLoading(),
          SizedBox(height: 16),
          Text('Carregando biblioteca curada...'),
        ],
      ),
    );
  }
}
