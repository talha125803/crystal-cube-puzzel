import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  static const int _poolSize = 4;
  final List<AudioPlayer> _pool = List.generate(_poolSize, (_) => AudioPlayer());
  int _currentPlayerIndex = 0;
  bool _enabled = true;

  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  Future<void> playSfx(String name) async {
    if (!_enabled) return;
    try {
      final player = _pool[_currentPlayerIndex];
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _poolSize;
      
      // Stop current sound if it's still playing and restart with new one
      await player.stop();
      await player.play(AssetSource('audio/$name.wav'));
    } catch (e) {
      print('Error playing sound $name: $e');
    }
  }

  void dispose() {
    for (var player in _pool) {
      player.dispose();
    }
  }
  // Predefined sound names
  static const String placeBlock = 'place_block';
  static const String clearLine = 'clear_line';
  static const String clearMulti = 'clear_multi';
  static const String dragStart = 'drag_start';
  static const String gameOver = 'game_over';
  static const String uiClick = 'ui_click';
  static const String trayRefresh = 'tray_refresh';
  static const String errorSnap = 'error_snap';
}
