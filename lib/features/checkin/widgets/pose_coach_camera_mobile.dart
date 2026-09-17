import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/feedback_helper.dart';

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

  // Full-screen — evita sheet aninhado em cima do sheet Postura (bug de layout).
  try {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder:
            (ctx) => _CameraCoachPage(
              exerciseName: exerciseName,
              brand: brand,
              onRep: onRep,
            ),
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    FeedbackHelper.showWarn(
      context,
      'Nao foi possivel abrir a camera agora.',
    );
  }
}

class _CameraCoachPage extends StatefulWidget {
  const _CameraCoachPage({
    required this.exerciseName,
    required this.brand,
    required this.onRep,
  });

  final String exerciseName;
  final Color brand;
  final VoidCallback onRep;

  @override
  State<_CameraCoachPage> createState() => _CameraCoachPageState();
}

class _CameraCoachPageState extends State<_CameraCoachPage> {
  CameraController? _controller;
  PoseDetector? _detector;
  bool _ready = false;
  bool _disposing = false;
  String _status = 'Iniciando camera...';
  int _detectedReps = 0;
  double _lastElbowAngle = 180;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initCamera());
  }

  Future<void> _safeStopStream(CameraController? controller) async {
    if (controller == null) return;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {}
  }

  Future<void> _safeDisposeController(CameraController? controller) async {
    if (controller == null) return;
    try {
      await _safeStopStream(controller);
    } catch (_) {}
    try {
      await controller.dispose();
    } catch (_) {}
  }

  bool _isPermissionDenied(Object error) {
    if (error is CameraException) {
      final code = error.code.toLowerCase();
      return code.contains('denied');
    }
    final msg = error.toString().toLowerCase();
    return msg.contains('permission') && msg.contains('denied');
  }

  Future<void> _initCamera() async {
    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (!mounted || _disposing) return;
      if (cameras.isEmpty) {
        setState(() => _status = 'Nenhuma camera encontrada.');
        return;
      }

      final preferred =
          cameras.where((c) => c.lensDirection == CameraLensDirection.front);
      final camera = preferred.isNotEmpty ? preferred.first : cameras.first;

      controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup:
            Platform.isAndroid
                ? ImageFormatGroup.nv21
                : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted || _disposing) {
        await _safeDisposeController(controller);
        return;
      }

      _detector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
          model: PoseDetectionModel.base,
        ),
      );

      await controller.startImageStream((image) async {
        if (_disposing || !mounted || _processing || _detector == null) {
          return;
        }
        _processing = true;
        try {
          final input = _inputImageFromCameraImage(image);
          if (input == null) return;
          final poses = await _detector!.processImage(input);
          if (_disposing || !mounted || poses.isEmpty) return;
          _trackRep(poses.first);
        } catch (_) {
        } finally {
          _processing = false;
        }
      });

      if (!mounted || _disposing) {
        await _safeDisposeController(controller);
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
        _status =
            'Enquadre corpo inteiro. Flexione e estenda para contar reps.';
      });
    } catch (e) {
      await _safeDisposeController(controller);
      if (!mounted || _disposing) return;
      setState(() {
        _ready = false;
        _controller = null;
        _status =
            _isPermissionDenied(e)
                ? 'Permissao de camera negada. Ative nas configuracoes do aparelho.'
                : 'Camera indisponivel.';
      });
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    try {
      if (image.planes.isEmpty) return null;
      final format =
          Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888;
      final plane = image.planes.first;
      final bytes =
          Platform.isAndroid
              ? _concatPlanes(image.planes)
              : plane.bytes;
      if (bytes == null) return null;
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Uint8List? _concatPlanes(List<Plane> planes) {
    try {
      final total = planes.fold<int>(0, (sum, p) => sum + p.bytes.length);
      final out = Uint8List(total);
      var offset = 0;
      for (final plane in planes) {
        out.setRange(offset, offset + plane.bytes.length, plane.bytes);
        offset += plane.bytes.length;
      }
      return out;
    } catch (_) {
      return null;
    }
  }

  void _trackRep(Pose pose) {
    if (_disposing || !mounted) return;
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
      if (!mounted || _disposing) return;
      setState(() {
        _detectedReps++;
        _status = 'Rep $_detectedReps detectada via MediaPipe!';
      });
      try {
        widget.onRep();
      } catch (_) {}
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
    _disposing = true;
    _ready = false;
    final controller = _controller;
    _controller = null;
    final detector = _detector;
    _detector = null;
    unawaited(() async {
      await _safeDisposeController(controller);
      try {
        await detector?.close();
      } catch (_) {}
    }());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final controller = _controller;
    final showPreview =
        _ready &&
        !_disposing &&
        controller != null &&
        controller.value.isInitialized;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName),
        leading: IconButton(
          tooltip: 'Fechar',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TokensStrip.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _status,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ColoredBox(
                    color: Colors.black,
                    child:
                        showPreview
                            ? CameraPreview(controller)
                            : Center(
                              child: Text(
                                _status,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Reps detectadas: $_detectedReps',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w800,
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
      ),
    );
  }
}
