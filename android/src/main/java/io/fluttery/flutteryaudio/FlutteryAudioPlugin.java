package io.fluttery.flutteryaudio;

import android.content.Context;
import android.media.MediaPlayer;
import android.support.annotation.NonNull;
import android.util.Log;

import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * FlutteryAudioPlugin
 */
public class FlutteryAudioPlugin implements MethodCallHandler {
  private static final String TAG = "FlutteryAudioPlugin";

  private static final Pattern METHOD_NAME_MATCH = Pattern.compile("audioplayer/([^/]+)/([^/]+)");

  private static MethodChannel channel;

  /**
   * Plugin registration.
   */
  public static void registerWith(Registrar registrar) {
    channel = new MethodChannel(registrar.messenger(), "fluttery_audio");
    channel.setMethodCallHandler(new FlutteryAudioPlugin());
  }

  private AudioPlayer player; // TODO: support multiple players.

  public FlutteryAudioPlugin() {
    MediaPlayer mediaPlayer = new MediaPlayer();
    player = new AudioPlayer(mediaPlayer);

    player.addListener(new AudioPlayer.Listener() {

      @Override
      public void onAudioLoading() {
        channel.invokeMethod("onAudioLoading", null);
      }

      @Override
      public void onBufferingUpdate(int percent) {
        channel.invokeMethod("onBufferingUpdate", null);
      }

      @Override
      public void onAudioReady() {
        Map<String, Object> args = new HashMap<>();
        args.put("audioLength", player.audioLength());
        channel.invokeMethod("onAudioReady", args);
      }

      @Override
      public void onPlayerPlaying() {
        channel.invokeMethod("onPlayerPlaying", null);
      }

      @Override
      public void onPlayerPlaybackUpdate(int position, int audioLength) {
        Map<String, Object> args = new HashMap<>();
        args.put("position", position);
        args.put("audioLength", audioLength);
        channel.invokeMethod("onPlayerPlaybackUpdate", args);
      }

      @Override
      public void onPlayerPaused() {
        channel.invokeMethod("onPlayerPaused", null);
      }

      @Override
      public void onPlayerStopped() {
        channel.invokeMethod("onPlayerStopped", null);
      }

      @Override
      public void onPlayerCompleted() {
        channel.invokeMethod("onPlayerCompleted", null);
      }

      @Override
      public void onSeekStarted() {
        channel.invokeMethod("onSeekStarted", null);
      }

      @Override
      public void onSeekCompleted() {
        channel.invokeMethod("onSeekCompleted", null);
      }
    });
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    Log.d(TAG, "onMethodCall(): " + call.method);
    try {
      AudioPlayerCall playerCall = parseMethodName(call.method);
      Log.d(TAG, playerCall.toString());

      // TODO: account for player ID

      switch (playerCall.command) {
        case "load":
          Log.d(TAG, "Loading new audio.");
          String audioUrl = call.argument("audioUrl");
          player.load(audioUrl);
          break;
        case "play":
          Log.d(TAG, "Playing audio");
          player.play();
          break;
        case "pause":
          Log.d(TAG, "Pausing audio");
          player.pause();
          break;
        case "stop":
          Log.d(TAG, "Stopping audio");
          player.stop();
          break;
        case "seek":
          Log.d(TAG, "Seeking audio");
          int seekPositionInMillis = call.argument("seekPosition");
          player.seek(seekPositionInMillis);
          break;
      }

      result.success(null);
    } catch (IllegalArgumentException e) {
      result.notImplemented();
    }
  }

  private AudioPlayerCall parseMethodName(@NonNull String methodName) {
    Matcher matcher = METHOD_NAME_MATCH.matcher(methodName);

    if (matcher.matches()) {
      String playerId = matcher.group(1);
      String command = matcher.group(2);
      return new AudioPlayerCall(playerId, command);
    } else {
      Log.d(TAG, "Match not found");
      throw new IllegalArgumentException("Invalid audio player message: " + methodName);
    }
  }

  private static class AudioPlayerCall {
    public final String playerId;
    public final String command;

    private AudioPlayerCall(@NonNull String playerId, @NonNull String command) {
      this.playerId = playerId;
      this.command = command;
    }

    @Override
    public String toString() {
      return String.format("AudioPlayerCall - Player ID: %s, Command: %s", playerId, command);
    }
  }
}
