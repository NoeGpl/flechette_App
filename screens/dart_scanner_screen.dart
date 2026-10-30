import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../models/dart_throw.dart';
import '../models/dartboard_calibration.dart';
import '../services/dart_detection_service.dart';

/// Écran de calibration et de détection des tirs par caméra.
class DartScannerScreen extends StatefulWidget {
  /// Nombre de tirs encore disponibles dans le tour.
  final int remainingDarts;

  /// Crée le scanner pour le nombre de tirs encore disponibles.
  const DartScannerScreen({super.key, required this.remainingDarts});

  @override
  State<DartScannerScreen> createState() => _DartScannerScreenState();
}

class _DartScannerScreenState extends State<DartScannerScreen> {
  static const double _duplicateDistance = 0.035;

  final DartDetectionService _detectionService = DartDetectionService();
  CameraController? _cameraController;
  String? _errorMessage;
  bool _isInitializing = true;
  bool _isScanning = false;
  bool _isProcessingFrame = false;
  DateTime _lastAnalysis = DateTime.fromMillisecondsSinceEpoch(0);
  Offset? _centerPoint;
  Offset? _doubleTwentyPoint;
  DartboardCalibration? _calibration;
  List<DetectedDart>? _startingDarts;
  final List<DetectedDart> _newDarts = [];

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  @override
  void dispose() {
    final controller = _cameraController;
    if (controller != null) {
      if (controller.value.isStreamingImages) {
        controller.stopImageStream();
      }
      controller.dispose();
    }
    _detectionService.dispose();
    super.dispose();
  }

