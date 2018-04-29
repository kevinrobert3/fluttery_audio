#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "AudioPlayer.h"

const NSString* TAG = @"AudioPlayer";

@implementation AudioPlayer {
  AVPlayer* _audioPlayer;
  NSMutableSet* _listeners;
  id _periodicListener;
  bool _isPlaybackDesired;
}

- (id)init {
  if (self = [super init]) {
    _audioPlayer = [[AVPlayer alloc] init];
    [_audioPlayer addObserver:self forKeyPath:@"status" options:0 context:nil];
    [_audioPlayer addObserver:self forKeyPath:@"rate" options:0 context:nil];
    _periodicListener = [_audioPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.5, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
      NSLog(@"Received time update: %f", CMTimeGetSeconds(time));
      for (id<AudioPlayerListener> listener in [self->_listeners allObjects]) {
        [listener onPlayerPlaybackUpdate:(CMTimeGetSeconds(time) * 1000) :self.audioLength];
      }
    }];
    
    _listeners = [[NSMutableSet alloc] init];
    
    _isAudioReady = FALSE;
    _isPlaying = FALSE;
  }
  return self;
}

- (void)deinit {
  [_audioPlayer removeTimeObserver:_periodicListener];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_audioPlayer.currentItem];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
  if ([keyPath isEqualToString:@"status"]) {
    if (_audioPlayer.status == AVPlayerStatusReadyToPlay && object == _audioPlayer.currentItem) {
      // Note: we look for the AVPlayerItem's status ready rather than the AVPlayer because this
      // way we know that the duration will be available.
      [self _onAudioReady];
    } else if (_audioPlayer.status == AVPlayerStatusFailed) {
      [self _onFailedToPrepareAudio];
    }
  } else if ([keyPath isEqualToString:@"rate"]) {
    [self _onPlaybackRateChange];
  }
}

- (void) _onAudioReady {
  if (!_isAudioReady) {
    NSLog(@"AVPlayer is ready to play.");
    _isAudioReady = TRUE;
    _isPlaying = FALSE;
    _isStopped = FALSE;
    _isCompleted = FALSE;
    NSLog(@"Audio length: %li", [self audioLength]);
    
    for (id<AudioPlayerListener> listener in [_listeners allObjects]) {
      [listener onAudioReady:[self audioLength]];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidFinish) name:AVPlayerItemDidPlayToEndTimeNotification object:_audioPlayer.currentItem];
    
    if ([_audioPlayer rate] > 0.0) {
      _isPlaying = TRUE;
      for (id<AudioPlayerListener> listener in [_listeners allObjects]) {
        [listener onPlayerPlaying];
      }
    } else if (_isPlaybackDesired) {
      _isPlaying = TRUE;
      [self play];
      
      // Theoretically we shouldn't need these callbacks here because our call
      // above to "play" should result in a callback about a rate change which would
      // then emit these same callbacks. However, this is not occuring when testing
      // the app so this is here as a stopgap fix until the root problem is found.
      for (id<AudioPlayerListener> listener in [_listeners allObjects]) {
        [listener onPlayerPlaying];
      }
    } else {
      _isPlaying = FALSE;
      for (id<AudioPlayerListener> listener in [_listeners allObjects]) {
        [listener onPlayerPaused];
      }
    }
  }
}

- (void) _onFailedToPrepareAudio {
  NSLog(@"AVPlayer failed to load audio");
  // TODO:
}

- (void) _onPlaybackRateChange {
  NSLog(@"Rate just changed to %f", _audioPlayer.rate);
  NSLog(@"Is playing? %@", _isPlaying ? @"YES" : @"NO");
  if (_audioPlayer.rate > 0 && !_isPlaying) {
    // Just started playing.
    NSLog(@"AVPlayer started playing.");
    for (id<AudioPlayerListener> listener in [_listeners allObjects]) {
      [listener onPlayerPlaying];
    }
    _isPlaying = TRUE;
    _isCompleted = FALSE;
  } else if (_audioPlayer.rate == 0 && _isPlaying) {
    // Just paused playing.
    NSLog(@"AVPlayer paused playback.");
    for (id<AudioPlayerListener> listener in [_listeners allObjects]) {
      [listener onPlayerPaused];
    }
    _isPlaying = FALSE;
  }
}

