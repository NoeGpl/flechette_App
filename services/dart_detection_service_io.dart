import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/dart_throw.dart';

/// Fléchette potentielle détectée, exprimée en coordonnées d’image normalisées.
class DetectedDart {
  /// Coordonnée horizontale comprise entre 0 et 1.
  final double x;

  /// Coordonnée verticale comprise entre 0 et 1.
  final double y;

  /// Largeur normalisée de la boîte détectée.
  final double width;

  /// Hauteur normalisée de la boîte détectée.
  final double height;

  /// Niveau de confiance du modèle pour cette détection.
  final double confidence;

  /// Crée une détection avec sa boîte et son niveau de confiance.
  DetectedDart({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.confidence,
  });
}

/// Charge le modèle TFLite et convertit les positions détectées en tirs.
class DartDetectionService {
  static const String _modelPath = 'assets/models/dart_detector_model.tflite';
  static const int _inputSize = 640;
  static const double _confidenceThreshold = 0.5;
  static const double _iouThreshold = 0.4;

  Interpreter? _interpreter;
  bool _isInitialized = false;

  static const List<int> _sectors = [
    20,
    1,
    18,
    4,
    13,
    6,
    10,
    15,
    2,
    17,
    3,
    19,
    7,
    16,
    8,
    11,
    14,
    9,
    12,
    5,
  ];

  /// Charge le modèle une seule fois pour les détections suivantes.
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(_modelPath, options: options);
      _isInitialized = true;
    } catch (e) {
      throw Exception(
        'Impossible de charger le modèle TFLite : $e\n'
        'Vérifie que tu as exporté un fichier .tflite et que tu l\'as placé dans assets/models/\n'
        'Assure-toi aussi que la version de tflite_flutter est compatible avec ta plateforme Android.',
      );
    }
  }

  /// Libère le modèle chargé afin de permettre une nouvelle initialisation.
  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }

  /// Détecte les fléchettes dans [imageBytes] et les convertit en scores.
  Future<List<DartThrow>> detectFromBytes(Uint8List imageBytes) async {
    final detections = await detectDartLocationsFromBytes(imageBytes);
    return _detectionsToThrows(detections);
  }

  /// Détecte les boîtes des fléchettes sans supposer que leur centre est la pointe.
  Future<List<DetectedDart>> detectDartLocationsFromBytes(
    Uint8List imageBytes,
  ) async {
    if (!_isInitialized) await initialize();

    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) throw Exception('Image invalide');

    final inputTensor = _preprocessImage(originalImage);
    return _runInference(inputTensor);
  }

  /// Lit [imageFile] et détecte les fléchettes qu’il contient.
  Future<List<DartThrow>> detectFromFile(File imageFile) async {
    return detectFromBytes(await imageFile.readAsBytes());
  }

  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    final resized = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
    );

    return [
      List.generate(_inputSize, (y) {
        return List.generate(_inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();
          return [r / 255.0, g / 255.0, b / 255.0];
        });
      }),
    ];
  }

  Future<List<DetectedDart>> _runInference(
    List<List<List<List<double>>>> input,
  ) async {
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final output = _createOutputTensor(outputShape);
    _interpreter!.run(input, output);
    return _parseYoloOutput(output);
  }

  dynamic _createOutputTensor(List<int> shape, [int dimension = 0]) {
    if (dimension == shape.length - 1) {
      return List<double>.filled(shape[dimension], 0);
    }
    return List.generate(
      shape[dimension],
      (_) => _createOutputTensor(shape, dimension + 1),
    );
  }

  List<DetectedDart> _parseYoloOutput(dynamic output) {
    final detections = <DetectedDart>[];
    final rawOutput = output[0] as List<dynamic>;
    if (rawOutput.isEmpty) return detections;
    final firstEntry = rawOutput.first as List<dynamic>;
    final isChannelFirst = rawOutput.length < firstEntry.length;
    final channelCount = isChannelFirst ? rawOutput.length : firstEntry.length;
    final boxCount = isChannelFirst ? firstEntry.length : rawOutput.length;

    double valueAt(int boxIndex, int channelIndex) {
      return isChannelFirst
          ? (rawOutput[channelIndex] as List<dynamic>)[boxIndex] as double
          : (rawOutput[boxIndex] as List<dynamic>)[channelIndex] as double;
    }

    for (var boxIndex = 0; boxIndex < boxCount; boxIndex++) {
      final confidence = channelCount > 5
          ? valueAt(boxIndex, 4) * valueAt(boxIndex, 5)
          : valueAt(boxIndex, 4);
      if (confidence < _confidenceThreshold) continue;
      detections.add(
        DetectedDart(
          x: valueAt(boxIndex, 0) / _inputSize,
          y: valueAt(boxIndex, 1) / _inputSize,
          width: valueAt(boxIndex, 2) / _inputSize,
          height: valueAt(boxIndex, 3) / _inputSize,
          confidence: confidence,
        ),
      );
    }

    return _applyNMS(detections);
  }

  List<DetectedDart> _applyNMS(List<DetectedDart> detections) {
    if (detections.isEmpty) return [];
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    final kept = <DetectedDart>[];

    for (final det in detections) {
      var suppressed = false;
      for (final k in kept) {
        final intersectionWidth = max(
          0.0,
          min(det.x + det.width / 2, k.x + k.width / 2) -
              max(det.x - det.width / 2, k.x - k.width / 2),
        );
        final intersectionHeight = max(
          0.0,
          min(det.y + det.height / 2, k.y + k.height / 2) -
              max(det.y - det.height / 2, k.y - k.height / 2),
        );
        final intersection = intersectionWidth * intersectionHeight;
        final union =
            det.width * det.height + k.width * k.height - intersection;
        if (union > 0 && intersection / union > _iouThreshold) {
          suppressed = true;
          break;
        }
      }
      if (!suppressed) kept.add(det);
    }

    return kept;
  }

  List<DartThrow> _detectionsToThrows(List<DetectedDart> detections) {
    return detections.map((d) => _calculateThrow(d.x, d.y)).toList();
  }

  DartThrow _calculateThrow(double normX, double normY) {
    const cx = 0.5;
    const cy = 0.5;
    final dx = normX - cx;
    final dy = normY - cy;
    final dist = sqrt(dx * dx + dy * dy) / 0.45;

    if (dist > 1.05) return DartThrow(base: 0, multiplier: 1);
    if (dist < 0.034) return DartThrow(base: 25, multiplier: 2);
    if (dist < 0.085) return DartThrow(base: 25, multiplier: 1);

    double angle = atan2(dx, -dy) * 180 / pi;
    if (angle < 0) angle += 360;
    final sectorIndex = ((angle + 9) / 18).floor() % 20;
    final sector = _sectors[sectorIndex];

    if (dist < 0.535) return DartThrow(base: sector, multiplier: 1);
    if (dist < 0.622) return DartThrow(base: sector, multiplier: 3);
    if (dist < 0.910) return DartThrow(base: sector, multiplier: 1);
    return DartThrow(base: sector, multiplier: 2);
  }
}
