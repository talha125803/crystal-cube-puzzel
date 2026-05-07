import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/game_grid.dart';
import '../models/block_piece.dart';
import '../models/game_particle.dart';

const Color kCellEmpty = Color(0xFF16213E); // Deep Navy
const Color kCellFilled = Color(0xFF0F3460);
const Color kCellHighlightValid = Color(0xFF00E676); // Spring Green
const Color kCellHighlightInvalid = Color(0xFFFF1744); // Torch Red
const Color kGridLine = Color(0xFF533483); // Violet
const Color kFlash = Color(0xFFFFFFFF);

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard>
    with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<double> _flashAnim;
  final GlobalKey _boardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flashAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final game = context.read<GameProvider>();
    if (game.flashingRows.isNotEmpty || game.flashingCols.isNotEmpty) {
      _flashController.forward(from: 0.0).then((_) {
        _flashController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final flashRows = game.flashingRows;
    final flashCols = game.flashingCols;
    final hoverPositions = game.getHoverPositions();
    final isValid = game.validDrop;

    final hoverSet = hoverPositions != null
        ? hoverPositions.map((p) => '${p[0]},${p[1]}').toSet()
        : <String>{};

    if ((flashRows.isNotEmpty || flashCols.isNotEmpty) &&
        !_flashController.isAnimating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _flashController.forward(from: 0.0).then((_) => _flashController.reverse());
      });
    }

    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        return game.draggingPiece != null;
      },
      onMove: (details) {
        final RenderBox? renderBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null && game.draggingPiece != null) {
          final innerSize = renderBox.size.width;
          final cellSize = innerSize / GameGrid.cols;
          final localPos = renderBox.globalToLocal(details.offset);
          _handleHover(localPos, cellSize, game);
        }
      },
      onAcceptWithDetails: (details) {
        final row = game.hoverRow;
        final col = game.hoverCol;
        if (row != null && col != null) {
          game.dropPiece(row, col);
        } else {
          game.cancelDrag();
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
                child: RepaintBoundary(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final outerSize = constraints.maxWidth < constraints.maxHeight
                          ? constraints.maxWidth
                          : constraints.maxHeight;
                      
                      final innerSize = outerSize - 12;
                      final cellSize = innerSize / GameGrid.cols;
                      game.setBoardCellSize(cellSize);

                      return Container(
                        width: outerSize,
                        height: outerSize,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF533483),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            key: _boardKey,
                            width: innerSize,
                            height: innerSize,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Stack(
                                children: [
                                  CustomPaint(
                                    size: Size(innerSize, innerSize),
                                    painter: GridPainter(
                                      grid: game.grid,
                                      draggingPiece: game.draggingPiece,
                                      flashRows: flashRows,
                                      flashCols: flashCols,
                                      flashValue: _flashAnim.value,
                                      hoverSet: hoverSet,
                                      isValid: isValid,
                                      cellSize: cellSize,
                                    ),
                                  ),
                                  CustomPaint(
                                    size: Size(innerSize, innerSize),
                                    painter: ParticlePainter(
                                      particles: game.particles,
                                      cellSize: cellSize,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleHover(Offset pos, double cellSize, GameProvider game) {
    if (game.draggingPiece == null) return;

    final piece = game.draggingPiece!;
    final pieceWidth = piece.width;
    final pieceHeight = piece.height;
    final Offset normAnchor = game.normalizedDragAnchor;
    
    final Offset boardAnchor = Offset(
      normAnchor.dx * (pieceWidth * cellSize),
      normAnchor.dy * (pieceHeight * cellSize),
    );
    
    final double visualLeft = pos.dx - boardAnchor.dx;
    final double visualTop = pos.dy - boardAnchor.dy;
    
    int col = (visualLeft / cellSize).round();
    int row = (visualTop / cellSize).round();

    col = col.clamp(0, GameGrid.cols - pieceWidth);
    row = row.clamp(0, GameGrid.rows - pieceHeight);

    game.updateHover(row, col);
  }
}

class GridPainter extends CustomPainter {
  final GameGrid grid;
  final BlockPiece? draggingPiece;
  final List<int> flashRows;
  final List<int> flashCols;
  final double flashValue;
  final Set<String> hoverSet;
  final bool isValid;
  final double cellSize;

  GridPainter({
    required this.grid,
    this.draggingPiece,
    required this.flashRows,
    required this.flashCols,
    required this.flashValue,
    required this.hoverSet,
    required this.isValid,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int r = 0; r < GameGrid.rows; r++) {
      for (int c = 0; c < GameGrid.cols; c++) {
        final rect = Rect.fromLTWH(
          c * cellSize,
          r * cellSize,
          cellSize - 1,
          cellSize - 1,
        );

        final isFlashing = flashRows.contains(r) || flashCols.contains(c);
        final key = '$r,$c';
        final isHover = hoverSet.contains(key);
        final isFilled = grid.isOccupied(r, c);

        Color cellColor = Colors.transparent;
        if (isFlashing) {
          final base = isFilled ? Color(grid.cells[r][c]!) : kCellEmpty;
          cellColor = Color.lerp(base, kFlash, flashValue) ?? base;
        } else if (isHover && draggingPiece != null) {
          cellColor = draggingPiece!.color;
        } else if (isFilled) {
          cellColor = Color(grid.cells[r][c]!);
        } else {
          cellColor = kCellEmpty;
        }

        if (isHover) {
          final paint = Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cellColor.withOpacity(0.9),
                cellColor,
                cellColor.withOpacity(0.8),
              ],
            ).createShader(rect);
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
          
          final highlightPaint = Paint()
            ..color = Colors.white.withOpacity(0.3)
            ..style = PaintingStyle.fill;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(rect.left + 2, rect.top + 2, rect.width * 0.4, rect.height * 0.4),
              const Radius.circular(2),
            ),
            highlightPaint,
          );

          final borderPaint = Paint()
            ..color = (isValid ? kCellHighlightValid : kCellHighlightInvalid).withOpacity(0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), borderPaint);
        } else if (isFilled) {
          final paint = Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cellColor.withOpacity(0.9),
                cellColor,
                cellColor.withOpacity(0.8),
              ],
            ).createShader(rect);
          
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);

          final highlightPaint = Paint()
            ..color = Colors.white.withOpacity(0.3)
            ..style = PaintingStyle.fill;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(rect.left + 2, rect.top + 2, rect.width * 0.4, rect.height * 0.4),
              const Radius.circular(2),
            ),
            highlightPaint,
          );
        } else {
          final paint = Paint()..color = cellColor;
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
        }

        final borderPaint = Paint()
          ..color = kGridLine.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), borderPaint);

        if (isFlashing && flashValue > 0.1) {
          final glowPaint = Paint()
            ..color = kFlash.withOpacity(flashValue * 0.6)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * flashValue);
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), glowPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return oldDelegate.flashValue != flashValue ||
        oldDelegate.hoverSet != hoverSet ||
        oldDelegate.isValid != isValid ||
        oldDelegate.flashRows != flashRows ||
        oldDelegate.flashCols != flashCols ||
        oldDelegate.draggingPiece != draggingPiece ||
        oldDelegate.grid != grid;
  }
}

class ParticlePainter extends CustomPainter {
  final List<GameParticle> particles;
  final double cellSize;

  ParticlePainter({
    required this.particles,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final progress = p.progress;
      final opacity = 1.0 - progress;
      final currentPos = Offset(
        p.position.dx * cellSize + p.velocity.dx * progress * 100,
        p.position.dy * cellSize + p.velocity.dy * progress * 100,
      );

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * (1 - progress));

      canvas.drawCircle(currentPos, p.size * (1 - progress), paint);
      
      final corePaint = Paint()
        ..color = Colors.white.withOpacity(opacity * 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(currentPos, p.size * 0.4 * (1 - progress), corePaint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
