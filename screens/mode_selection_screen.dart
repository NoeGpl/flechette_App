import 'package:flutter/material.dart';
import '../models/player.dart';
import 'game_screen.dart';

/// Permet de choisir un mode de jeu et ses règles.
class ModeSelectionScreen extends StatefulWidget {
  /// Joueurs participant à cette partie.
  final List<Player> players;

  /// Crée un écran de sélection de mode pour [players].
  const ModeSelectionScreen({super.key, required this.players});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  String selectedMode = '501';
  bool doubleOut = false;
  bool doubleIn = false;
  bool showTrainingModes = false;

  void startGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          players: widget.players,
          mode: selectedMode,
          doubleOut: doubleOut,
          doubleIn: doubleIn,
        ),
      ),
    );
  }

  Widget _buildModeCard(String mode, String label, Color accent) {
    final active = selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => selectedMode = mode),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF161616) : const Color(0xFF111111),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? accent : const Color(0xFF1E1E1E),
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: active
                    ? accent.withValues(alpha: 0.22)
                    : const Color(0xFF121212),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  mode,
                  style: TextStyle(
                    color: active ? accent : Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mode classique',
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white60,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Row(
        children: [
          _buildCategoryButton(
            label: 'Mode classique',
            icon: Icons.sports_score,
            isSelected: !showTrainingModes,
            onTap: () => setState(() => showTrainingModes = false),
          ),
          _buildCategoryButton(
            label: 'Entraînement',
            icon: Icons.track_changes,
            isSelected: showTrainingModes,
            onTap: () => setState(() => showTrainingModes = true),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: isSelected ? const Color(0xFF00C853) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.black : Colors.white70,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingModeCard(
    String title,
    String description,
    IconData icon,
    Color accent,
  ) {
    final active = selectedMode == title;
    return GestureDetector(
      onTap: () => setState(() => selectedMode = title),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF161616) : const Color(0xFF111111),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? accent : const Color(0xFF1E1E1E),
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1E1E1E)),
              ),
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisissez le mode'),
        backgroundColor: const Color(0xFF121212),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF1F1F1F)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mode de jeu',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Choisissez votre mode de jeu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${widget.players.length} joueurs prêts',
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/images/cible.png',
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _buildCategorySelector(),
              const SizedBox(height: 22),
              if (showTrainingModes) ...[
                const Text(
                  'Modes d’entraînement',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choisissez un jeu pour vous entraîner.',
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 16),
                _buildTrainingModeCard(
                  'Shanghai',
                  'Visez les numéros à tour de rôle.',
                  Icons.casino_outlined,
                  const Color(0xFF42A5F5),
                ),
                const SizedBox(height: 14),
                _buildTrainingModeCard(
                  'Cricket',
                  'Entraînez-vous sur les cibles du Cricket.',
                  Icons.track_changes,
                  const Color(0xFFFFB300),
                ),
              ] else ...[
                _buildModeCard(
                  '501',
                  'Début 501 - plus long',
                  const Color(0xFF00C853),
                ),
                const SizedBox(height: 22),
                _buildModeCard(
                  '401',
                  'Début 401 - moyen',
                  const Color.fromARGB(255, 200, 0, 0),
                ),
                const SizedBox(height: 14),
                _buildModeCard(
                  '301',
                  'Début 301 - rapide',
                  const Color(0xFF42A5F5),
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sortie uniquement en double',
                              style: TextStyle(color: Colors.white70),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Double Out',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: doubleOut,
                        activeThumbColor: const Color(0xFF00C853),
                        onChanged: (value) => setState(() => doubleOut = value),
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Entrée uniquement en double',
                              style: TextStyle(color: Colors.white70),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Double In',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: doubleIn,
                        activeThumbColor: const Color(0xFF00C853),
                        onChanged: (value) => setState(() => doubleIn = value),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: startGame,
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
