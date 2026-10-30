import '../models/player.dart';

/// Gère les scores des modes où le total diminue à partir d’un score initial.
class ScoringService {
  /// Soustrait [points] au score de [player], sans autoriser un score négatif.
  void addPoints(Player player, int points) {
    int newScore = player.score - points;

    if (newScore < 0) return; // règle darts : pas négatif

    player.score = newScore;
  }
}