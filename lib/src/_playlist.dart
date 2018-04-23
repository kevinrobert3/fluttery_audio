import 'package:flutter/widgets.dart';
import 'package:fluttery_audio/src/_audio_player.dart';
import 'package:fluttery_audio/src/_audio_player_widgets.dart';

class AudioPlaylist extends StatefulWidget {

  final List<String> playlist;
  final int startPlayingFromIndex;
  final PlaybackState playbackState;
  final Widget child;

  AudioPlaylist({
    this.playlist = const [],
    this.startPlayingFromIndex = 0,
    this.playbackState = PlaybackState.paused,
    this.child,
  });

  @override
  _AudioPlaylistState createState() => new _AudioPlaylistState();
}

class _AudioPlaylistState extends State<AudioPlaylist> with Playlist {

  static Playlist of(BuildContext context) {
    return context.ancestorStateOfType(new TypeMatcher<_AudioPlaylistState>()) as Playlist;
  }

  int _activeAudioIndex;
  AudioPlayerState _prevState;

  @override
  void initState() {
    super.initState();
    _activeAudioIndex = widget.startPlayingFromIndex;
  }

  @override
  void didUpdateWidget(AudioPlaylist oldWidget) {
    super.didUpdateWidget(oldWidget);

    // TODO: how should we handle changes to the playlist?

    if (widget.startPlayingFromIndex != oldWidget.startPlayingFromIndex) {
      setState(() => _activeAudioIndex = widget.startPlayingFromIndex);
    }
  }

  void next() {
    if (_activeAudioIndex < (widget.playlist.length - 1)) {
      setState(() => ++_activeAudioIndex);
    }
  }

  void previous() {
    if (_activeAudioIndex > 0) {
      setState(() => --_activeAudioIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building with active index: $_activeAudioIndex');
    return new Audio(
      audioUrl: widget.playlist[_activeAudioIndex],
      playbackState: widget.playbackState,
      callMe: [
        WatchableAudioProperties.audioPlayerState,
      ],
      playerCallback: (BuildContext context, AudioPlayer player) {
        if (_prevState != player.state) {
          if (player.state == AudioPlayerState.completed) {
            print('Reached end of audio. Trying to play next clip.');
            // Playback has completed. Go to next song.
            next();
          }

          _prevState = player.state;
        }
      },
      child: widget.child,
    );
  }
}

class AudioPlaylistComponent extends StatefulWidget {

  final Function(BuildContext, Playlist, Widget child) playlistBuilder;
  final Widget child;

  AudioPlaylistComponent({
    this.playlistBuilder,
    this.child,
  });

  @override
  _AudioPlaylistComponentState createState() => new _AudioPlaylistComponentState();
}

class _AudioPlaylistComponentState extends State<AudioPlaylistComponent> {
  @override
  Widget build(BuildContext context) {
    return widget.playlistBuilder != null
      ? widget.playlistBuilder(
          context,
          _AudioPlaylistState.of(context),
          widget.child,
        )
      : widget.child;
  }
}

abstract class Playlist {
  void next();
  void previous();
}