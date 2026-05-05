import 'package:flutter/material.dart';

class WizardStepLoading extends StatelessWidget {
  const WizardStepLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Carregando biblioteca curada...'),
        ],
      ),
    );
  }
}