- (void) playerDidFinish {
  NSLog(@"playerDidFinish");
  _isPlaying = FALSE;
  _isCompleted = TRUE;
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_audioPlayer.currentItem];
  
  for (id<AudioPlayerListener> listener in [_listeners allObjects]) {
    [listener onPlayerCompleted];
  }
}

- (void) addListener:(id <AudioPlayerListener>) listener {
  [_listeners addObject:listener];
}

- (void) removeListener:(id <AudioPlayerListener>) listener {
  [_listeners removeObject:listener];
}

- (void) load:(NSString*) urlString {
  NSLog(@"%@: %@", TAG, @"load()");
  _isAudioReady = FALSE;
  _isStopped = FALSE;
  _isCompleted = FALSE;
  
  for (id<AudioPlayerListener> listener in [_listeners allObjects]) {
    [listener onAudioLoading];
  }
  
  // We need to assemble an AVURLAsset instead of sending of the URL directly into
  // AVPlayerItem because we need to load the "duration" of the audio stream which requires
  // using the AVURLAsset constructor.
  NSURL* url = [NSURL URLWithString:urlString];
  AVURLAsset* urlAsset = [AVURLAsset assetWithURL:url];
  AVPlayerItem* audio = [[AVPlayerItem alloc] initWithAsset:urlAsset automaticallyLoadedAssetKeys:@[@"duration"]];
  [audio addObserver:self forKeyPath:@"status" options:0 context:nil];

  [_audioPlayer replaceCurrentItemWithPlayerItem:audio];
}

- (long) audioLength {
  if (_audioPlayer.currentItem != nil && _audioPlayer.currentItem.duration.value > 0) {
    CMTime time = [_audioPlayer.currentItem duration];
    NSLog(@"Time value: %lld", time.value);
    NSLog(@"Timescale: %i", time.timescale);
    long millis = CMTimeGetSeconds(time) * 1000;
    return millis;
  } else {
    return -1;
  }
}

- (void) play {
  NSLog(@"%@: %@", TAG, @"play()");
  
  _isPlaybackDesired = TRUE;
  
  if (_isAudioReady) {
    if (self.isCompleted) {
      [self seek:0];
    }
    
    [_audioPlayer play];
  }
}

- (int) playbackPosition {
  if (_audioPlayer.currentItem != nil) {
    return CMTimeGetSeconds([_audioPlayer.currentItem currentTime]) * 1000;
  } else {
    return -1;
  }
}

- (void) pause {
  NSLog(@"%@: %@", TAG, @"pause()");
  _isPlaybackDesired = FALSE;
  [_audioPlayer pause];
}

- (bool) isPaused {
  return _isAudioReady && !_isPlaying;
}

- (void) stop {
  NSLog(@"%@: %@", TAG, @"stop()");
  
  _isPlaybackDesired = FALSE;
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_audioPlayer.currentItem];
  
  [_audioPlayer pause];
  
  for (id<AudioPlayerListener> listener in [_listeners allObjects]) {
    [listener onPlayerStopped];
  }
}

- (void) seek:(int64_t) seekPositionInMillis {
  NSLog(@"%@: %@: %lli", TAG, @"seek()", seekPositionInMillis);
  CMTime seekTime = CMTimeMakeWithSeconds(seekPositionInMillis / 1000, NSEC_PER_SEC);
  NSLog(@"%@: Decoded seek seconds: %f", TAG, CMTimeGetSeconds(seekTime));
  
  for (id<AudioPlayerListener> listener in [_listeners allObjects]) {
    [listener onSeekStarted];
  }
  
  [_audioPlayer seekToTime:seekTime completionHandler:^(bool finished) {
    for (id<AudioPlayerListener> listener in [self->_listeners allObjects]) {
      [listener onSeekCompleted:[self playbackPosition]];
    }
  }];
}

@end
