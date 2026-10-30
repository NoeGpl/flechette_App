import 'player.dart';
import 'dart_throw.dart';

/// Contient l’état commun d’une partie et les fonctions de calcul des scores.
class Game {
  /// Joueurs participant à la partie.
  List<Player> players;
  /// Index du joueur dont c’est le tour.
  int currentPlayerIndex;
  /// Identifiant du mode de jeu sélectionné.
  String mode;
  /// Score initial attribué à chaque joueur.
  int startingScore;
  /// Indique si un mode à décompte exige de terminer par un double.
  bool doubleOut;
  /// Indique si un mode à décompte exige un double pour commencer à marquer.
  bool doubleIn;
  /// Indices des joueurs ayant satisfait à la règle Double In.
  final Set<int> enteredPlayerIndices = {};

  /// Crée une partie et initialise le score de chaque joueur à [startingScore].
  Game({
    required this.players,
    required this.startingScore,
    required this.mode,
    this.doubleOut = false,
    this.doubleIn = false,
    this.currentPlayerIndex = 0,
  }) {
    for (var p in players) {
      p.score = startingScore;
    }
  }

  /// Joueur dont c’est actuellement le tour.
  Player get currentPlayer => players[currentPlayerIndex];

  /// Indique si [playerIndex] a satisfait à la règle Double In.
  bool hasEntered(int playerIndex) {
    return !doubleIn || enteredPlayerIndices.contains(playerIndex);
  }

  /// Enregistre que [playerIndex] a commencé la partie avec un double.
  void markEntered(int playerIndex) {
    enteredPlayerIndices.add(playerIndex);
  }

  /// Calcule le score de chaque tir en tenant compte de la règle Double In.
  List<int> scoreThrows(int playerIndex, List<DartThrow> throws) {
    var entered = hasEntered(playerIndex);

    return throws.map((dartThrow) {
      if (!entered && dartThrow.multiplier != 2) return 0;
      if (!entered) {
        entered = true;
        markEntered(playerIndex);
      }
      return dartThrow.score;
    }).toList();
  }

  /// Calcule les scores des [throws] qui touchent la cible Shanghai [target].
  List<int> scoreShanghaiThrows(int target, List<DartThrow> throws) {
    return throws
        .map((dartThrow) => scoreShanghaiThrow(target, dartThrow))
        .toList();
  }

  /// Attribue le score de [dartThrow] uniquement si le tir touche [target].
  int scoreShanghaiThrow(int target, DartThrow dartThrow) {
    return dartThrow.base == target ? dartThrow.score : 0;
  }

  /// Indique si [throws] comprennent un simple, un double et un triple sur [target].
  bool hasShanghai(int target, List<DartThrow> throws) {
    final multipliers = throws
        .where((dartThrow) => dartThrow.base == target)
        .map((dartThrow) => dartThrow.multiplier)
        .toSet();
    return multipliers.containsAll({1, 2, 3});
  }

  /// Passe au joueur suivant, puis revient au premier si nécessaire.
  void nextPlayer() {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
  }
}
