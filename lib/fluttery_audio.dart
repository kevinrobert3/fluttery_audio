import 'package:flutter/services.dart';
import 'package:fluttery_audio/src/_audio_player.dart';
import 'package:fluttery_audio/src/_audio_visualizer.dart';

export 'src/_audio_player.dart';
export 'src/_audio_player_widgets.dart';
export 'src/_audio_visualizer.dart';
export 'src/_playlist.dart';
export 'src/_visualizer.dart';

class FlutteryAudio {
  static const MethodChannel _channel =
      const MethodChannel('fluttery_audio');

  static const MethodChannel _visualizerChannel =
      const MethodChannel('fluttery_audio_visualizer');

  static AudioPlayer audioPlayer() {
    return new AudioPlayer(
      playerId: 'demo_player',
      channel: _channel,
    );
  }

  static AudioVisualizer audioVisualizer() {
    return new AudioVisualizer(
      channel: _visualizerChannel,
    );
  }
}