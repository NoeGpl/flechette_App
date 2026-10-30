import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/game.dart';
import '../models/dart_throw.dart';
import 'dart_scanner_screen.dart';
import 'mode_selection_screen.dart';
import 'victory_screen.dart';

/// Gère une partie de fléchettes avec les joueurs et le mode sélectionnés.
class GameScreen extends StatefulWidget {
  /// Joueurs participant à la partie.
  final List<Player> players;

  /// Nom du mode de jeu sélectionné.
  final String mode;

  /// Indique si les modes à décompte exigent un double pour terminer.
  final bool doubleOut;

  /// Indique si les modes à décompte exigent un double pour commencer à marquer.
  final bool doubleIn;

  /// Crée l’écran de partie avec ses joueurs, son mode et ses règles.
  const GameScreen({
    super.key,
    required this.players,
    required this.mode,
    required this.doubleOut,
    required this.doubleIn,
  });

  /// Crée l’objet qui gère l’état de cet écran.
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _CricketTurnResult {
  final List<List<int>> marks;
  final List<int> dartPoints;

  /// Regroupe les marques calculées et les points de chaque fléchette.
  const _CricketTurnResult({required this.marks, required this.dartPoints});

  /// Calcule le total des points produits par les fléchettes du tour.
  int get totalPoints => dartPoints.fold(0, (total, points) => total + points);
}

class _GameScreenState extends State<GameScreen> {
  // État de partie conservé entre les reconstructions de l’interface.
  late Game game;
  List<DartThrow> turn = [];
  List<List<int>> _cricketMarks = [];
  int _shanghaiTarget = 1;
  int _turnReset = 0;
  bool _isDetecting = false;
  int selectedMultiplier = 1;

  final ScrollController _playerScrollController = ScrollController();

  static final List<int> _scoreButtons = [
    ...List.generate(20, (index) => index + 1),
    25,
  ];
  static const List<int> _cricketScoreButtons = [20, 19, 18, 17, 16, 15, 25];
  static const List<Color> _cricketPlayerColors = [
    Colors.amber,
    Colors.red,
    Colors.blue,
    Colors.green,
  ];

  /// Indique si la partie utilise les règles Shanghai.
  bool get _isShanghai =>
      widget.mode == 'Shanghaï' || widget.mode == 'Shanghai';

  /// Indique si la partie utilise les règles Cricket.
  bool get _isCricket => widget.mode == 'Cricket';

  /// Distingue les modes à décompte pour adapter l’espace de l’écran.
  bool get _isCountdown =>
      widget.mode == '301' || widget.mode == '401' || widget.mode == '501';

  /// Initialise la partie et les marques propres au mode Cricket.
  @override
  void initState() {
    super.initState();
    _cricketMarks = List.generate(
      widget.players.length,
      (_) => List<int>.filled(7, 0),
    );
    if (widget.mode == '301' || widget.mode == '401' || widget.mode == '501') {
      game = Game(
        players: widget.players,
        startingScore: int.parse(widget.mode),
        mode: widget.mode,
        doubleOut: widget.doubleOut,
        doubleIn: widget.doubleIn,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentPlayer();
      });
    } else {
      game = Game(
        players: widget.players,
        startingScore: 0,
        mode: widget.mode,
        doubleOut: widget.doubleOut,
        doubleIn: widget.doubleIn,
      );
    }
  }

  /// Libère le contrôleur de défilement lorsque l’écran est fermé.
  @override
  void dispose() {
    _playerScrollController.dispose();
    super.dispose();
  }

