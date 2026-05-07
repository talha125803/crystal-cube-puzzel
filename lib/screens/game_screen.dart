import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/game_provider.dart';
import '../widgets/game_board.dart';
import '../widgets/tray_panel.dart';
import '../widgets/score_board.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color(0xFF16213E),
              Color(0xFF1A1A2E),
            ],
            center: Alignment.center,
            radius: 1.2,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const ScoreBoard(),
                  Expanded(
                    child: const GameBoard(),
                  ),
                  const TrayPanel(),
                  const SizedBox(height: 16),
                ],
              ),

              // Game Over Overlay
              Consumer<GameProvider>(
                builder: (context, game, child) {
                  if (game.gameState != GameState.gameOver) {
                    return const SizedBox.shrink();
                  }
                  return _buildGameOverOverlay(context, game);
                },
              ),

              // Floating Score Popups (Wrapped in IgnorePointer so they don't block buttons)
              IgnorePointer(
                child: Consumer<GameProvider>(
                  builder: (context, game, child) {
                    return Stack(
                      children: game.scorePopups.map((popup) {
                        return Positioned(
                          left: MediaQuery.of(context).size.width * popup.x - 30,
                          top: MediaQuery.of(context).size.height * popup.y - 100,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, -50 * value),
                                child: Opacity(
                                  opacity: 1.0 - (value * value),
                                  child: Text(
                                    '+${popup.score}',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF76FF03),
                                      fontSize: 32 + (10 * (1 - value)),
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.8),
                                          offset: const Offset(2, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),

              // Paused Overlay
              Consumer<GameProvider>(
                builder: (context, game, child) {
                  if (game.gameState != GameState.paused) {
                    return const SizedBox.shrink();
                  }
                  return _buildPausedOverlay(context, game);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPausedOverlay(BuildContext context, GameProvider game) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PAUSED',
            style: GoogleFonts.poppins(
              color: const Color(0xFF00E5FF),
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => game.togglePause(),
            icon: const Icon(CupertinoIcons.play_fill, color: Colors.white),
            label: Text(
              'RESUME GAME',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF533483),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF00E5FF), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay(BuildContext context, GameProvider game) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF533483),
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF533483).withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NO MORE MOVES',
              style: GoogleFonts.poppins(
                color: const Color(0xFFE53935),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'FINAL SCORE',
              style: GoogleFonts.poppins(
                color: const Color(0xFF76FF03),
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
            Text(
              '${game.score}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => game.restartGame(),
              icon: const Icon(CupertinoIcons.refresh, color: Colors.white),
              label: Text(
                'RESTART GAME',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF533483),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFF00E5FF), width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
