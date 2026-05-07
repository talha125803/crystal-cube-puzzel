import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'counter_text.dart';
import '../providers/game_provider.dart';

class ScoreBoard extends StatelessWidget {
  const ScoreBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left controls
              Row(
                children: [
                  _buildIconButton(
                    icon: game.gameState == GameState.paused
                        ? CupertinoIcons.play_arrow_solid
                        : CupertinoIcons.pause_solid,
                    onTap: () => context.read<GameProvider>().togglePause(),
                  ),
                  const SizedBox(width: 16),
                  _buildIconButton(
                    icon: game.soundEnabled
                        ? CupertinoIcons.speaker_3_fill
                        : CupertinoIcons.speaker_slash_fill,
                    onTap: () => context.read<GameProvider>().toggleSound(),
                  ),
                ],
              ),

              // Score Display
              Column(
                children: [
                  Text(
                    'SCORE',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF76FF03), // Neon Lime
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  CounterText(
                    value: game.score,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3460),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF533483)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.rosette,
                          color: Color(0xFFFFD700),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'BEST ${game.highScore}',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF76FF03),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Right controls
              _buildIconButton(
                icon: CupertinoIcons.bars,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => _buildMenuDialog(context, game),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // XP Bar
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF533483).withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                  blurStyle: BlurStyle.inner,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: (game.xpProgress * 100).toInt(),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF00E5FF),
                          Color(0xFF76FF03),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 100 - (game.xpProgress * 100).toInt(),
                  child: const SizedBox(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lv ${game.level}',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF00E5FF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'NEXT',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF76FF03).withOpacity(0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuDialog(BuildContext context, GameProvider game) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF533483), width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PAUSED',
              style: GoogleFonts.poppins(
                color: const Color(0xFF00E5FF),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            _buildMenuButton(
              context,
              label: 'RESUME',
              color: const Color(0xFF4CAF50),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              context,
              label: 'RESTART',
              color: const Color(0xFF533483),
              onTap: () {
                game.restartGame();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIconButton(
                  icon: game.soundEnabled
                      ? CupertinoIcons.speaker_3_fill
                      : CupertinoIcons.speaker_slash_fill,
                  onTap: () => game.toggleSound(),
                ),
                const SizedBox(width: 24),
                _buildIconButton(
                  icon: CupertinoIcons.home,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, {required String label, required Color color, required VoidCallback onTap}) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F3460),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF533483), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: const Color(0xFF00E5FF),
            size: 20,
          ),
        ),
      ),
    );
  }
}
