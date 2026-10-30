/// Représente un tir avec le secteur touché et son multiplicateur.
class DartThrow {
  /// Valeur du secteur touché, 25 correspondant au centre de la cible.
  int base;

  /// Multiplicateur du tir : 1 pour un simple, 2 pour un double, 3 pour un triple.
  int multiplier;

  /// Crée un tir à partir du secteur [base] et de son [multiplier].
  DartThrow({required this.base, required this.multiplier});

  /// Renvoie le score brut du tir (`base * multiplier`).
  int get score => base * multiplier;
}
