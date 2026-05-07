import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/block_piece.dart';
import '../models/game_grid.dart';
import '../models/score_popup.dart';
import '../models/game_particle.dart';
import '../services/sound_service.dart';

enum GameState { playing, paused, gameOver }

class GameProvider extends ChangeNotifier {
  // ─── State ───────────────────────────────────────────────────────────────
  GameGrid _grid = GameGrid();
  List<BlockPiece?> _trayPieces = [null, null, null];
  int _score = 0;
  int _highScore = 0;
  int _coins = 0;
  int _keys = 0;
  int _xp = 0;
  int _level = 1;
  bool _soundEnabled = true;
  GameState _gameState = GameState.playing;

  // Cleared lines animation tracking
  List<int> _flashingRows = [];
  List<int> _flashingCols = [];
  List<ScorePopup> _scorePopups = [];
  List<GameParticle> _particles = [];

  // Drag state
  BlockPiece? _draggingPiece;
  int _draggingTrayIndex = -1;
  int? _hoverRow;
  int? _hoverCol;
  bool _validDrop = false;
  Offset _normalizedDragAnchor = Offset.zero;
  double _boardCellSize = 48.0;

  final Random _random = Random();
  int _streakCount = 0;
  final SoundService _soundService = SoundService();

  // ─── Getters ──────────────────────────────────────────────────────────────
  GameGrid get grid => _grid;
  List<BlockPiece?> get trayPieces => _trayPieces;
  int get score => _score;
  int get highScore => _highScore;
  int get coins => _coins;
  int get keys => _keys;
  int get xp => _xp;
  int get level => _level;
  double get xpProgress => ((_xp % 100) / 100.0).clamp(0.0, 1.0);
  bool get soundEnabled => _soundEnabled;
  GameState get gameState => _gameState;
  List<int> get flashingRows => _flashingRows;
  List<int> get flashingCols => _flashingCols;
  List<ScorePopup> get scorePopups => _scorePopups;
  BlockPiece? get draggingPiece => _draggingPiece;
  int get draggingTrayIndex => _draggingTrayIndex;
  int? get hoverRow => _hoverRow;
  int? get hoverCol => _hoverCol;
  bool get validDrop => _validDrop;
  List<GameParticle> get particles => _particles;
  Offset get normalizedDragAnchor => _normalizedDragAnchor;
  double get boardCellSize => _boardCellSize;

  // ─── Setters ──────────────────────────────────────────────────────────────
  void setBoardCellSize(double size) {
    if ((_boardCellSize - size).abs() < 0.01) return;
    _boardCellSize = size;
    // We notify so the TrayPiece feedback can scale correctly
    // The board's LayoutBuilder will handle its own sizing, so this won't cause an infinite loop
    notifyListeners();
  }

  // ─── Init ─────────────────────────────────────────────────────────────────
  GameProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadHighScore();
    _generateTrayPieces();
    notifyListeners();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    _highScore = prefs.getInt('high_score') ?? 0;
    _coins = prefs.getInt('coins') ?? 0;
    
