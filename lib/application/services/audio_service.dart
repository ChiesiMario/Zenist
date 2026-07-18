import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  AudioService() {
    // Optionally preload the audio file to reduce latency on first play
    _player.setSource(AssetSource('sounds/coin.wav'));
  }

  Future<void> playTaskCompleteSound() async {
    try {
      // Create a new instance for each play to allow overlapping sounds
      // if tasks are completed very quickly.
      final player = AudioPlayer();
      await player.play(AssetSource('sounds/coin.wav'), volume: 1.0);
      
      // Dispose the player after sound finishes to free up resources
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (e) {
      // Ignore errors if sound cannot be played
      debugPrint('AudioService: Error playing audio: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
