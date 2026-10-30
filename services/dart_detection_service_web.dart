import 'dart:typed_data';

import '../models/dart_throw.dart';

/// Fléchette potentielle détectée en coordonnées normalisées.
class DetectedDart {
  /// Coordonnée horizontale comprise entre 0 et 1.
  final double x;

  /// Coordonnée verticale comprise entre 0 et 1.
  final double y;

  /// Largeur normalisée de la boîte détectée.
  final double width;

  /// Hauteur normalisée de la boîte détectée.
  final double height;

  /// Niveau de confiance du modèle.
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

/// Implémentation web de la détection, où le modèle TFLite n’est pas disponible.
class DartDetectionService {
  /// Prépare le détecteur; cette méthode ne fait rien sur le web.
  Future<void> initialize() async {}

  /// Libère les ressources du détecteur; il n’y en a pas sur le web.
  void dispose() {}

  /// Signale que la détection de fléchettes à partir d’une image n’est pas prise en charge sur le web.
  Future<List<DartThrow>> detectFromBytes(Uint8List imageBytes) async {
    throw UnsupportedError(
      'La détection TFLite n\'est pas prise en charge sur le web.',
    );
  }

  /// Signale que la détection de positions n’est pas prise en charge sur le web.
  Future<List<DetectedDart>> detectDartLocationsFromBytes(
    Uint8List imageBytes,
  ) async {
    throw UnsupportedError(
      'La détection TFLite n\'est pas prise en charge sur le web.',
    );
  }
}
