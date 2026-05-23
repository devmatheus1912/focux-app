import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/design_tokens.dart';
import 'pose_coach_camera.dart';

/// Rep counter + optional MediaPipe camera coach during check-in.
class PoseCoachPanel extends StatefulWidget {
  const PoseCoachPanel({
    super.key,
    required this.exerciseName,
    required this.targetReps,
    required this.brand,
    required this.dark,
    required this.onRepCompleted,
  });

  final String exerciseName;
  final int? targetReps;
  final Color brand;
  final bool dark;
  final VoidCallback onRepCompleted;

  @override
  State<PoseCoachPanel> createState() => _PoseCoachPanelState();
}

class _PoseCoachPanelState extends State<PoseCoachPanel> {
  int _reps = 0;
  String? _formHint;

  void _registerRep() {
    HapticFeedback.lightImpact();
    setState(() => _reps++);
    widget.onRepCompleted();
    final target = widget.targetReps;
    if (target != null && _reps >= target) {
      HapticFeedback.mediumImpact();
      setState(() => _formHint = 'Serie completa — registre carga e feedback.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = widget.dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final target = widget.targetReps;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: widget.brand.withValues(alpha: widget.dark ? 0.12 : 0.06),
        border: Border.all(color: widget.brand.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.accessibility_new_rounded, color: widget.brand, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Coach de execucao',
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => openPoseCameraCoach(
                  context,
                  exerciseName: widget.exerciseName,
                  brand: widget.brand,
                  onRep: _registerRep,
                ),
                icon: const Icon(Icons.videocam_outlined, size: 16),
                label: const Text('Camera'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formHint ??
                'Conte reps com precisao. ${target != null ? 'Meta: $target.' : 'Toque +1 a cada repeticao.'}',
            style: TextStyle(color: mute, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _RepChip(label: 'Reps', value: '$_reps', brand: widget.brand),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: _reps > 0 ? () => setState(() => _reps--) : null,
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _registerRep,
                style: IconButton.styleFrom(backgroundColor: widget.brand),
                icon: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RepChip extends StatelessWidget {
  const _RepChip({required this.label, required this.value, required this.brand});

  final String label;
  final String value;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brand.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: brand.withValues(alpha: 0.8))),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: brand)),
        ],
      ),
    );
  }
}
