#import "FlutteryAudioPlugin.h"
#import "AudioPlayer.h"

@implementation FlutteryAudioPlugin {
  FlutterMethodChannel* _channel;
  AudioPlayer* _audioPlayer;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"fluttery_audio"
            binaryMessenger:[registrar messenger]];
  FlutteryAudioPlugin* instance = [[FlutteryAudioPlugin alloc] initWithChannel: channel];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (id)initWithChannel:(FlutterMethodChannel*)channel {
  if (self = [super init]) {
    _channel = channel;
    
    _audioPlayer = [[AudioPlayer alloc] init];
    [_audioPlayer addListener:self];
  }
  return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSError *regexError = NULL;
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"audioplayer/([^/]+)/([^/]+)" options:NSRegularExpressionCaseInsensitive error:&regexError];

  NSArray *matches = [regex matchesInString:call.method options:0 range:NSMakeRange(0, [call.method length])];
  NSString *playerId = nil;
  NSString *command = nil;
  NSRange first = [matches[0] rangeAtIndex:1];
  playerId = [call.method substringWithRange:first];

  NSRange second = [matches[0] rangeAtIndex:2];
  command = [call.method substringWithRange:second];

  NSLog(@"1:%@ 2:%@.", playerId, command);

  NSLog(@"Command: %@", command);
  if ([@"load" isEqualToString:command]) {
    NSLog(@"Received 'load' message.");
    
    NSDictionary* args = call.arguments;
    NSString* url = args[@"audioUrl"];
    NSLog(@"Audio url: %@", url);
    
    [_audioPlayer load:url];
    
    result(nil);
  } else if ([@"play" isEqualToString:command]) {
    NSLog(@"Received 'play' message.");
    
    [_audioPlayer play];
    
    result(nil);
  } else if ([@"pause" isEqualToString:command]) {
    NSLog(@"Received 'pause' message.");
    
    [_audioPlayer pause];
    
    result(nil);
  } else if ([@"stop" isEqualToString:command]) {
    NSLog(@"Received 'stop' message.");
    
    [_audioPlayer stop];
    
    result(nil);
  } else if ([@"seek" isEqualToString:command]) {
    NSLog(@"Received 'seek' message.");
    
    NSDictionary* args = call.arguments;
    int64_t seekPositionInMillis = ((NSNumber*)args[@"seekPosition"]).unsignedIntegerValue;
    [_audioPlayer seek:seekPositionInMillis];
    
    result(nil);
  } else {
    NSLog(@"Received unknown message: %@", call.method);
    
    result(FlutterMethodNotImplemented);
  }
}

//----------- AudioPlayerListener -----------
- (void) onAudioLoading {
  NSLog(@"onAudioLoading");
  [_channel invokeMethod:@"onAudioLoading" arguments:nil];
}

- (void) onBufferingUpdate:(int) percent {
  NSLog(@"onBufferingUpdate: %i", percent);
  NSDictionary* args = @{
     @"percent" : @(percent)
  };
  [_channel invokeMethod:@"onBufferingUpdate" arguments:args];
}

- (void) onAudioReady:(long) audioLengthInMillis {
  NSLog(@"onAudioReady");
  NSDictionary* args = @{ @"audioLength" : @(audioLengthInMillis) };
  [_channel invokeMethod:@"onAudioReady" arguments:args];
}

- (void) onPlayerPlaying {
  NSLog(@"onPlayerPlaying");
  [_channel invokeMethod:@"onPlayerPlaying" arguments:nil];
}

- (void) onPlayerPlaybackUpdate:(int)position :(long)audioLength {
  NSLog(@"onPlayerPlaybackUpdate - position: %i", position);
  NSDictionary* args = @{ @"position" : @(position), @"audioLength": @(audioLength) };
  [_channel invokeMethod:@"onPlayerPlaybackUpdate" arguments:args];
}

- (void) onPlayerPaused {
  NSLog(@"onPlayerPaused");
  [_channel invokeMethod:@"onPlayerPaused" arguments:nil];
}

- (void) onPlayerStopped {
  NSLog(@"onPlayerStopped");
  [_channel invokeMethod:@"onPlayerStopped" arguments:nil];
}

- (void) onPlayerCompleted {
  NSLog(@"onPlayerCompleted");
  [_channel invokeMethod:@"onPlayerCompleted" arguments:nil];
}

- (void) onSeekStarted {
  NSLog(@"onSeekStarted");
  [_channel invokeMethod:@"onSeekStarted" arguments:nil];
}

- (void) onSeekCompleted:(long) position {
  NSLog(@"onSeekCompleted");
  NSDictionary* args = @{ @"position" : @(position) };
  [_channel invokeMethod:@"onSeekCompleted" arguments:args];
}

//---------- End AudioPlayerListener ---------

@end