  Future<void> _initializeScanner() async {
    CameraController? pendingController;
    try {
      if (kIsWeb ||
          (defaultTargetPlatform != TargetPlatform.android &&
              defaultTargetPlatform != TargetPlatform.iOS)) {
        throw UnsupportedError(
          'Le scanner en direct est disponible sur Android et iOS.',
        );
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('Aucune caméra n’est disponible sur cet appareil.');
      }
      final camera = cameras.firstWhere(
        (availableCamera) =>
            availableCamera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );
      pendingController = controller;
      await controller.initialize();
      await _detectionService.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _isInitializing = false;
      });
    } catch (error) {
      await pendingController?.dispose();
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Impossible de démarrer le scanner : $error';
        _isInitializing = false;
      });
    }
  }

  void _handleCalibrationTap(TapDownDetails details, Size previewSize) {
    final point = Offset(
      (details.localPosition.dx / previewSize.width).clamp(0.0, 1.0),
      (details.localPosition.dy / previewSize.height).clamp(0.0, 1.0),
    );
    setState(() {
      if (_centerPoint == null) {
        _centerPoint = point;
        return;
      }
      final distance = (point - _centerPoint!).distance;
      if (distance < 0.05) {
        _errorMessage =
            'Choisis le bord extérieur du double 20, pas le centre.';
        return;
      }
      _doubleTwentyPoint = point;
      _calibration = DartboardCalibration(
        centerX: _centerPoint!.dx,
        centerY: _centerPoint!.dy,
        doubleTwentyX: point.dx,
        doubleTwentyY: point.dy,
      );
      _errorMessage = null;
    });
  }

  Future<void> _startScanning() async {
    final controller = _cameraController;
    if (controller == null || _calibration == null || _isScanning) return;
    try {
      await controller.startImageStream(_processFrame);
      if (!mounted) return;
      setState(() {
        _isScanning = true;
        _startingDarts = null;
        _newDarts.clear();
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Impossible de lancer l’analyse : $error');
    }
  }

  Future<void> _processFrame(CameraImage cameraImage) async {
    final now = DateTime.now();
    if (_isProcessingFrame ||
        now.difference(_lastAnalysis) < const Duration(milliseconds: 800)) {
      return;
    }
    _isProcessingFrame = true;
    _lastAnalysis = now;
    try {
      final imageBytes = _convertFrameToJpeg(cameraImage);
      final detections = await _detectionService.detectDartLocationsFromBytes(
        imageBytes,
      );
      if (!mounted) return;

      setState(() {
        if (_startingDarts == null) {
          _startingDarts = detections;
          return;
        }
        for (final detection in detections) {
          if (_isNearAny(detection, _startingDarts!) ||
              _isNearAny(detection, _newDarts)) {
            continue;
          }
          if (_newDarts.length < widget.remainingDarts) {
            _newDarts.add(detection);
          }
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur pendant l’analyse de l’image : $error';
        _isScanning = false;
      });
      final controller = _cameraController;
      if (controller?.value.isStreamingImages ?? false) {
        await controller!.stopImageStream();
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  bool _isNearAny(DetectedDart dart, List<DetectedDart> others) {
    return others.any(
      (other) =>
          sqrt(pow(dart.x - other.x, 2) + pow(dart.y - other.y, 2)) <
          _duplicateDistance,
    );
  }

  Uint8List _convertFrameToJpeg(CameraImage cameraImage) {
    final converted = img.Image(
      width: cameraImage.width,
      height: cameraImage.height,
    );
    final planes = cameraImage.planes;
    if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      final plane = planes.first;
      final pixelStride = plane.bytesPerPixel ?? 4;
      for (var y = 0; y < cameraImage.height; y++) {
        for (var x = 0; x < cameraImage.width; x++) {
          final index = y * plane.bytesPerRow + x * pixelStride;
          converted.setPixelRgb(
            x,
            y,
            plane.bytes[index + 2],
            plane.bytes[index + 1],
            plane.bytes[index],
          );
        }
      }
    } else if (cameraImage.format.group == ImageFormatGroup.yuv420 &&
        planes.length >= 3) {
      final yPlane = planes[0];
      final uPlane = planes[1];
      final vPlane = planes[2];
      final uvPixelStride = uPlane.bytesPerPixel ?? 1;
      for (var y = 0; y < cameraImage.height; y++) {
        for (var x = 0; x < cameraImage.width; x++) {
          final yValue = yPlane.bytes[y * yPlane.bytesPerRow + x] - 16;
          final uvIndex =
              (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2) * uvPixelStride;
          final u = uPlane.bytes[uvIndex] - 128;
          final v =
              vPlane.bytes[(y ~/ 2) * vPlane.bytesPerRow +
                  (x ~/ 2) * (vPlane.bytesPerPixel ?? uvPixelStride)] -
              128;
          final luminance = max(0, yValue);
          converted.setPixelRgb(
            x,
            y,
            ((298 * luminance + 409 * v + 128) >> 8).clamp(0, 255),
            ((298 * luminance - 100 * u - 208 * v + 128) >> 8).clamp(0, 255),
            ((298 * luminance + 516 * u + 128) >> 8).clamp(0, 255),
          );
        }
      }
    } else {
      throw UnsupportedError(
        'Format caméra non pris en charge : ${cameraImage.format.group}.',
      );
    }

    final upright = img.copyRotate(
      converted,
      angle: _cameraController!.description.sensorOrientation,
    );
    return Uint8List.fromList(img.encodeJpg(upright, quality: 75));
  }

  void _resetCalibration() {
    setState(() {
      _centerPoint = null;
      _doubleTwentyPoint = null;
      _calibration = null;
      _errorMessage = null;
    });
  }

  void _confirmThrows() {
    final calibration = _calibration;
    if (calibration == null || _newDarts.isEmpty) return;
    final throws = _newDarts
        .take(widget.remainingDarts)
        .map((dart) => calibration.scoreAt(dart.x, dart.y))
        .toList();
    Navigator.of(context).pop(throws);
  }

  String _throwLabel(DartThrow dartThrow) {
    if (dartThrow.base == 0) return 'Manqué';
    if (dartThrow.base == 25) {
      return dartThrow.multiplier == 2 ? 'Bull double' : 'Bull simple';
    }
    final prefix = switch (dartThrow.multiplier) {
      2 => 'Double ',
      3 => 'Triple ',
      _ => 'Simple ',
    };
    return '$prefix${dartThrow.base}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner la cible'),
        actions: [
          if (_calibration != null && !_isScanning)
            IconButton(
              tooltip: 'Recommencer la calibration',
              onPressed: _resetCalibration,
              icon: const Icon(Icons.center_focus_weak),
            ),
        ],
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && controller == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_errorMessage!, textAlign: TextAlign.center),
              ),
            )
          : controller == null
          ? const SizedBox.shrink()
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1 / controller.value.aspectRatio,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final previewSize = Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );
                          return GestureDetector(
                            onTapDown: _calibration == null
                                ? (details) => _handleCalibrationTap(
                                    details,
                                    previewSize,
                                  )
                                : null,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CameraPreview(controller),
                                if (_centerPoint != null)
                                  _buildCalibrationMarker(
                                    _centerPoint!,
                                    previewSize,
                                    Colors.cyan,
                                  ),
                                if (_doubleTwentyPoint != null)
                                  _buildCalibrationMarker(
                                    _doubleTwentyPoint!,
                                    previewSize,
                                    Colors.amber,
                                  ),
                                if (_calibration != null)
                                  ..._newDarts.map(
                                    (dart) => _buildDetectionMarker(
                                      dart,
                                      previewSize,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _calibration == null
                            ? _centerPoint == null
                                  ? 'Calibration 1/2 : touche le centre du bull.'
                                  : 'Calibration 2/2 : touche le bord extérieur du double 20.'
                            : !_isScanning
                            ? 'Calibration terminée. Lance le suivi, puis lance tes fléchettes.'
                            : _startingDarts == null
                            ? 'Analyse de départ… les fléchettes déjà présentes ne seront pas comptées.'
                            : '${_newDarts.length} nouvelle(s) fléchette(s) détectée(s).',
                        textAlign: TextAlign.center,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (_isScanning && _calibration != null) ...[
                        const SizedBox(height: 8),
                        ..._newDarts.asMap().entries.map((entry) {
                          final dartThrow = _calibration!.scoreAt(
                            entry.value.x,
                            entry.value.y,
                          );
                          return Text(
                            'Tir ${entry.key + 1} : ${_throwLabel(dartThrow)}',
                            textAlign: TextAlign.center,
                          );
                        }),
                      ],
                      const SizedBox(height: 12),
                      if (!_isScanning)
                        ElevatedButton.icon(
                          onPressed: _calibration == null
                              ? null
                              : _startScanning,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Lancer le suivi'),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _newDarts.isEmpty ? null : _confirmThrows,
                          icon: const Icon(Icons.check),
                          label: const Text('Vérifier et valider les tirs'),
                        ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Annuler'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCalibrationMarker(Offset point, Size size, Color color) {
    return Positioned(
      left: point.dx * size.width - 12,
      top: point.dy * size.height - 12,
      child: IgnorePointer(child: Icon(Icons.add, color: color, size: 24)),
    );
  }

  Widget _buildDetectionMarker(DetectedDart dart, Size size) {
    return Positioned(
      left: dart.x * size.width - 10,
      top: dart.y * size.height - 10,
      child: IgnorePointer(
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.greenAccent, width: 2),
          ),
          child: const Center(
            child: Icon(Icons.circle, size: 6, color: Colors.greenAccent),
          ),
        ),
      ),
    );
  }
}
