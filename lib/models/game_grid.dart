// Grid model for the 10x10 board
class GameGrid {
  static const int rows = 10;
  static const int cols = 10;

  // null = empty, non-null = filled with color value
  final List<List<int?>> cells;

  GameGrid() : cells = List.generate(rows, (_) => List.filled(cols, null));

  GameGrid.fromCells(this.cells);

  bool isOccupied(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) return true;
    return cells[row][col] != null;
  }

  bool isInBounds(int row, int col) {
    return row >= 0 && row < rows && col >= 0 && col < cols;
  }

  GameGrid copyWith() {
    return GameGrid.fromCells(
      List.generate(rows, (r) => List<int?>.from(cells[r])),
    );
  }

  // Place cells, returns new grid
  GameGrid placeCells(List<List<int>> positions, int colorValue) {
    final newGrid = copyWith();
    for (final pos in positions) {
      final row = pos[0];
      final col = pos[1];
      if (newGrid.isInBounds(row, col)) {
        newGrid.cells[row][col] = colorValue;
      }
    }
    return newGrid;
  }

  // Clear rows and columns, returns (newGrid, clearedRows, clearedCols)
  (GameGrid, List<int>, List<int>) clearCompletedLines() {
    final clearedRows = <int>[];
    final clearedCols = <int>[];

    // Check rows
    for (int r = 0; r < rows; r++) {
      if (cells[r].every((cell) => cell != null)) {
        clearedRows.add(r);
      }
    }

    // Check columns
    for (int c = 0; c < cols; c++) {
      if (List.generate(rows, (r) => cells[r][c]).every((cell) => cell != null)) {
        clearedCols.add(c);
      }
    }

    if (clearedRows.isEmpty && clearedCols.isEmpty) {
      return (this, clearedRows, clearedCols);
    }

    final newGrid = copyWith();
    for (final r in clearedRows) {
      for (int c = 0; c < cols; c++) {
        newGrid.cells[r][c] = null;
      }
    }
    for (final c in clearedCols) {
      for (int r = 0; r < rows; r++) {
        newGrid.cells[r][c] = null;
      }
    }

    return (newGrid, clearedRows, clearedCols);
  }
}
