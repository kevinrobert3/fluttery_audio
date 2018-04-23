import 'dart:async';

import 'package:flutter/services.dart';
import 'package:fluttery_audio/src/_audio_player.dart';

export 'src/_audio_player.dart';
export 'src/_audio_player_widgets.dart';
export 'src/_playlist.dart';

class FlutteryAudio {
  static const MethodChannel _channel =
      const MethodChannel('fluttery_audio');

  static AudioPlayer audioPlayer() {
    return new AudioPlayer(
      playerId: 'demo_player',
      channel: _channel,
    );
  }
}