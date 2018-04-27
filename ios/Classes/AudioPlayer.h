//
//  Audio player with the following capabilities:
//  - stream from web URL
//  - playback from file URI
//  - seek to a time in a loaded audio stream/clip
//

#ifndef AudioPlayer_h
#define AudioPlayer_h

@protocol AudioPlayerListener;

@interface AudioPlayer : NSObject

// Is the audio stream/clip loaded to the point that it can be played?
@property (readonly) bool isAudioReady;

// Length of a prepared audio stream/clip in milliseconds
@property (readonly) long audioLength;

// Is audio playing?
@property (readonly) bool isPlaying;

// Current audio playback position in milliseconds
@property (readonly) int playbackPosition;

// Is audio playback currently paused?
@property (readonly) bool isPaused;

// Is audio in the stopped state? Stopped means audio has been unloaded.
@property (readonly) bool isStopped;

// Is audio done playing for the current stream/clip?
@property (readonly) bool isCompleted;

// Loads an audio stream from a URL or a clip from a URI. Audio does not
// play automatically. When enough audio is loaded to be played, listeners
// are notified via onAudioReady, then listeners are immediately notified
// of onPlayerPaused.
- (void) load:(NSString*) url;

// Starts playing audio that was previously loaded.
- (void) play;

// Pauses audio that's currently playing. Has no effect if already paused.
- (void) pause;

// Pauses any playing audio and then releases the audio stream/clip.
- (void) stop;

// Moves the playhead to the given time. Can seek when audio is playing
// or paused.
- (void) seek:(int64_t) seekPositionInMillis;

- (void) addListener:(id <AudioPlayerListener>) listener;

- (void) removeListener:(id <AudioPlayerListener>) listener;

@end

@protocol AudioPlayerListener

// An audio stream/clip just started being loaded.
- (void) onAudioLoading;

// An audio stream/clip has buffered to the given percent.
- (void) onBufferingUpdate:(int) percent;

// An audio stream/clip has been loaded to the point that it can be played.
// Immediately after this call listeners will be notified of either
// onPlayerPlaying or onPlayerPaused depending on what the state was prior
// to loading the audio.
- (void) onAudioReady:(long) audioLength;

// An audio stream/clip has started to play (this could be from the paused
// state or immediately after onAudioReady).
- (void) onPlayerPlaying;

// An audio stream/clip has progressed forward to the given playhead position.
- (void) onPlayerPlaybackUpdate:(int)position :(long)audioLength;

// An audio stream/clip has paused (this could be from the playing state or
// immediately after onAudioReady).
- (void) onPlayerPaused;

// An audio stream/clip has stopped which means playback has ceased AND the
// audio has been released. To start playing again, the caller must load a
// new audio stream/clip.
- (void) onPlayerStopped;

// An audio stream/clip has reached its end.  Playback has ceased.
- (void) onPlayerCompleted;

// A seek operation has begun.
- (void) onSeekStarted;

// A seek operation has completed.
- (void) onSeekCompleted:(long)position;

@end

#endif /* AudioPlayer_h */