  /// Lance la détection, fait confirmer les tirs, puis valide le tour.
  Future<void> _scanDarts() async {
    // Une manche ne peut contenir que trois fléchettes au maximum.
    if (turn.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('3 fléchettes déjà enregistrées')),
      );
      return;
    }

    setState(() => _isDetecting = true);

    try {
      final detected = await Navigator.of(context).push<List<DartThrow>>(
        MaterialPageRoute(
          builder: (_) => DartScannerScreen(remainingDarts: 3 - turn.length),
        ),
      );
      if (detected == null || detected.isEmpty) return;
      // Ignore tout résultat excédentaire renvoyé par le scanner.
      final toAdd = detected.take(3 - turn.length).toList();
      if (!mounted) return;
      final confirmedThrows = await _showDetectionConfirm(toAdd);
      if (confirmedThrows == null) return;

      setState(() {
        turn.addAll(confirmedThrows);
      });
      if (_isCricket) {
        _endCricketTurn();
      } else {
        endTurn();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur détection : $e')));
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  /// Permet de corriger les secteurs et multiplicateurs détectés avant validation.
  Future<List<DartThrow>?> _showDetectionConfirm(
    List<DartThrow> detected,
  ) async {
    // Les copies évitent de modifier les données de détection avant confirmation.
    final confirmedThrows = detected
        .map(
          (dartThrow) =>
              DartThrow(base: dartThrow.base, multiplier: dartThrow.multiplier),
        )
        .toList();
    return await showDialog<List<DartThrow>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final displayedPoints = _isCricket
              ? _cricketTurnResult([
                  ...turn,
                  ...confirmedThrows,
                ]).dartPoints.skip(turn.length).toList()
              : confirmedThrows.map(_scoreOfThrow).toList();
          final totalPoints = displayedPoints.fold<int>(
            0,
            (total, points) => total + points,
          );

          return AlertDialog(
            backgroundColor: const Color(0xFF121212),
            title: const Text('Vérifier les tirs détectés'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (
                      var index = 0;
                      index < confirmedThrows.length;
                      index++
                    ) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.adjust, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _throwLabel(confirmedThrows[index]),
                                ),
                              ),
                              Text(
                                _isCricket
                                    ? '+${displayedPoints[index]} pts'
                                    : '${displayedPoints[index]} pts',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Secteur'),
                                    DropdownButton<int>(
                                      isExpanded: true,
                                      value: confirmedThrows[index].base,
                                      items: [
                                        const DropdownMenuItem(
                                          value: 0,
                                          child: Text('Miss'),
                                        ),
                                        for (var base = 1; base <= 20; base++)
                                          DropdownMenuItem(
                                            value: base,
                                            child: Text('$base'),
                                          ),
                                        const DropdownMenuItem(
                                          value: 25,
                                          child: Text('Bull'),
                                        ),
                                      ],
                                      onChanged: (base) {
                                        if (base == null) return;
                                        setDialogState(() {
                                          confirmedThrows[index].base = base;
                                          if (base == 0) {
                                            confirmedThrows[index].multiplier =
                                                0;
                                          } else if (base == 25 &&
                                              confirmedThrows[index]
                                                      .multiplier ==
                                                  3) {
                                            confirmedThrows[index].multiplier =
                                                2;
                                          } else if (confirmedThrows[index]
                                                  .multiplier ==
                                              0) {
                                            confirmedThrows[index].multiplier =
                                                1;
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Zone'),
                                    DropdownButton<int>(
                                      isExpanded: true,
                                      value: confirmedThrows[index].multiplier,
                                      items: [
                                        for (final multiplier
                                            in confirmedThrows[index].base == 0
                                                ? [0]
                                                : confirmedThrows[index].base ==
                                                      25
                                                ? [1, 2]
                                                : [1, 2, 3])
                                          DropdownMenuItem(
                                            value: multiplier,
                                            child: Text(
                                              multiplier == 0
                                                  ? 'Miss'
                                                  : multiplier == 1
                                                  ? 'Simple'
                                                  : multiplier == 2
                                                  ? 'Double'
                                                  : 'Triple',
                                            ),
                                          ),
                                      ],
                                      onChanged: (multiplier) {
                                        if (multiplier == null) return;
                                        setDialogState(() {
                                          confirmedThrows[index].multiplier =
                                              multiplier;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12),
                    ],
                    Text(
                      'Total : $totalPoints pts',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Le score est estimé à partir du centre de la fléchette. Corrige-le si nécessaire avant de valider le tour.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Recommencer'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(
                  context,
                  confirmedThrows
                      .map(
                        (dartThrow) => DartThrow(
                          base: dartThrow.base,
                          multiplier: dartThrow.multiplier,
                        ),
                      )
                      .toList(),
                ),
                child: const Text('Valider le tour'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Ajoute un tir manuel validé au tour en cours.
  void addScore(int base, int multiplier) {
    if (turn.length >= 3) return;
    final isMiss =
        (_isShanghai && base == _shanghaiTarget && multiplier == 0) ||
        (_isCricket && base == 0 && multiplier == 0);
    if ((!isMiss && (multiplier < 1 || multiplier > 3)) ||
        (base < 1 && !isMiss) ||
        (base > 20 && base != 25) ||
        (base == 25 && multiplier == 3)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Score de fléchette invalide')),
      );
      return;
    }

    setState(() {
      turn.add(DartThrow(base: base, multiplier: multiplier));
      // Un multiplicateur choisi est à usage unique ; les prochains tirs sont simples.
      selectedMultiplier = 1;
    });
  }

  /// Convertit un secteur Cricket en indice dans les listes de marques.
  int _cricketTargetIndex(int base) {
    if (base == 25) return 6;
    if (base >= 15 && base <= 20) return base - 15;
    return -1;
  }

  /// Applique un tir de Cricket à [marks] et renvoie les points gagnés.
  ///
  /// Chaque secteur est limité à trois marques. Les marques supplémentaires
  /// rapportent des points tant qu’au moins un adversaire ne l’a pas fermé.
  int scoreCricket(
    int base,
    int multiplier,
    int player, {
    required List<List<int>> marks,
  }) {
    final targetIndex = _cricketTargetIndex(base);
    if (!_isCricket ||
        targetIndex < 0 ||
        multiplier < 1 ||
        multiplier > 3 ||
        player < 0 ||
        player >= marks.length) {
      return 0;
    }

    final currentMarks = marks[player][targetIndex];
    // Les points au-delà de trois marques ne comptent que si un adversaire
    // n’a pas encore fermé ce secteur.
    final unclosedOpponents = marks.asMap().entries.any(
      (entry) => entry.key != player && entry.value[targetIndex] < 3,
    );
    final totalMarks = currentMarks + multiplier;
    // Le surplus ferme le secteur à trois marques, puis peut rapporter des points.
    final marksBeyondClose = totalMarks > 3 ? totalMarks - 3 : 0;
    marks[player][targetIndex] = totalMarks > 3 ? 3 : totalMarks;
    return unclosedOpponents ? marksBeyondClose * base : 0;
  }

  /// Projette les marques et les points du tour sans modifier l’état sauvegardé.
  _CricketTurnResult _cricketTurnResult([List<DartThrow>? throws]) {
    final marks = _cricketMarks.map(List<int>.from).toList();
    final points = <int>[];
    for (final dartThrow in throws ?? turn) {
      points.add(
        scoreCricket(
          dartThrow.base,
          dartThrow.multiplier,
          game.currentPlayerIndex,
          marks: marks,
        ),
      );
    }
    return _CricketTurnResult(marks: marks, dartPoints: points);
  }

  /// Associe l’index d’un joueur à l’une des couleurs Cricket disponibles.
  int _cricketPlayerColorIndex(int playerIndex) =>
      playerIndex % _cricketPlayerColors.length;

  /// Choisit la couleur d’un secteur ouvert par le joueur actif.
  Color _cricketButtonColor(int targetIndex, _CricketTurnResult projection) {
    final currentPlayer = game.currentPlayerIndex;
    if (projection.marks[currentPlayer][targetIndex] >= 3) {
      return _cricketPlayerColors[_cricketPlayerColorIndex(currentPlayer)];
    }
    return const Color(0xFF111111);
  }

  /// Vérifie que tous les joueurs ont fermé le secteur demandé.
  bool _isCricketTargetClosedForEveryone(
    int targetIndex,
    _CricketTurnResult projection,
  ) {
    return projection.marks.every(
      (playerMarks) => playerMarks[targetIndex] >= 3,
    );
  }

  /// Construit un bouton Cricket avec les marques et l’état de fermeture visibles.
  Widget _buildCricketScoreButton(int base, _CricketTurnResult projection) {
    final targetIndex = _cricketTargetIndex(base);
    final isClosedForEveryone = _isCricketTargetClosedForEveryone(
      targetIndex,
      projection,
    );
    final currentPlayerHasClosed =
        projection.marks[game.currentPlayerIndex][targetIndex] >= 3;
    final currentPlayerColor =
        _cricketPlayerColors[_cricketPlayerColorIndex(game.currentPlayerIndex)];
    final buttonColor = isClosedForEveryone
        ? const Color(0xFF333333)
        : _cricketButtonColor(targetIndex, projection);
    final textColor = isClosedForEveryone
        ? Colors.white54
        : currentPlayerHasClosed
        ? (currentPlayerColor.computeLuminance() > 0.5
              ? Colors.black
              : Colors.white)
        : Colors.white;

    return ElevatedButton(
      key: ValueKey('cricket-target-$base'),
      onPressed: isClosedForEveryone
          ? null
          : () => addScore(base, selectedMultiplier),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        disabledBackgroundColor: buttonColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$base',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (
                      var playerIndex = 0;
                      playerIndex < game.players.length;
                      playerIndex++
                    ) ...[
                      if (playerIndex > 0) const SizedBox(width: 4),
                      Tooltip(
                        message:
                            '${game.players[playerIndex].name} : '
                            '${projection.marks[playerIndex][targetIndex]}/3',
                        child: Text(
                          '${projection.marks[playerIndex][targetIndex]}',
                          style: TextStyle(
                            color: isClosedForEveryone
                                ? Colors.white38
                                : _cricketPlayerColors[_cricketPlayerColorIndex(
                                    playerIndex,
                                  )],
                            fontSize: 11,
                            fontWeight: playerIndex == game.currentPlayerIndex
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isClosedForEveryone)
            const Center(
              child: Text(
                'X',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Construit le bouton MISS du mode Cricket.
  Widget _buildCricketMissButton() {
    return ElevatedButton(
      onPressed: () => addScore(0, 0),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF333333),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Text('MISS', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  /// Enregistre le tour Cricket, actualise les marques et vérifie les conditions de fin.
  void _endCricketTurn() {
    if (turn.isEmpty) return;

    final playerIndex = game.currentPlayerIndex;
    final player = game.currentPlayer;
    final result = _cricketTurnResult();
    final closesAllTargets = result.marks[playerIndex].every(
      (marks) => marks >= 3,
    );
    final leadsOrTies = game.players.asMap().entries.every(
      (entry) =>
          entry.key == playerIndex ||
          player.score + result.totalPoints >= entry.value.score,
    );
    // Au Cricket, fermer tous les secteurs ne suffit pas : le joueur doit aussi
    // avoir au moins autant de points que chacun de ses adversaires.
    final winsImmediately = closesAllTargets && leadsOrTies;

    setState(() {
      _cricketMarks = result.marks;
      player.score += result.totalPoints;
      player.turns.add(result.dartPoints);
      turn.clear();
      _turnReset++;
      if (!winsImmediately) game.nextPlayer();
    });

    if (winsImmediately) {
      showWinner(player, highScoreWins: true);
      return;
    }

    if (game.players.every(
      (currentPlayer) => currentPlayer.turns.length >= 15,
    )) {
      final highestScore = game.players
          .map((currentPlayer) => currentPlayer.score)
          .reduce(
            (current, candidate) => candidate > current ? candidate : current,
          );
      final leaders = game.players
          .where((currentPlayer) => currentPlayer.score == highestScore)
          .toList();
      showWinner(
        leaders.first,
        highScoreWins: true,
        isDraw: leaders.length > 1,
      );
      return;
    }

    if (mounted) _scrollToCurrentPlayer();
  }

  /// Formate un tir avec la notation usuelle (S, D, T ou Bull).
  String _throwLabel(DartThrow dartThrow) {
    if (dartThrow.base == 0) return 'Miss';
    if (dartThrow.base == 25) {
      return dartThrow.multiplier == 2 ? 'DB' : 'SB';
    }
    final prefix = dartThrow.multiplier == 1
        ? 'S'
        : dartThrow.multiplier == 2
        ? 'D'
        : 'T';
    return '$prefix${dartThrow.base}';
  }

  /// Renvoie les points effectifs d’un tir selon le mode de jeu.
  int _scoreOfThrow(DartThrow dartThrow) {
    if (_isShanghai) {
      return game.scoreShanghaiThrow(_shanghaiTarget, dartThrow);
    }
    return dartThrow.score;
  }

  /// Ouvre l’édition d’un tir et applique les corrections confirmées.
  Future<void> _editThrow(int index) async {
    final original = turn[index];
    int base = original.base;
    int multiplier = original.multiplier;

    final editedThrow = await showDialog<DartThrow>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF121212),
              title: const Text('Modifier le tir'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: '$base',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Base'),
                    onChanged: (value) {
                      base = int.tryParse(value) ?? base;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final option in [1, 2, 3])
                        Expanded(
                          child: RadioListTile<int>(
                            title: Text(
                              option == 1
                                  ? 'S'
                                  : option == 2
                                  ? 'D'
                                  : 'T',
                            ),
                            value: option,
                            groupValue: multiplier,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => multiplier = value);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () {
                    if (base != 25 && (base < 1 || base > 20)) return;
                    if (base == 25 && multiplier == 3) return;
                    Navigator.pop(
                      context,
                      DartThrow(base: base, multiplier: multiplier),
                    );
                  },
                  child: const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );

    if (editedThrow != null && mounted) {
      setState(() => turn[index] = editedThrow);
    }
  }

  /// Indique si le joueur courant a satisfait la règle Double In.
  bool get _currentPlayerHasEnteredDoubleIn =>
      game.hasEntered(game.currentPlayerIndex);

  /// Calcule les points du tour en respectant les règles du mode courant.
  int get turnScore {
    if (_isCricket) return _cricketTurnResult().totalPoints;
    if (_isShanghai) {
      return game
          .scoreShanghaiThrows(_shanghaiTarget, turn)
          .fold(0, (total, score) => total + score);
    }

    var entered = _currentPlayerHasEnteredDoubleIn;
    var score = 0;

    for (final dartThrow in turn) {
      if (!entered) {
        if (dartThrow.multiplier != 2) continue;
        entered = true;
      }
      score += dartThrow.score;
    }

    return score;
  }

  /// Calcule le score affiché, en intégrant provisoirement le tour en cours.
  int _displayedScore(Player player) {
    if (_isCricket) {
      return player.score + (player == game.currentPlayer ? turnScore : 0);
    }
    if (_isShanghai) {
      return player.score + (player == game.currentPlayer ? turnScore : 0);
    }
    if (player != game.currentPlayer) return player.score;
    return (player.score - turnScore).clamp(0, player.score);
  }

  /// Cherche une sortie possible pour le score et les fléchettes restants.
  List<DartThrow>? get _checkoutSuggestion {
    if (_isCricket)
      return null; // verifie si le mode actuelle est un cricket , si oui return null car pas de sortie possible
    if (_isShanghai)
      return null; // verifie si le mode actuelle est un shanghai , si oui return null car pas de sortie possible

    if (widget.doubleIn &&
        !_currentPlayerHasEnteredDoubleIn &&
        !turn.any((dartThrow) => dartThrow.multiplier == 2)) {
      return null;
    }

    final remainingScore = game.currentPlayer.score - turnScore;
    final dartsLeft = 3 - turn.length;
    final maxCheckoutScore = widget.doubleOut ? 170 : 180;
    if (remainingScore <= 0 ||
        dartsLeft <= 0 ||
        remainingScore > maxCheckoutScore) {
      return null;
    }
    return _findCheckout(remainingScore, dartsLeft);
  }

  /// Explore les combinaisons de tirs pour trouver une sortie valide.
  List<DartThrow>? _findCheckout(int remainingScore, int dartsLeft) {
    if (remainingScore <= 0 || dartsLeft == 0) return null;

    final possibleThrows = <DartThrow>[
      for (var base = 20; base >= 1; base--) ...[
        DartThrow(base: base, multiplier: 3),
        DartThrow(base: base, multiplier: 2),
        DartThrow(base: base, multiplier: 1),
      ],
      DartThrow(base: 25, multiplier: 2),
      DartThrow(base: 25, multiplier: 1),
    ];

    for (final dartThrow in possibleThrows) {
      if (dartThrow.score > remainingScore) continue;

      final scoreAfterThrow = remainingScore - dartThrow.score;
      if (scoreAfterThrow == 0) {
        // Avec Double Out, le tir qui termine la partie doit être un double.
        if (!widget.doubleOut || dartThrow.multiplier == 2) {
          return [dartThrow];
        }
        continue;
      }

      final nextThrows = _findCheckout(scoreAfterThrow, dartsLeft - 1);
      if (nextThrows != null) {
        return [dartThrow, ...nextThrows];
      }
    }

    return null;
  }

  /// Formate une combinaison de sortie pour son affichage.
  String _checkoutLabel(List<DartThrow> checkout) {
    return checkout.map(_throwLabel).join('  -  ');
  }

  /// Ajoute les tirs de la sortie conseillée puis valide le tour.
  void _useCheckoutSuggestion() {
    final checkout = _checkoutSuggestion;
    if (checkout == null) return;
    setState(() => turn.addAll(checkout));
    endTurn();
  }

  /// Valide le tour en cours, puis passe au joueur suivant ou termine la partie.
  void endTurn() {
    if (_isCricket) {
      _endCricketTurn();
      return;
    }
    if (_isShanghai) {
      _endShanghaiTurn();
      return;
    }

    var movedToNextPlayer = false;
    setState(() {
      final Player p = game.currentPlayer;
      final int startOfTurnScore = p.score;
      int currentScore = startOfTurnScore;
      DartThrow? finishingThrow;
      bool busted = false;
      final scoredThrows = game.scoreThrows(game.currentPlayerIndex, turn);

      for (var index = 0; index < scoredThrows.length; index++) {
        final throwScore = scoredThrows[index];
        final dartThrow = turn[index];
        currentScore -= throwScore;

        if (currentScore < 0) {
          busted = true;
          break;
        }

        if (currentScore == 0) {
          finishingThrow = dartThrow;
          break;
        }
      }

      if (!busted && currentScore == 1) {
        // Un score restant de 1 ne peut pas être terminé en respectant Double Out.
        busted = true;
      }

      if (!busted && currentScore == 0 && widget.doubleOut) {
        if (finishingThrow == null || finishingThrow.multiplier != 2) {
          busted = true;
        }
      }

      if (busted) {
        // Un bust annule tous les points du tour avant de passer au joueur suivant.
        p.score = startOfTurnScore;
        turn.clear();
        _turnReset++;
        game.nextPlayer();
        movedToNextPlayer = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bust : la sortie n’est pas valide.')),
        );
        return;
      }

      p.turns.add(scoredThrows);
      p.score = currentScore;

      if (p.score == 0) {
        turn.clear();
        _turnReset++;
        showWinner(p);
        return;
      }

      turn.clear();
      _turnReset++;
      game.nextPlayer();
      movedToNextPlayer = true;
    });
    if (mounted && movedToNextPlayer) {
      _scrollToCurrentPlayer();
    }
  }

  /// Applique les tirs Shanghai et fait progresser la cible après chaque manche.
  void _endShanghaiTurn() {
    if (turn.isEmpty) return;

    final player = game.currentPlayer;
    final scoredThrows = game.scoreShanghaiThrows(_shanghaiTarget, turn);
    final hasShanghai = game.hasShanghai(_shanghaiTarget, turn);
    Player? winner;

    setState(() {
      player.score += scoredThrows.fold(0, (total, score) => total + score);
      player.turns.add(scoredThrows);
      turn.clear();
      _turnReset++;

      if (hasShanghai) {
        winner = player;
        return;
      }

      game.nextPlayer();
      if (game.currentPlayerIndex == 0) {
        if (_shanghaiTarget == 20) {
          winner = game.players.reduce(
            (currentWinner, candidate) => candidate.score > currentWinner.score
                ? candidate
                : currentWinner,
          );
          return;
        }
        _shanghaiTarget++;
      }
    });

    if (winner != null) {
      showWinner(winner!, highScoreWins: true, isShanghai: hasShanghai);
    } else if (mounted) {
      _scrollToCurrentPlayer();
    }
  }

  /// Fait défiler horizontalement les cartes jusqu’au joueur actif.
  void _scrollToCurrentPlayer() {
    if (!_playerScrollController.hasClients) return;

    final cardWidth = _playerCardWidth(context) + 10;
    final target = game.currentPlayerIndex * cardWidth;
    final maxScroll = _playerScrollController.position.maxScrollExtent;
    final offset = target.clamp(0.0, maxScroll);

    _playerScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  /// Calcule la largeur des cartes selon le nombre de joueurs et l’écran.
  double _playerCardWidth(BuildContext context) {
    final count = game.players.length;
    if (count <= 3) return 120.0;
    final available = MediaQuery.of(context).size.width - 32;
    final width = (available - (count - 1) * 10) / count;
    return width.clamp(80.0, 110.0);
  }

  /// Remplace l’écran de partie par le résultat et prépare la navigation suivante.
  void showWinner(
    Player p, {
    bool highScoreWins = false,
    bool isShanghai = false,
    bool isDraw = false,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VictoryScreen(
          winner: p,
          finalPlayers: game.players,
          highScoreWins: highScoreWins,
          isShanghai: isShanghai,
          isDraw: isDraw,
          onNewGame: (victoryContext) {
            final newPlayers = game.players
                .map((player) => Player(name: player.name, score: 0))
                .toList();
            Navigator.popUntil(victoryContext, (route) => route.isFirst);
            Navigator.push(
              victoryContext,
              MaterialPageRoute(
                builder: (_) => ModeSelectionScreen(players: newPlayers),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Affiche le nom, le score et la moyenne d’un joueur.
  Widget _buildPlayerScoreCard(Player player, bool active, double width) {
    return Container(
      width: width,
      constraints: const BoxConstraints(maxHeight: 78),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1E3C2F) : const Color(0xFF181818),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active ? Colors.greenAccent : Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _isCricket
                  ? _cricketPlayerColors[_cricketPlayerColorIndex(
                      game.players.indexOf(player),
                    )]
                  : Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_displayedScore(player)} pts',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: active ? Colors.greenAccent : Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Moyenne ${player.averagePerTurn.toStringAsFixed(1)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Construit l’écran de partie et sélectionne les commandes selon le mode.
  @override
  Widget build(BuildContext context) {
    final cricketProjection = _isCricket ? _cricketTurnResult() : null;
    return Scaffold(
      appBar: AppBar(title: const Text('DARTS PRO')),
      body: SafeArea(
        child: Padding(
          // Les modes à décompte réservent moins de marge pour afficher la grille.
          padding: EdgeInsets.all(_isCountdown ? 10 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(_isCountdown ? 12 : 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF1F1F1F)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'PARTIE EN COURS',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: _isCountdown ? 8 : 16),
                    SizedBox(
                      height: _isCountdown ? 78 : 92,
                      child: ListView.separated(
                        controller: _playerScrollController,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final player = game.players[index];
                          return _buildPlayerScoreCard(
                            player,
                            index == game.currentPlayerIndex,
                            _playerCardWidth(context),
                          );
                        },
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemCount: game.players.length,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: _isCountdown ? 8 : 18),
              Text(
                'Tour de ${game.currentPlayer.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isShanghai) ...[
                const SizedBox(height: 6),
                Text(
                  'cible $_shanghaiTarget',
                  style: const TextStyle(
                    color: Color.fromARGB(179, 255, 0, 0),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'RobotoMono',
                    fontSize: 45,
                  ),
                ),
              ],
              if (!_isShanghai && widget.doubleIn) ...[
                const SizedBox(height: 4),
                Text(
                  _currentPlayerHasEnteredDoubleIn
                      ? 'Double In validé'
                      : 'Touche un double pour commencer à marquer',
                  style: TextStyle(
                    color: _currentPlayerHasEnteredDoubleIn
                        ? Colors.greenAccent
                        : Colors.amberAccent,
                    fontSize: 12,
                  ),
                ),
              ],
              if (_checkoutSuggestion case final checkout?) ...[
                if (!_isShanghai || !_isCricket) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF173B2A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.greenAccent),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.flag,
                          color: Colors.greenAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Finish conseillé : ${_checkoutLabel(checkout)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _useCheckoutSuggestion,
                          child: const Text('Jouer'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              SizedBox(height: 18),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(_isCountdown ? 8 : 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161616),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFF1F1F1F)),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: _isShanghai
                                  ? GridView.count(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      childAspectRatio: 1.8,
                                      children: [
                                        _buildShanghaiThrowButton(
                                          'SIMPLE',
                                          1,
                                          const Color(0xFF42A5F5),
                                        ),
                                        _buildShanghaiThrowButton(
                                          'DOUBLE',
                                          2,
                                          const Color.fromARGB(
                                            255,
                                            47,
                                            197,
                                            52,
                                          ),
                                        ),
                                        _buildShanghaiThrowButton(
                                          'TRIPLE',
                                          3,
                                          const Color.fromARGB(
                                            255,
                                            255,
                                            34,
                                            34,
                                          ),
                                        ),
                                        _buildShanghaiThrowButton(
                                          'MISS',
                                          0,
                                          const Color.fromARGB(
                                            255,
                                            247,
                                            245,
                                            245,
                                          ),
                                        ),
                                      ],
                                    )
                                  : _isCricket
                                  ? GridView.count(
                                      crossAxisCount: 4,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      childAspectRatio: 1.45,
                                      children: [
                                        ..._cricketScoreButtons.map(
                                          (score) => _buildCricketScoreButton(
                                            score,
                                            cricketProjection!,
                                          ),
                                        ),
                                        _buildCricketMissButton(),
                                      ],
                                    )
                                  : GridView.count(
                                      crossAxisCount: 5,
                                      // Les 21 scores restent visibles sans défilement en 301/401/501.
                                      physics: _isCountdown
                                          ? const NeverScrollableScrollPhysics()
                                          : null,
                                      mainAxisSpacing: _isCountdown ? 4 : 15,
                                      crossAxisSpacing: _isCountdown ? 4 : 15,
                                      childAspectRatio: _isCountdown
                                          ? 1.3
                                          : 1.2,
                                      children: _scoreButtons.map((score) {
                                        return ElevatedButton(
                                          onPressed: () => addScore(
                                            score,
                                            selectedMultiplier,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF111111,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: Text(
                                            '$score',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                            if (!_isShanghai) ...[
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildMultiplierButton(
                                    1,
                                    'SIMPLE',
                                    Colors.white,
                                  ),
                                  const SizedBox(width: 10),
                                  _buildMultiplierButton(
                                    2,
                                    'DOUBLE',
                                    Colors.greenAccent,
                                  ),
                                  const SizedBox(width: 10),
                                  _buildMultiplierButton(
                                    3,
                                    'TRIPLE',
                                    Colors.redAccent,
                                  ),
                                ],
                              ),
                            ],
                            SizedBox(height: _isCountdown ? 6 : 14),
                            ElevatedButton.icon(
                              onPressed: _isDetecting ? null : _scanDarts,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A1B9A),
                                minimumSize: Size.fromHeight(
                                  _isCountdown ? 46 : 54,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: _isDetecting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.camera_alt),
                              label: Text(
                                _isDetecting
                                    ? 'Analyse en cours...'
                                    : 'Scanner la cible',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: _isCountdown ? 6 : 14),
                            Row(
                              children: [
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: turn.asMap().entries.map((
                                        entry,
                                      ) {
                                        final index = entry.key;
                                        final dartThrow = entry.value;
                                        final cricketPoints = cricketProjection
                                            ?.dartPoints[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: InputChip(
                                            label: Text(
                                              _isCricket
                                                  ? '${_throwLabel(dartThrow)} • +$cricketPoints pts'
                                                  : '${_throwLabel(dartThrow)} = ${_scoreOfThrow(dartThrow)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            deleteIcon: const Icon(
                                              Icons.close,
                                              size: 18,
                                              color: Colors.white70,
                                            ),
                                            deleteIconColor: Colors.white70,
                                            onPressed: () => _editThrow(index),
                                            onDeleted: () {
                                              setState(() {
                                                turn.removeAt(index);
                                              });
                                            },
                                            backgroundColor: const Color(
                                              0xFF111111,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: _isCountdown ? 6 : 12),
                    ElevatedButton(
                      onPressed: turn.isEmpty ? null : endTurn,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.fromHeight(_isCountdown ? 48 : 56),
                        backgroundColor: const Color(0xFF00C853),
                      ),
                      child: const Text(
                        'Valider le tour',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit un bouton de multiplicateur et met en évidence la sélection.
  Widget _buildMultiplierButton(
    int multiplier,
    String label,
    Color activeColor,
  ) {
    final active = selectedMultiplier == multiplier;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => setState(() => selectedMultiplier = multiplier),
        style: ElevatedButton.styleFrom(
          backgroundColor: active ? activeColor : const Color(0xFF111111),
          foregroundColor: active ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: _isCountdown ? 8 : 14),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  /// Construit un bouton de tir Shanghai pour la cible courante.
  Widget _buildShanghaiThrowButton(String label, int multiplier, Color color) {
    return ElevatedButton(
      onPressed: () => addScore(_shanghaiTarget, multiplier),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF111111),
        foregroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
