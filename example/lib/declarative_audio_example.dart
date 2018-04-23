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
      buildMe: [
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

class PlaylistExample extends StatefulWidget {
  @override
  _PlaylistExampleState createState() => new _PlaylistExampleState();
}

class _PlaylistExampleState extends State<PlaylistExample> {

  final _audioUrls = [
    "https://api.soundcloud.com/tracks/266891990/stream?secret_token=s-tj3IS&client_id=LBCcHmRB8XSStWL6wKH2HPACspQlXg2P",
    "https://api.soundcloud.com/tracks/260578593/stream?secret_token=s-tj3IS&client_id=LBCcHmRB8XSStWL6wKH2HPACspQlXg2P",
    "https://api.soundcloud.com/tracks/258735531/stream?secret_token=s-tj3IS&client_id=LBCcHmRB8XSStWL6wKH2HPACspQlXg2P",
    "https://api.soundcloud.com/tracks/9540779/stream?secret_token=s-tj3IS&client_id=LBCcHmRB8XSStWL6wKH2HPACspQlXg2P",
    "https://api.soundcloud.com/tracks/9540352/stream?secret_token=s-tj3IS&client_id=LBCcHmRB8XSStWL6wKH2HPACspQlXg2P",
    "https://api.soundcloud.com/tracks/295692063/stream?secret_token=s-tj3IS&client_id=LBCcHmRB8XSStWL6wKH2HPACspQlXg2P",
  ];

  int _activeIndex = 0;
  PlaybackState _playbackState = PlaybackState.playing;

  @override
  Widget build(BuildContext context) {
    return new AudioPlaylist(
      playlist: _audioUrls,
      startPlayingFromIndex: _activeIndex,
      playbackState: _playbackState,
      child: new Center(
        child: new Row(
          children: <Widget>[
            new Expanded(child: new Container()),
            new IconButton(
              icon: new Icon(
                Icons.skip_previous,
                size: 35.0,
              ),
              onPressed: () {
                setState(() {
                  if (_activeIndex > 0) {
                    --_activeIndex;
                  }
                });
              },
            ),
            new Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0),
              child: new IconButton(
                icon: new Icon(
                  _playbackState == PlaybackState.paused ? Icons.play_arrow : Icons.pause,
                  size: 35.0,
                ),
                onPressed: () {
                  setState(() {
                    if (_playbackState == PlaybackState.playing) {
                      _playbackState = PlaybackState.paused;
                    } else {
                      _playbackState = PlaybackState.playing;
                    }
                  });
                },
              ),
            ),
            new IconButton(
              icon: new Icon(
                Icons.skip_next,
                size: 35.0,
              ),
              onPressed: () {
                setState(() {
                  if (_activeIndex < _audioUrls.length - 1) {
                    ++_activeIndex;
                  }
                });
              },
            ),
            new Expanded(child: new Container()),
          ],
        ),
      ),
    );
  }
}
