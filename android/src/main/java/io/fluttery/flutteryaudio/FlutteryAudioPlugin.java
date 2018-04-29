package io.fluttery.flutteryaudio;

import android.media.MediaPlayer;
import android.media.audiofx.Visualizer;
import android.support.annotation.NonNull;
import android.util.Log;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * FlutteryAudioPlugin
 */
public class FlutteryAudioPlugin implements MethodCallHandler {
  private static final String TAG = "FlutteryAudioPlugin";

  private static final Pattern METHOD_NAME_MATCH = Pattern.compile("audioplayer/([^/]+)/([^/]+)");
  private static final Pattern VISUALIZER_METHOD_NAME_MATCH = Pattern.compile("audiovisualizer/([^/]+)");

  private static MethodChannel channel;
  private static MethodChannel visualizerChannel;

  /**
   * Plugin registration.
   */
  public static void registerWith(Registrar registrar) {
    channel = new MethodChannel(registrar.messenger(), "fluttery_audio");
    channel.setMethodCallHandler(new FlutteryAudioPlugin());

    visualizerChannel = new MethodChannel(registrar.messenger(), "fluttery_audio_visualizer");
    visualizerChannel.setMethodCallHandler(new FlutteryAudioVisualizerPlugin());
  }

  private AudioPlayer player; // TODO: support multiple players.

  public FlutteryAudioPlugin() {
    final MediaPlayer mediaPlayer = new MediaPlayer();
    player = new AudioPlayer(mediaPlayer);

    player.addListener(new AudioPlayer.Listener() {

      @Override
      public void onAudioLoading() {
        Log.d(TAG, "Android -> Flutter: onAudioLoading()");
        channel.invokeMethod("onAudioLoading", null);
      }

      @Override
      public void onBufferingUpdate(int percent) {
        Log.d(TAG, "Android -> Flutter: onBufferingUpdate()");
        channel.invokeMethod("onBufferingUpdate", null);
      }

      @Override
      public void onAudioReady() {
        Log.d(TAG, "Android -> Flutter: onAudioReady()");
        Map<String, Object> args = new HashMap<>();
        args.put("audioLength", player.audioLength());
        channel.invokeMethod("onAudioReady", args);
      }

      @Override
      public void onPlayerPlaying() {
        Log.d(TAG, "Android -> Flutter: onPlayerPlaying()");
        channel.invokeMethod("onPlayerPlaying", null);
      }

      @Override
      public void onPlayerPlaybackUpdate(int position, int audioLength) {
//        Log.d(TAG, "Android -> Flutter: onPlayerPlaybackUpdate()");
        Map<String, Object> args = new HashMap<>();
        args.put("position", position);
        args.put("audioLength", audioLength);
        channel.invokeMethod("onPlayerPlaybackUpdate", args);
      }

      @Override
      public void onPlayerPaused() {
        Log.d(TAG, "Android -> Flutter: onPlayerPaused()");
        channel.invokeMethod("onPlayerPaused", null);
      }

      @Override
      public void onPlayerStopped() {
        Log.d(TAG, "Android -> Flutter: onPlayerStopped()");
        channel.invokeMethod("onPlayerStopped", null);
      }

      @Override
      public void onPlayerCompleted() {
        Log.d(TAG, "Android -> Flutter: onPlayerCompleted()");
        channel.invokeMethod("onPlayerCompleted", null);
      }

      @Override
      public void onSeekStarted() {
        Log.d(TAG, "Android -> Flutter: onSeekStarted()");
        channel.invokeMethod("onSeekStarted", null);
      }

      @Override
      public void onSeekCompleted() {
        Log.d(TAG, "Android -> Flutter: onSeekCompleted()");

        // We send the new seek position over the channel with the
        // onSeekCompleted call because clients will likely need to
        // know immediately after seeking what the position is. If we
        // don't send that information with this call then a client will
        // have to call back and ask, and due to the asynchronous nature
        // of channels, there will be a noticeable time gap between when
        // seeking ends and when clients are able to synchronize with the
        // new playback position which will lead to visual artifacts in the UI.
        Map<String, Object> args = new HashMap<>();
        args.put("position", player.playbackPosition());
        
        channel.invokeMethod("onSeekCompleted", args);
      }
    });
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    Log.d(TAG, "Flutter -> Android: " + call.method);
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

  private static class FlutteryAudioVisualizerPlugin implements MethodCallHandler {

    private AudioVisualizer visualizer = new AudioVisualizer();

    @Override
    public void onMethodCall(MethodCall call, Result result) {
//      Log.d(TAG, "Flutter -> Android: " + call.method);
      try {
        AudioVisualizerPlayerCall playerCall = parseMethodName(call.method);
        Log.d(TAG, playerCall.toString());

        switch (playerCall.command) {
          case "activate_visualizer":
            Log.d(TAG, "Activating visualizer");
            if (visualizer.isActive()) {
              Log.d(TAG, "Visualizer is already active. Ignoring.");
              return;
            }

            // TODO: support media player specification for visualizer
            // TODO: support requested sample rate and buffer size
            // TODO: support selection of FFT vs waveform
            visualizer.activate(new Visualizer.OnDataCaptureListener() {
              @Override
              public void onWaveFormDataCapture(Visualizer visualizer, byte[] waveform, int samplingRate) {
                Map<String, Object> args = new HashMap<>();
                args.put("waveform", waveform);

                visualizerChannel.invokeMethod("onWaveformVisualization", args);
              }

              @Override
              public void onFftDataCapture(Visualizer visualizer, byte[] sharedFft, int samplingRate) {
                byte[] fft = Arrays.copyOf(sharedFft, sharedFft.length);
                
                Map<String, Object> args = new HashMap<>();
                args.put("fft", fft);

                visualizerChannel.invokeMethod("onFftVisualization", args);
              }
            });
            break;
          case "deactivate_visualizer":
            Log.d(TAG, "Deactivating visualizer");
            visualizer.deactivate();
            break;
        }

        result.success(null);
      } catch (IllegalArgumentException e) {
        result.notImplemented();
      }
    }

    private AudioVisualizerPlayerCall parseMethodName(@NonNull String methodName) {
      Matcher matcher = VISUALIZER_METHOD_NAME_MATCH.matcher(methodName);

      if (matcher.matches()) {
        String command = matcher.group(1);
        return new AudioVisualizerPlayerCall(command);
      } else {
        Log.d(TAG, "Match not found");
        throw new IllegalArgumentException("Invalid audio visualizer message: " + methodName);
      }
    }

    private static class AudioVisualizerPlayerCall {
      public final String command;

      private AudioVisualizerPlayerCall(@NonNull String command) {
        this.command = command;
      }

      @Override
      public String toString() {
        return String.format("AudioVisualizerPlayerCall - Command: %s", command);
      }
    }
  }
}
