import 'package:flutter/material.dart';
import '../models/player.dart';

/// Affiche les résultats de la partie et propose d’en démarrer une nouvelle.
class VictoryScreen extends StatelessWidget {
  /// Joueur présenté comme vainqueur ou premier du classement en cas d’égalité.
  final Player winner;
  /// Joueurs dont les scores finaux sont affichés.
  final List<Player> finalPlayers;
  /// Fonction de rappel pour revenir à la préparation d’une nouvelle partie.
  final void Function(BuildContext context) onNewGame;
  /// Trie le classement du score le plus élevé au plus faible si vrai.
  final bool highScoreWins;
  /// Affiche le titre de victoire propre au Shanghai si vrai.
  final bool isShanghai;
  /// Affiche une égalité au lieu de désigner un seul vainqueur.
  final bool isDraw;

  /// Crée l’écran des résultats pour [winner] et le classement final.
  const VictoryScreen({
    super.key,
    required this.winner,
    required this.finalPlayers,
    required this.onNewGame,
    this.highScoreWins = false,
    this.isShanghai = false,
    this.isDraw = false,
  });

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = [...finalPlayers]
      ..sort(
        (a, b) => highScoreWins
            ? b.score.compareTo(a.score)
            : a.score.compareTo(b.score),
      );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF121212),
        title: Text(isDraw ? 'MATCH NUL' : 'VICTOIRE'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 240,
                      height: 240,
                      decoration: const BoxDecoration(
                        color: Color(0xFF161616),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/trophé.png',
                        width: 190,
                        height: 190,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (isShanghai)
                      const Text(
                        'SHANGAI !',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      )
                    else if (isDraw)
                      const Text(
                        'ÉGALITÉ !',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      )
                    else
                      const Text(
                        'VICTOIRE !',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      isDraw
                          ? 'Les joueurs sont à égalité après 15 tours.'
                          : '${winner.name} a remporté la partie !',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF1F1F1F)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Scores finaux',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: ListView.separated(
                          itemCount: sortedPlayers.length,
                          separatorBuilder: (_, _) =>
                              const Divider(color: Colors.white12),
                          itemBuilder: (context, index) {
                            final player = sortedPlayers[index];
                            return Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index == 0 && !isDraw
                                        ? Colors.greenAccent
                                        : const Color(0xFF222222),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: index == 0 && !isDraw
                                            ? Colors.black
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    player.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${player.score}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => onNewGame(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFF00C853),
                ),
                child: const Text(
                  'Nouvelle partie',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  side: const BorderSide(color: Colors.white12),
                ),
                child: const Text(
                  'Retour à l’accueil',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
