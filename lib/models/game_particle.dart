import 'package:flutter/material.dart';
import 'dart:math';

class GameParticle {
  final Offset position;
  final Offset velocity;
  final Color color;
  final double size;
  final Duration lifetime;
  final DateTime createdAt;

  GameParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.lifetime,
    required this.createdAt,
  });

  double get progress {
    final elapsed = DateTime.now().difference(createdAt).inMilliseconds;
    return (elapsed / lifetime.inMilliseconds).clamp(0.0, 1.0);
  }

  bool get isDead => progress >= 1.0;
}
