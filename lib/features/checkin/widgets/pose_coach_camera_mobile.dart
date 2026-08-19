import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_home_sheet.dart';

Future<void> openPoseCameraCoach(
  BuildContext context, {
  required String exerciseName,
  required Color brand,
  required VoidCallback onRep,
}) async {
  if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
    FeedbackHelper.showWarn(
      context,
      'Coach com camera disponivel apenas no celular.',
    );
    return;
  }

  await showFxHomeSheet<void>(
    context,
    builder:
        (ctx) => _CameraCoachSheet(
          exerciseName: exerciseName,
          brand: brand,
          onRep: onRep,
        ),
  );
}

class _CameraCoachSheet extends StatefulWidget {
  const _CameraCoachSheet({
    required this.exerciseName,
    required this.brand,
    required this.onRep,
  });

  final String exerciseName;
  final Color brand;
  final VoidCallback onRep;

  @override
  State<_CameraCoachSheet> createState() => _CameraCoachSheetState();
}

class _CameraCoachSheetState extends State<_CameraCoachSheet> {
  CameraController? _controller;
  PoseDetector? _detector;
  bool _ready = false;
  String _status = 'Iniciando camera...';
  int _detectedReps = 0;
  double _lastElbowAngle = 180;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _status = 'Nenhuma camera encontrada.');
        return;
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await controller.initialize();

      _detector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
          model: PoseDetectionModel.accurate,
        ),
      );

      await controller.startImageStream((image) async {
        if (_processing || _detector == null) return;
        _processing = true;
        try {
          final input = _inputImageFromCameraImage(image);
          if (input == null) return;
          final poses = await _detector!.processImage(input);
          if (poses.isEmpty) return;
          _trackRep(poses.first);
        } catch (_) {
        } finally {
          _processing = false;
        }
      });

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _ready = true;
        _status =
            'Enquadre corpo inteiro. Flexione e estenda para contar reps.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Camera indisponivel.');
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final rotation = InputImageRotation.rotation0deg;
    final format = InputImageFormat.nv21;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void _trackRep(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    if (leftShoulder == null || leftElbow == null || leftWrist == null) return;

    final angle = _angle(
      Offset(leftShoulder.x, leftShoulder.y),
      Offset(leftElbow.x, leftElbow.y),
      Offset(leftWrist.x, leftWrist.y),
    );

    if (_lastElbowAngle > 130 && angle < 90) {
      if (!mounted) return;
      setState(() {
        _detectedReps++;
        _status = 'Rep $_detectedReps detectada via MediaPipe!';
      });
      widget.onRep();
      HapticFeedback.lightImpact();
    }
    _lastElbowAngle = angle;
  }

  double _angle(Offset a, Offset b, Offset c) {
    final ab = a - b;
    final cb = c - b;
    final dot = ab.dx * cb.dx + ab.dy * cb.dy;
    final mag = ab.distance * cb.distance;
    if (mag == 0) return 180;
    return math.acos((dot / mag).clamp(-1.0, 1.0)) * 180 / math.pi;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return FxHomeSheetSurface(
      isDark: isDark,
      expand: true,
      maxHeight:
          MediaQuery.sizeOf(context).height *
          FxHomeSheetChrome.expandHeightFactor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            title: 'MediaPipe · ${widget.exerciseName}',
            subtitle: _status,
            leading: Icon(Icons.videocam_outlined, color: primary, size: 18),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 280,
                    child:
                        _ready && _controller != null
                            ? CameraPreview(_controller!)
                            : Center(child: Text(_status)),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar coach'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
