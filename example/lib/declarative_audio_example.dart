import 'package:flutter/material.dart';
import 'package:fluttery_audio/fluttery_audio.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

final _log = new Logger('DeclarativeAudioExample');

/// Simple example does not use AudioComponents.
class DeclarativeAudioSimpleExample extends StatefulWidget {

  final String audioUrl;

  DeclarativeAudioSimpleExample({
    @required this.audioUrl,
  });

  @override
  _DeclarativeAudioSimpleExampleState createState() => new _DeclarativeAudioSimpleExampleState();
}

class _DeclarativeAudioSimpleExampleState extends State<DeclarativeAudioSimpleExample> {

  @override
  initState() {
    super.initState();
  }

  Widget _buildButton(String title, VoidCallback onPressed) {
    return new Container(
      padding: const EdgeInsets.all(8.0),
      width: double.infinity,
      child: new RaisedButton(
        child: new Text(
          title,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildButtonsWithSlider(AudioPlayer audioPlayer) {
    return new Column(
      children: <Widget>[
        _buildButton('LOAD AUDIO', audioPlayer.state == AudioPlayerState.idle
            || audioPlayer.state == AudioPlayerState.stopped ? () {
          audioPlayer.loadMedia(Uri.parse(widget.audioUrl));
        } : null),
        _buildButton('PLAY AUDIO', audioPlayer.state == AudioPlayerState.paused ? () {
          audioPlayer.play();
        } : null),
        _buildButton('PAUSE AUDIO', audioPlayer.state == AudioPlayerState.playing ? () {
          audioPlayer.pause();
        } : null),
        _buildButton('STOP AUDIO', audioPlayer.state == AudioPlayerState.playing
          || audioPlayer.state == AudioPlayerState.paused ? () {
          audioPlayer.stop();
        } : null),
        new Slider(
            value: audioPlayer.position == null ? 0.0 : audioPlayer.position.inMilliseconds.toDouble(),
            max: audioPlayer.audioLength == null ? 1.0 : audioPlayer.audioLength.inMilliseconds.toDouble(),
            onChanged: null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Audio(
      audioUrl: widget.audioUrl,
      updateMe: [
        WatchableAudioProperties.audioPlayerState,
        WatchableAudioProperties.audioLength,
        WatchableAudioProperties.audioPlayhead,
      ],
      playerBuilder: (BuildContext context, AudioPlayer player, Widget child) {
        return _buildButtonsWithSlider(player);
      },
      child: null,
    );
  }
}

/// This example uses AudioComponents
class DeclarativeAudioComponentsExample extends StatefulWidget {

  final String audioUrl;

  DeclarativeAudioComponentsExample({
    @required this.audioUrl,
  });

  @override
  _DeclarativeAudioComponentsExampleState createState() => new _DeclarativeAudioComponentsExampleState();
}

class _DeclarativeAudioComponentsExampleState extends State<DeclarativeAudioComponentsExample> {

  @override
  initState() {
    super.initState();
  }

  Widget _buildButton(String title, VoidCallback onPressed) {
    return new Container(
      padding: const EdgeInsets.all(8.0),
      width: double.infinity,
      child: new RaisedButton(
        child: new Text(
          title,
        ),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Audio(
      audioUrl: widget.audioUrl,
      child: new Column(
        children: <Widget>[
          new AudioComponent(
            updateMe: [
              WatchableAudioProperties.audioPlayerState,
            ],
            playerBuilder: (BuildContext context, AudioPlayer player, Widget child) {
              return _buildButton('LOAD AUDIO', player.state == AudioPlayerState.idle
                  || player.state == AudioPlayerState.stopped ? () {
                player.loadMedia(Uri.parse(widget.audioUrl));
              } : null);
            },
          ),

          new AudioComponent(
            updateMe: [
              WatchableAudioProperties.audioPlayerState,
            ],
            playerBuilder: (BuildContext context, AudioPlayer player, Widget child) {
              return _buildButton('PLAY AUDIO', player.state == AudioPlayerState.paused ? () {
                player.play();
              } : null);
            },
          ),

          new AudioComponent(
            updateMe: [
              WatchableAudioProperties.audioPlayerState,
            ],
            playerBuilder: (BuildContext context, AudioPlayer player, Widget child) {
              return _buildButton('PAUSE AUDIO', player.state == AudioPlayerState.playing ? () {
                player.pause();
              } : null);
            },
          ),

          new AudioComponent(
            updateMe: [
              WatchableAudioProperties.audioPlayerState,
            ],
            playerBuilder: (BuildContext context, AudioPlayer player, Widget child) {
              return _buildButton('STOP AUDIO', player.state == AudioPlayerState.playing
                  || player.state == AudioPlayerState.paused ? () {
                player.stop();
              } : null);
            },
          ),

          new AudioComponent(
            updateMe: [
              WatchableAudioProperties.audioLength,
              WatchableAudioProperties.audioPlayhead,
            ],
            playerBuilder: (BuildContext context, AudioPlayer player, Widget child) {
              return new Slider(
                value: player.position == null ? 0.0 : player.position.inMilliseconds.toDouble(),
                max: player.audioLength == null ? 1.0 : player.audioLength.inMilliseconds.toDouble(),
                onChanged: null,
              );
            },
          ),
        ],
      ),
    );
  }
}