import 'package:flutter/material.dart';
import 'package:focux_app/core/widgets/skeleton_loader.dart';

class WizardStepLoading extends StatelessWidget {
  const WizardStepLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carregando biblioteca curada...',
      child: const SkeletonList(count: 5),
    );
  }
}
