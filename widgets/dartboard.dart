import 'package:flutter/material.dart';

/// Cible interactive qui transmet le secteur et le multiplicateur sélectionnés.
class DartBoard extends StatefulWidget {
  /// Appelé lorsqu’un joueur sélectionne un tir valide.
  final void Function(int base, int multiplier) onHit;

  /// Incrémenté par le widget parent à la réinitialisation du tour.
  final int turnReset;

  /// Nombre de fléchettes déjà enregistrées pendant le tour.
  final int currentTurnCount;

  /// Crée une cible reliée à la fonction de score du widget parent.
  const DartBoard({
    super.key,
    required this.onHit,
    required this.turnReset,
    required this.currentTurnCount,
  });

  @override
  State<DartBoard> createState() => _DartBoardState();
}

class _DartBoardState extends State<DartBoard> {
  static const List<int> _sectors = [
    20, 1, 18, 4, 13, 6, 10, 15, 2, 17,
    3, 19, 7, 16, 8, 11, 14, 9, 12, 5,
  ];

  void _registerHit(int base, int multiplier) {
    if (widget.currentTurnCount >= 3) return;

    widget.onHit(base, multiplier);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('+${base * multiplier}'),
        duration: const Duration(milliseconds: 200),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            const BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.6),
              blurRadius: 20,
              offset: Offset(0, 10),
            )
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 20,
                itemBuilder: (context, index) {
                  final number = _sectors[index];
                  return _buildCompactNumberButton(number);
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildCompact25Button(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactNumberButton(int number) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$number',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCompactMultiplierButton('S', 1, number),
              _buildCompactMultiplierButton('D', 2, number),
              if (number != 25)
                _buildCompactMultiplierButton('T', 3, number),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompact25Button() {
    return SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '25',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          _buildCompactMultiplierButton('S', 1, 25),
          const SizedBox(width: 8),
          _buildCompactMultiplierButton('D', 2, 25),
        ],
      ),
    );
  }

  Widget _buildCompactMultiplierButton(
      String label, int multiplier, int number) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            backgroundColor: multiplier == 1
                ? Colors.grey[700]
                : multiplier == 2
                    ? Colors.green
                    : Colors.red,
            minimumSize: const Size(0, 44),
          ),
          onPressed: () => _registerHit(number, multiplier),
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
