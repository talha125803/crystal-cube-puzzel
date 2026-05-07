import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/block_piece.dart';
import '../providers/game_provider.dart';

class TrayPiece extends StatefulWidget {
  final BlockPiece? piece;
  final int index;

  const TrayPiece({
    super.key,
    required this.piece,
    required this.index,
  });

  @override
  State<TrayPiece> createState() => _TrayPieceState();
}

class _TrayPieceState extends State<TrayPiece> {
  Offset? _lastTapDown;

  @override
  Widget build(BuildContext context) {
    if (widget.piece == null) {
      return const SizedBox.shrink();
    }

    final p = widget.piece!;
    final normalized = p.normalizedShape;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double horizontalCellSize = (constraints.maxWidth - 20) / p.width;
        final double verticalCellSize = (constraints.maxHeight - 20) / p.height;
        final double trayCellSize = horizontalCellSize < verticalCellSize 
            ? horizontalCellSize 
            : verticalCellSize;

        final width = p.width * trayCellSize;
        final height = p.height * trayCellSize;

        final child = Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: UnconstrainedBox(
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: normalized.map((cell) {
                    return Positioned(
                      left: cell[1] * trayCellSize,
                      top: cell[0] * trayCellSize,
                      child: Container(
                        width: trayCellSize,
                        height: trayCellSize,
                        decoration: BoxDecoration(
                          color: p.color,
                          border: Border.all(color: p.borderColor, width: 2),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.transparent,
                                Colors.black.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );

        return SizedBox.expand(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              _lastTapDown = details.localPosition;
            },
            child: Draggable<Map<String, dynamic>>(
              data: {'index': widget.index, 'piece': p},
              onDragStarted: () {
                final normalizedAnchor = const Offset(0.5, 0.5);
                context.read<GameProvider>().startDrag(widget.index, normalizedAnchor);
              },
              onDraggableCanceled: (_, __) {
                context.read<GameProvider>().cancelDrag();
              },
              onDragEnd: (details) {
                if (!details.wasAccepted) {
                  context.read<GameProvider>().cancelDrag();
                }
              },
              dragAnchorStrategy: (Draggable<Object> draggable, BuildContext context, Offset position) {
                final game = context.read<GameProvider>();
                final double bCellSize = game.boardCellSize;
                final norm = game.normalizedDragAnchor;
                return Offset(
                  norm.dx * (p.width * bCellSize),
                  norm.dy * (p.height * bCellSize),
                );
              },
              feedback: Material(
                color: Colors.transparent,
                child: Consumer<GameProvider>(
                  builder: (context, game, _) {
                    final double bCellSize = game.boardCellSize;
                    final double opacity = game.hoverRow != null ? 0.0 : 0.8;
                    return Opacity(
                      opacity: opacity,
                      child: SizedBox(
                        width: p.width * bCellSize,
                        height: p.height * bCellSize,
                        child: Stack(
                          children: normalized.map((cell) {
                            return Positioned(
                              left: cell[1] * bCellSize,
                              top: cell[0] * bCellSize,
                              child: Container(
                                width: bCellSize,
                                height: bCellSize,
                                decoration: BoxDecoration(
                                  color: p.color,
                                  border: Border.all(color: p.borderColor, width: 2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.2),
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.2,
                child: child,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
