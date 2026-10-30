import 'package:flutter/material.dart';
import '../models/player.dart';
import 'mode_selection_screen.dart';

/// Permet de créer les joueurs avant de configurer une partie.
class HomeScreen extends StatefulWidget {
  /// Crée l’écran de préparation des joueurs.
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController controller = TextEditingController();

  List<Player> players = [];

  void addPlayer() {
    if (controller.text.isEmpty) return;

    setState(() {
      players.add(Player(name: controller.text, score: 0));
      controller.clear();
    });
  }

  void reorderPlayers(int oldIndex, int newIndex) {
    setState(() {
      final player = players.removeAt(oldIndex);
      players.insert(newIndex, player);
    });
  }

  void continueToModeSelection() {
    if (players.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ModeSelectionScreen(players: players)),
    );
  }

  Widget _playerCard(Player player, int index) {
    final colors = [
      Colors.green,
      Colors.deepPurple,
      Colors.orange,
      Colors.cyan,
    ];
    final color = colors[index % colors.length];
    return Container(
      key: ObjectKey(player),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                players.removeAt(index);
              });
            },
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.18),
            child: Text(
              player.name.isEmpty ? '?' : player.name[0].toUpperCase(),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${player.score} pts',
                  style: const TextStyle(color: Colors.greenAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DARTS PRO'), elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/cible.png',
                      width: 140,
                      height: 140,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Créez vos joueurs',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ajoutez jusqu’à 4 joueurs et passez au choix de la partie.',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF1E1E1E)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Nom du joueur',
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: addPlayer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Ajouter'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: players.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.person_add,
                            size: 48,
                            color: Colors.white24,
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Aucun joueur pour l’instant',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      )
                    : ReorderableListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: players.length,
                        onReorderItem: reorderPlayers,
                        itemBuilder: (_, index) =>
                            _playerCard(players[index], index),
                      ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: players.isEmpty ? null : continueToModeSelection,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFF00C853),
                ),
                child: const Text(
                  'Commencer la partie',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
