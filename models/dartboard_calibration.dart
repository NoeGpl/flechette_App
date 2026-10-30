import 'dart:math';

import 'dart_throw.dart';

/// Calibration d’une cible à partir du centre et du double du secteur 20.
class DartboardCalibration {
  /// Coordonnée horizontale normalisée du centre de la cible.
  final double centerX;

  /// Coordonnée verticale normalisée du centre de la cible.
  final double centerY;

  /// Coordonnée horizontale normalisée du bord extérieur du double 20.
  final double doubleTwentyX;

  /// Coordonnée verticale normalisée du bord extérieur du double 20.
  final double doubleTwentyY;

  /// Crée une calibration à partir de deux points normalisés de l’image.
  const DartboardCalibration({
    required this.centerX,
    required this.centerY,
    required this.doubleTwentyX,
    required this.doubleTwentyY,
  });

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

  /// Convertit une position normalisée en secteur et multiplicateur estimés.
  DartThrow scoreAt(double x, double y) {
    final referenceX = doubleTwentyX - centerX;
    final referenceY = doubleTwentyY - centerY;
    final radius = sqrt(referenceX * referenceX + referenceY * referenceY);
    if (radius <= 0) return DartThrow(base: 0, multiplier: 0);

    final dx = x - centerX;
    final dy = y - centerY;
    final distance = sqrt(dx * dx + dy * dy) / radius;

    if (distance > 1.324) return DartThrow(base: 0, multiplier: 0);
    if (distance <= 0.037) return DartThrow(base: 25, multiplier: 2);
    if (distance <= 0.094) return DartThrow(base: 25, multiplier: 1);

    final referenceAngle = atan2(referenceY, referenceX);
    final pointAngle = atan2(dy, dx);
    final relativeAngle = (pointAngle - referenceAngle + 2 * pi) % (2 * pi);
    final sectorIndex = ((relativeAngle + pi / 20) / (pi / 10)).floor() % 20;
    final sector = _sectors[sectorIndex];

    if (distance > 0.582 && distance <= 0.629) {
      return DartThrow(base: sector, multiplier: 3);
    }
    if (distance > 0.953 && distance <= 1) {
      return DartThrow(base: sector, multiplier: 2);
    }
    return DartThrow(base: sector, multiplier: 1);
  }
}
