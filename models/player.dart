/// Regroupe l’identité d’un joueur, son score et l’historique de ses tours.
class Player {
  /// Nom affiché dans l’interface de jeu.
  String name;

  /// Score actuel du joueur.
  int score;

  /// Scores de chaque fléchette, regroupés par tour pour les statistiques et les limites de tours.
  List<List<int>> turns = [];

  /// Crée un joueur avec le [name] et le [score] initial indiqués.
  Player({
    required this.name,
    required this.score,
  });

  /// Nombre moyen de points marqués par tour terminé.
  double get averagePerTurn {
    if (turns.isEmpty) return 0;

    int total = turns
        .map((t) => t.fold(0, (a, b) => a + b))
        .reduce((a, b) => a + b);

    return total / turns.length;
  }

  /// Nombre moyen de points marqués par fléchette enregistrée dans [turns].
  double get averagePerDart {
    int darts = turns.fold(0, (a, t) => a + t.length);
    if (darts == 0) return 0;

    int total = turns
        .map((t) => t.fold(0, (a, b) => a + b))
        .reduce((a, b) => a + b);

    return total / darts;
  }
}