    // Gift 50 keys to new players
    if (!prefs.containsKey('keys_gifted')) {
      _keys = 50;
      await prefs.setInt('keys', _keys);
      await prefs.setBool('keys_gifted', true);
    } else {
      _keys = prefs.getInt('keys') ?? 0;
    }
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('high_score', _highScore);
    await prefs.setInt('coins', _coins);
    await prefs.setInt('keys', _keys);
  }

  // ─── Tray Generation ──────────────────────────────────────────────────────
  void refreshTrayPieces() {
    if (_score >= 500) {
      _score -= 500;
      _trayPieces = BlockPieceDefinitions.getThreeRandomPieces(_random);
      _soundService.playSfx(SoundService.trayRefresh);
      notifyListeners();
    }
  }

  void _generateTrayPieces() {
    // Smart Luck: If the board is more than 45% full, favor 1x1 and 1x2 pieces
    final int filledCount = _grid.cells.expand((row) => row).where((c) => c != null).length;
    final bool boardIsFull = filledCount > 45;
    
    if (boardIsFull) {
      // Generate very simple pieces to help the player survive
      _trayPieces = List.generate(3, (index) {
        // Favor templates 0 (Single), 1 (1x2H), 2 (1x2V)
        final template = BlockPieceDefinitions.pieceTemplates[_random.nextInt(3)];
        final color = BlockPieceDefinitions.blockColors[_random.nextInt(BlockPieceDefinitions.blockColors.length)];
        final borderColor = BlockPieceDefinitions.blockBorderColors[_random.nextInt(BlockPieceDefinitions.blockBorderColors.length)];
        return BlockPiece(
          id: 'help_${template['name']}_${DateTime.now().millisecondsSinceEpoch}_$index',
          shape: (template['shape'] as List).map((cell) => [cell[0] as int, cell[1] as int]).toList(),
          color: color,
          borderColor: borderColor,
          name: template['name'] as String,
        );
      });
    } else {
      _trayPieces = BlockPieceDefinitions.getThreeRandomPieces(_random);
    }
    _soundService.playSfx(SoundService.trayRefresh);
  }

  void _checkAndRefillTray() {
    // If all 3 are placed (null), generate new set
    if (_trayPieces.every((p) => p == null)) {
      _generateTrayPieces();
      return;
    }
    // If remaining pieces can't fit anywhere, also generate new set
    final remaining = _trayPieces.where((p) => p != null).toList();
    bool anyFits = remaining.any((piece) => _canPieceFitAnywhere(piece!));
    if (!anyFits) {
      // Check game over
      if (_isGameOver()) {
        _gameState = GameState.gameOver;
        _soundService.playSfx(SoundService.gameOver);
        _saveHighScore();
      } else {
        _generateTrayPieces();
      }
    }
  }

  // ─── Drag Handling ────────────────────────────────────────────────────────
  void startDrag(int trayIndex, Offset normalizedAnchor) {
    if (_gameState != GameState.playing) return;
    _draggingPiece = _trayPieces[trayIndex];
    _draggingTrayIndex = trayIndex;
    _normalizedDragAnchor = normalizedAnchor;
    _hoverRow = null;
    _hoverCol = null;
    _validDrop = false;
    _soundService.playSfx(SoundService.dragStart);
    notifyListeners();
  }

  void updateHover(int? row, int? col) {
    if (_draggingPiece == null) return;
    
    if (row != null && col != null) {
      // 1. Prioritize the direct spot under your finger
      if (_canPlace(_draggingPiece!, row, col)) {
        _hoverRow = row;
        _hoverCol = col;
        _validDrop = true;
      } else {
        // 2. Magnetic Snap: Look for the NEAREST valid spot within a 2-cell range
        int? bestR;
        int? bestC;
        double minDistance = 999.0;

        for (int dr = -2; dr <= 2; dr++) {
          for (int dc = -2; dc <= 2; dc++) {
            final nr = row + dr;
            final nc = col + dc;
            if (nr >= 0 && nr < 10 && nc >= 0 && nc < 10) {
              if (_canPlace(_draggingPiece!, nr, nc)) {
                // Calculate Euclidean distance to the finger position
                final double dist = sqrt(dr * dr + dc * dc);
                if (dist < minDistance) {
                  minDistance = dist;
                  bestR = nr;
                  bestC = nc;
                }
              }
            }
          }
        }

        // 3. Only snap if the nearest valid spot is 'close enough' (e.g. within 1.5 cells)
        // This prevents the 'unlike force' jumping across the board
        if (bestR != null && minDistance <= 1.8) {
          _hoverRow = bestR;
          _hoverCol = bestC;
          _validDrop = true;
        } else {
          // If no close valid spot, just show the cursor position as invalid
          _hoverRow = row;
          _hoverCol = col;
          _validDrop = false;
        }
      }
    } else {
      _hoverRow = null;
      _hoverCol = null;
      _validDrop = false;
    }
    notifyListeners();
  }

  void cancelDrag() {
    if (_draggingPiece != null) {
      _soundService.playSfx(SoundService.errorSnap);
    }
    _draggingPiece = null;
    _draggingTrayIndex = -1;
    _hoverRow = null;
    _hoverCol = null;
    _validDrop = false;
    notifyListeners();
  }

  Future<void> dropPiece(int row, int col) async {
    if (_draggingPiece == null) return;
    if (!_canPlace(_draggingPiece!, row, col)) {
      cancelDrag();
      return;
    }

    final piece = _draggingPiece!;
    final trayIndex = _draggingTrayIndex;

    // Place piece
    final positions = _getAbsolutePositions(piece, row, col);
    final colorValue = piece.color.toARGB32();
    _grid = _grid.placeCells(positions, colorValue);
    _soundService.playSfx(SoundService.placeBlock);

    // Add score for placement
    final placementScore = positions.length;
    _addScore(placementScore);

    // Remove from tray
    _trayPieces = List.from(_trayPieces);
    _trayPieces[trayIndex] = null;

    // Clear dragging state
    _draggingPiece = null;
    _draggingTrayIndex = -1;
    _hoverRow = null;
    _hoverCol = null;
    _validDrop = false;

    notifyListeners();

    // Check for line clears
    final linesCleared = await _checkAndClearLines(row, col, positions);
    
    // Reset streak if no lines cleared
    if (!linesCleared) {
      _streakCount = 0;
    }

    // Refill tray if needed
    _checkAndRefillTray();
    notifyListeners();
  }

  Future<bool> _checkAndClearLines(
      int startRow, int startCol, List<List<int>> positions) async {
    final (newGrid, clearedRows, clearedCols) = _grid.clearCompletedLines();

    if (clearedRows.isEmpty && clearedCols.isEmpty) return false;

    // Increment streak
    _streakCount++;

    // Play sound based on number of lines
    final totalLines = clearedRows.length + clearedCols.length;
    if (totalLines > 1) {
      _soundService.playSfx(SoundService.clearMulti);
    } else {
      _soundService.playSfx(SoundService.clearLine);
    }

    // Flash animation
    _flashingRows = clearedRows;
    _flashingCols = clearedCols;
    
    // Spawn particles for cleared rows
    for (var r in clearedRows) {
      _spawnLineParticles(r, -1);
    }
    // Spawn particles for cleared columns
    for (var c in clearedCols) {
      _spawnLineParticles(-1, c);
    }
    
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 400));

    _grid = newGrid;
    _flashingRows = [];
    _flashingCols = [];

    // Calculate bonus score (exponential dopamine growth)
    final comboMultiplier = totalLines * totalLines;
    final streakBonus = 1.0 + _streakCount.toDouble();
    final lineScore = (100 * totalLines * comboMultiplier * streakBonus).toInt();
    _addScore(lineScore);
    _coins += totalLines;

    // Score popup position (center of board area)
    _scorePopups.add(ScorePopup(
      x: 0.5,
      y: 0.5,
      score: lineScore,
      createdAt: DateTime.now(),
    ));

    notifyListeners();

    // Remove popup and particles after animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      _scorePopups.removeWhere(
          (p) => DateTime.now().difference(p.createdAt).inSeconds >= 1);
      _particles.removeWhere((p) => p.isDead);
      notifyListeners();
    });

    return true;
  }

  void _spawnLineParticles(int row, int col) {
    final Random random = Random();
    
    if (row != -1) {
      for (int c = 0; c < 10; c++) {
        final color = _grid.cells[row][c] != null ? Color(_grid.cells[row][c]!) : Colors.white;
        for (int i = 0; i < 3; i++) {
          _particles.add(GameParticle(
            position: Offset(c.toDouble() + 0.5, row.toDouble() + 0.5),
            velocity: Offset(random.nextDouble() * 0.2 - 0.1, random.nextDouble() * 0.2 - 0.1),
            color: color,
            size: random.nextDouble() * 4 + 2,
            lifetime: const Duration(milliseconds: 800),
            createdAt: DateTime.now(),
          ));
        }
      }
    } else if (col != -1) {
      for (int r = 0; r < 10; r++) {
        final color = _grid.cells[r][col] != null ? Color(_grid.cells[r][col]!) : Colors.white;
        for (int i = 0; i < 3; i++) {
          _particles.add(GameParticle(
            position: Offset(col.toDouble() + 0.5, r.toDouble() + 0.5),
            velocity: Offset(random.nextDouble() * 0.2 - 0.1, random.nextDouble() * 0.2 - 0.1),
            color: color,
            size: random.nextDouble() * 4 + 2,
            lifetime: const Duration(milliseconds: 800),
            createdAt: DateTime.now(),
          ));
        }
      }
    }
    
    _animateParticles();
  }

  void _animateParticles() {
    if (_particles.isEmpty) return;
    
    Future.delayed(const Duration(milliseconds: 16), () {
      if (_particles.isNotEmpty) {
        _particles.removeWhere((p) => p.isDead);
        notifyListeners();
        _animateParticles();
      }
    });
  }

  void _addScore(int points) {
    _score += points;
    _xp += points;
    if (_score > _highScore) {
      _highScore = _score;
      _saveHighScore();
    }
    // Level up every 500 XP
    _level = (_xp ~/ 500) + 1;
  }

  // ─── Game Logic ───────────────────────────────────────────────────────────
  bool _canPlace(BlockPiece piece, int row, int col) {
    final positions = _getAbsolutePositions(piece, row, col);
    for (final pos in positions) {
      if (!_grid.isInBounds(pos[0], pos[1])) return false;
      if (_grid.isOccupied(pos[0], pos[1])) return false;
    }
    return true;
  }

  List<List<int>> _getAbsolutePositions(BlockPiece piece, int row, int col) {
    return piece.normalizedShape.map((cell) => [row + cell[0], col + cell[1]]).toList();
  }

  bool _canPieceFitAnywhere(BlockPiece piece) {
    for (int r = 0; r < GameGrid.rows; r++) {
      for (int c = 0; c < GameGrid.cols; c++) {
        if (_canPlace(piece, r, c)) return true;
      }
    }
    return false;
  }

  bool _isGameOver() {
    final remaining = _trayPieces.where((p) => p != null).toList();
    if (remaining.isEmpty) return false;
    return !remaining.any((piece) => _canPieceFitAnywhere(piece!));
  }

  List<List<int>>? getHoverPositions() {
    if (_draggingPiece == null || _hoverRow == null || _hoverCol == null) {
      return null;
    }
    return _getAbsolutePositions(_draggingPiece!, _hoverRow!, _hoverCol!);
  }

  // ─── UI Actions ───────────────────────────────────────────────────────────
  void togglePause() {
    _soundService.playSfx(SoundService.uiClick);
    if (_gameState == GameState.playing) {
      _gameState = GameState.paused;
    } else if (_gameState == GameState.paused) {
      _gameState = GameState.playing;
    }
    notifyListeners();
  }

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    _soundService.setEnabled(_soundEnabled);
    _soundService.playSfx(SoundService.uiClick);
    notifyListeners();
  }

  void restartGame() {
    _soundService.playSfx(SoundService.uiClick);
    _grid = GameGrid();
    _score = 0;
    _xp = 0;
    _level = 1;
    _flashingRows = [];
    _flashingCols = [];
    _scorePopups = [];
    _draggingPiece = null;
    _draggingTrayIndex = -1;
    _hoverRow = null;
    _hoverCol = null;
    _validDrop = false;
    _gameState = GameState.playing;
    _generateTrayPieces();
    notifyListeners();
  }

  void useKey() {
    if (_keys > 0) {
      _soundService.playSfx(SoundService.trayRefresh);
      _keys--;
      _generateTrayPieces();
      if (_gameState == GameState.gameOver) {
        _gameState = GameState.playing;
      }
      _saveHighScore();
      notifyListeners();
    }
  }

  void addCoins(int amount) {
    _coins += amount;
    _saveHighScore();
    notifyListeners();
  }
}
