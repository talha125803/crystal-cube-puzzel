import 'dart:math';
import 'package:flutter/material.dart';

class BlockPiece {
  final String id;
  final List<List<int>> shape; // List of [row, col] offsets
  final Color color;
  final Color borderColor;
  final String name;

  const BlockPiece({
    required this.id,
    required this.shape,
    required this.color,
    required this.borderColor,
    required this.name,
  });

  int get width {
    if (shape.isEmpty) return 0;
    int maxCol = shape.map((cell) => cell[1]).reduce(max);
    int minCol = shape.map((cell) => cell[1]).reduce(min);
    return maxCol - minCol + 1;
  }

  int get height {
    if (shape.isEmpty) return 0;
    int maxRow = shape.map((cell) => cell[0]).reduce(max);
    int minRow = shape.map((cell) => cell[0]).reduce(min);
    return maxRow - minRow + 1;
  }

  // Normalize shape so top-left is at (0,0)
  List<List<int>> get normalizedShape {
    if (shape.isEmpty) return [];
    int minRow = shape.map((cell) => cell[0]).reduce(min);
    int minCol = shape.map((cell) => cell[1]).reduce(min);
    return shape.map((cell) => [cell[0] - minRow, cell[1] - minCol]).toList();
  }

  BlockPiece copyWith({
    String? id,
    List<List<int>>? shape,
    Color? color,
    Color? borderColor,
    String? name,
  }) {
    return BlockPiece(
      id: id ?? this.id,
      shape: shape ?? this.shape,
      color: color ?? this.color,
      borderColor: borderColor ?? this.borderColor,
      name: name ?? this.name,
    );
  }
}

class BlockPieceDefinitions {
  static const List<Color> blockColors = [
    Color(0xFF00E5FF), // Cyan Crystal
    Color(0xFFFF00FF), // Magenta Crystal
    Color(0xFF76FF03), // Lime Crystal
    Color(0xFFFFC400), // Amber Crystal
    Color(0xFF3D5AFE), // Indigo Crystal
    Color(0xFFFF3D00), // Orange Crystal
    Color(0xFFD500F9), // Purple Crystal
  ];

  static const List<Color> blockBorderColors = [
    Colors.black26,
    Colors.white24,
  ];

  static final List<Map<String, dynamic>> pieceTemplates = [
    // Single
    {
      'name': 'Single',
      'shape': [
        [0, 0]
      ],
    },
    // 1x2 horizontal
    {
      'name': '1x2H',
      'shape': [
        [0, 0],
        [0, 1]
      ],
    },
    // 1x2 vertical
    {
      'name': '1x2V',
      'shape': [
        [0, 0],
        [1, 0]
      ],
    },
    // 1x3 horizontal
    {
      'name': '1x3H',
      'shape': [
        [0, 0],
        [0, 1],
        [0, 2]
      ],
    },
    // 1x3 vertical
    {
      'name': '1x3V',
      'shape': [
        [0, 0],
        [1, 0],
        [2, 0]
      ],
    },
    // 2x2 square
    {
      'name': '2x2',
      'shape': [
        [0, 0],
        [0, 1],
        [1, 0],
        [1, 1]
      ],
    },
    // L-shape
    {
      'name': 'L',
      'shape': [
        [0, 0],
        [1, 0],
        [2, 0],
        [2, 1]
      ],
    },
    // L-shape mirrored
    {
      'name': 'LM',
      'shape': [
        [0, 1],
        [1, 1],
        [2, 0],
        [2, 1]
      ],
    },
    // L-shape rotated
    {
      'name': 'LR',
      'shape': [
        [0, 0],
        [0, 1],
        [0, 2],
        [1, 0]
      ],
    },
    // L-shape rotated mirrored
    {
      'name': 'LRM',
      'shape': [
        [0, 0],
        [0, 1],
        [0, 2],
        [1, 2]
      ],
    },
    // T-shape
    {
      'name': 'T',
      'shape': [
        [0, 0],
        [0, 1],
        [0, 2],
        [1, 1]
      ],
    },
    // T-shape rotated
    {
      'name': 'TR',
      'shape': [
        [0, 0],
        [1, 0],
        [1, 1],
        [2, 0]
      ],
    },
    // T-shape rotated 180
    {
      'name': 'T180',
      'shape': [
        [0, 1],
        [1, 0],
        [1, 1],
        [1, 2]
      ],
    },
    // T-shape rotated 270
    {
      'name': 'T270',
      'shape': [
        [0, 1],
        [1, 0],
        [1, 1],
        [2, 1]
      ],
    },
    // S-shape
    {
      'name': 'S',
      'shape': [
        [0, 1],
        [0, 2],
        [1, 0],
        [1, 1]
      ],
    },
    // S-shape vertical
    {
      'name': 'SV',
      'shape': [
        [0, 0],
        [1, 0],
        [1, 1],
        [2, 1]
      ],
    },
    // Z-shape
    {
      'name': 'Z',
      'shape': [
        [0, 0],
        [0, 1],
        [1, 1],
        [1, 2]
      ],
    },
    // Z-shape vertical
    {
      'name': 'ZV',
      'shape': [
        [0, 1],
        [1, 0],
        [1, 1],
        [2, 0]
      ],
    },
    // 2x3 rectangle
    {
      'name': '2x3',
      'shape': [
        [0, 0],
        [0, 1],
        [1, 0],
        [1, 1],
        [2, 0],
        [2, 1]
      ],
    },
    // 3x2 rectangle
    {
      'name': '3x2',
      'shape': [
        [0, 0],
        [0, 1],
        [0, 2],
        [1, 0],
        [1, 1],
        [1, 2]
      ],
    },
    // 3x3 square
    {
      'name': '3x3',
      'shape': [
        [0, 0],
        [0, 1],
        [0, 2],
        [1, 0],
        [1, 1],
        [1, 2],
        [2, 0],
        [2, 1],
        [2, 2]
      ],
    },
    // 1x4 horizontal
    {
      'name': '1x4H',
      'shape': [
        [0, 0],
        [0, 1],
        [0, 2],
        [0, 3]
      ],
    },
    // 1x4 vertical
    {
      'name': '1x4V',
      'shape': [
        [0, 0],
        [1, 0],
        [2, 0],
        [3, 0]
      ],
    },
    // 1x5 horizontal
    {
      'name': '1x5H',
      'shape': [
        [0, 0],
        [0, 1],
        [0, 2],
        [0, 3],
        [0, 4]
      ],
    },
    // 1x5 vertical
    {
      'name': '1x5V',
      'shape': [
        [0, 0],
        [1, 0],
        [2, 0],
        [3, 0],
        [4, 0]
      ],
    },
  ];

  static BlockPiece getRandomPiece(Random random) {
    // Weighted randomness: 70% chance for simple pieces, 30% for complex
    final bool isSimple = random.nextDouble() < 0.7;
    final int templateIndex = isSimple 
        ? random.nextInt(15) // First 15 pieces are simpler
        : random.nextInt(pieceTemplates.length);
        
    final template = pieceTemplates[templateIndex];
    final color = blockColors[random.nextInt(blockColors.length)];
    final borderColor = blockBorderColors[random.nextInt(blockBorderColors.length)];
    final shape = (template['shape'] as List)
        .map((cell) => [cell[0] as int, cell[1] as int])
        .toList();
    return BlockPiece(
      id: '${template['name']}_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(9999)}',
      shape: shape,
      color: color,
      borderColor: borderColor,
      name: template['name'] as String,
    );
  }

  static List<BlockPiece> getThreeRandomPieces(Random random) {
    return List.generate(3, (_) => getRandomPiece(random));
  }
}
