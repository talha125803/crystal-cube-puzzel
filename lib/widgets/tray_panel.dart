import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'tray_piece.dart';

class TrayPanel extends StatelessWidget {
  const TrayPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final pieces = game.trayPieces;

    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF533483).withOpacity(0.3),
            blurRadius: 0,
            spreadRadius: 2,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF533483),
          width: 3,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return Expanded(
            child: Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF16213E),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                    blurStyle: BlurStyle.inner,
                  ),
                ],
              ),
              child: TrayPiece(
                piece: pieces[index],
                index: index,
              ),
            ),
          );
        }),
      ),
    );
  }
}
