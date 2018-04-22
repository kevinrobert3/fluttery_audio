import 'package:flutter/widgets.dart';
import 'package:fluttery_audio/src/_audio_player.dart';
import 'package:fluttery_audio/fluttery_audio.dart';
import 'package:meta/meta.dart';
import 'package:logging/logging.dart';

final _log = new Logger('AudioPlayerWidget');

class Audio extends StatefulWidget {

  final String audioUrl;
  final PlaybackState playbackState;
  final List<WatchableAudioProperties> updateMe;
  final Widget Function(BuildContext, AudioPlayer, Widget child) playerBuilder;
  final Widget child;

  Audio({
    this.audioUrl,
    this.playbackState = PlaybackState.paused,
    this.updateMe = const [],
    this.playerBuilder,
    this.child,
  });

  @override
  _AudioState createState() => new _AudioState();
}

class _AudioState extends State<Audio> {

  static AudioPlayer of(BuildContext context) {
    _AudioState state = context.ancestorStateOfType(
        new TypeMatcher<_AudioState>()
    );
    return state?._player;
  }

  AudioPlayer _player;
  String _audioUrl;

  @override
  void initState() {
    super.initState();

    // TODO: player ID
    _player = FlutteryAudio.audioPlayer();
    _player.addListener(
      onBufferingUpdate: _onBufferingUpdate,
      onAudioReady: _onAudioReady,
      onPlayerPlaybackUpdate: _onPlayerPlaybackUpdate,
      onStateChanged: _onStateChanged,
      onSeekStarted: () {
        _onSeekingChanged(true);
      },
      onSeekCompleted: () {
        _onSeekingChanged(false);
      }
    );

    _setAudioUrl(widget.audioUrl);
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setAudioUrl(widget.audioUrl);

    // TODO: change to playback mode

    // TODO: change to updateMe?
  }

  _setAudioUrl(String url) {
    // If the url has changed then we need to switch audio sources.
    if (url != _audioUrl) {
      _audioUrl = url;
      _player.loadMedia(Uri.parse(_audioUrl));
    }
  }

  _onBufferingUpdate(int percent) {
    if (widget.updateMe.contains(WatchableAudioProperties.audioBuffering)) {
      setState(() {});
    }
  }

  _onAudioReady() {
    if (widget.updateMe.contains(WatchableAudioProperties.audioLength)) {
      setState(() {});
    }
  }

  _onPlayerPlaybackUpdate(Duration position) {
    if (widget.updateMe.contains(WatchableAudioProperties.audioPlayhead)) {
      setState(() {});
    }
  }

  _onStateChanged(AudioPlayerState newState) {
    _log.fine('onStateChnaged: $newState');
    if (widget.updateMe.contains(WatchableAudioProperties.audioPlayerState)) {
      setState(() {});
    }
  }

  _onSeekingChanged(bool isSeeking) {
    _log.fine('onSeekingChanged: $isSeeking');
    if (widget.updateMe.contains(WatchableAudioProperties.audioSeeking)) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.playerBuilder != null
      ? widget.playerBuilder(context, _player, widget.child)
      : widget.child;
  }
}

enum WatchableAudioProperties {
  audioPlayerState,
  audioLength,
  audioBuffering,
  audioPlayhead,
  audioSeeking,
}

enum PlaybackState {
  playing,
  paused,
}

class AudioComponent extends StatefulWidget {

  final List<WatchableAudioProperties> updateMe;
  final Widget Function(BuildContext, AudioPlayer, Widget child) playerBuilder;
  final Widget child;

  AudioComponent({
    this.updateMe = const [],
    @required this.playerBuilder,
    this.child,
  });

  @override
  _AudioComponentState createState() => new _AudioComponentState();
}

class _AudioComponentState extends State<AudioComponent> {

  AudioPlayer _player;

  @override
  void initState() {
    super.initState();

    _player = _AudioState.of(context);
    if (_player == null) {
      throw new StateError('AudioComponent could not find an Audio ancestor.');
    }
    _player.addListener(
        onBufferingUpdate: _onBufferingUpdate,
        onAudioReady: _onAudioReady,
        onPlayerPlaybackUpdate: _onPlayerPlaybackUpdate,
        onStateChanged: _onStateChanged,
        onSeekStarted: () {
          _onSeekingChanged(true);
        },
        onSeekCompleted: () {
          _onSeekingChanged(false);
        }
    );
  }

  @override
  void dispose() {
    _player = null;
    super.dispose();
  }

  _onBufferingUpdate(int percent) {
    if (widget.updateMe.contains(WatchableAudioProperties.audioBuffering)) {
      setState(() {});
    }
  }

  _onAudioReady() {
    if (widget.updateMe.contains(WatchableAudioProperties.audioLength)) {
      setState(() {});
    }
  }

  _onPlayerPlaybackUpdate(Duration position) {
    if (widget.updateMe.contains(WatchableAudioProperties.audioPlayhead)) {
      setState(() {});
    }
  }

  _onStateChanged(AudioPlayerState newState) {
    _log.fine('onStateChnaged: $newState');
    if (widget.updateMe.contains(WatchableAudioProperties.audioPlayerState)) {
      setState(() {});
    }
  }

  _onSeekingChanged(bool isSeeking) {
    _log.fine('onSeekingChanged: $isSeeking');
    if (widget.updateMe.contains(WatchableAudioProperties.audioSeeking)) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.playerBuilder != null
        ? widget.playerBuilder(context, _player, widget.child)
        : widget.child;
  }
}
