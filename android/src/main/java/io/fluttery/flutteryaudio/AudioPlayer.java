package io.fluttery.flutteryaudio;

import android.media.MediaPlayer;
import android.os.Handler;
import android.os.HandlerThread;
import android.support.annotation.NonNull;
import android.util.Log;

import java.io.IOException;
import java.util.Arrays;
import java.util.Set;
import java.util.concurrent.CopyOnWriteArraySet;

/**
 * Android side of AudioPlayer for the fluttery_audio plugin.
 *
 * Android docs for the MediaPlayer state machine:
 * https://developer.android.com/reference/android/media/MediaPlayer.html
 */
public class AudioPlayer {

    public static int playerId = -1;

    private static final String TAG = "AudioPlayer";

    private final Set<Listener> listeners = new CopyOnWriteArraySet<>();
    private MediaPlayer mediaPlayer;
    private State state;
    private boolean isPlaybackDesired = false;
    private Handler playbackPollHandler;
    private boolean isPollingPlayback = false;

    public AudioPlayer(@NonNull MediaPlayer mediaPlayer) {
        AudioPlayer.playerId = mediaPlayer.getAudioSessionId();
        this.mediaPlayer = mediaPlayer;
        this.state = State.idle;

        HandlerThread handlerThread = new HandlerThread("AudioPlayer");
        handlerThread.start();
        playbackPollHandler = new Handler(handlerThread.getLooper());

        MediaPlayerCallbacks mediaPlayerCallbacks = new MediaPlayerCallbacks();
        mediaPlayer.setOnPreparedListener(mediaPlayerCallbacks);
        mediaPlayer.setOnBufferingUpdateListener(mediaPlayerCallbacks);
        mediaPlayer.setOnSeekCompleteListener(mediaPlayerCallbacks);
        mediaPlayer.setOnCompletionListener(mediaPlayerCallbacks);
        mediaPlayer.setOnErrorListener(mediaPlayerCallbacks);
    }

    public void release() {
        this.mediaPlayer.release();
        this.listeners.clear();
        this.playbackPollHandler.removeCallbacks(null);
    }

    public void addListener(@NonNull Listener listener) {
        listeners.add(listener);
    }

    public void removeListener(@NonNull Listener listener) {
        listeners.remove(listener);
    }

    public void load(String url) {
        Log.d(TAG, "load()");
        try {
            // Stop polling the playhead position in case we were already
            // playing some audio.
            stopPlaybackPolling();

            mediaPlayer.reset();
            mediaPlayer.setDataSource(url);
            mediaPlayer.prepareAsync();

            state = State.loading;
            for (Listener listener : listeners) {
                listener.onAudioLoading();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public boolean isAudioReady() {
        return Arrays.asList(
                State.paused,
                State.playing,
                State.completed
        ).indexOf(state) >= 0;
    }

    public int audioLength() {
        return mediaPlayer.getDuration();
    }

    public void play() {
        Log.d(TAG, "play()");
        isPlaybackDesired = true;

        if (canPlay()) {
            mediaPlayer.start();
            state = State.playing;

            for (Listener listener : listeners) {
                listener.onPlayerPlaying();
            }

            startPlaybackPolling();
        } else {
            Log.w(TAG, "Can't play in current MediaPlayer state: " + state);
        }
    }

    private boolean canPlay() {
        return Arrays.asList(
                State.paused,
                State.completed
        ).indexOf(state) >= 0;
    }

    public boolean isPlaying() {
        return state == State.playing;
    }

    public int playbackPosition() {
        return mediaPlayer.getCurrentPosition();
    }

    public void pause() {
        Log.d(TAG, "pause()");
        isPlaybackDesired = false;

        if (state == State.playing) {
            mediaPlayer.pause();
            state = State.paused;

            for (Listener listener : listeners) {
                listener.onPlayerPaused();
            }

            stopPlaybackPolling();
        } else {
            Log.w(TAG, "Can't pause in current MediaPlayer state: " + state);
        }
    }

    public boolean isPaused() {
        return state == State.paused;
    }

    public void stop() {
        Log.d(TAG, "stop()");
        isPlaybackDesired = false;

        if (canStop()) {
            mediaPlayer.stop();
            state = State.stopped;

            for (Listener listener : listeners) {
                listener.onPlayerStopped();
            }

            stopPlaybackPolling();
        } else {
            Log.w(TAG, "Can't stop in current MediaPlayer state: " + state);
        }
    }

    private boolean canStop() {
        return Arrays.asList(
                State.playing,
                State.paused,
                State.completed
        ).indexOf(state) >= 0;
    }

    public boolean isStopped() {
        return state == State.stopped;
    }

    public void seek(int seekPositionInMillis) {
        Log.d(TAG, "seek() - Current playhead: "
                + mediaPlayer.getCurrentPosition()
                + ", Seek position: " + seekPositionInMillis + "ms");
        if (canSeek()) {
            // Seek doesn't have its own dedicated state so when exactly
            // it starts and completes is variable. Therefore, we notify
            // our listeners before we even make the call to seek() so
            // that we don't risk sending onSeekStarted() AFTER
            // onSeekCompleted().
            for (Listener listener : listeners) {
                listener.onSeekStarted();
            }

            mediaPlayer.seekTo(seekPositionInMillis);
        } else {
            Log.w(TAG, "Can't seek in current MediaPlayer state.");
        }
    }

    private boolean canSeek() {
        return Arrays.asList(
                State.playing,
                State.paused,
                State.completed
        ).indexOf(state) >= 0;
    }

    private void startPlaybackPolling() {
        if (!isPollingPlayback) {
            isPollingPlayback = true;
            playbackPollHandler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    if (isPollingPlayback) {
//                        Log.d(TAG, "Notifying playback listeners of playhead change.");
                        for (Listener listener : listeners) {
                            listener.onPlayerPlaybackUpdate(
                                playbackPosition(),
                                audioLength()
                            );
                        }

                        playbackPollHandler.postDelayed(this, 500);
                    }
                }
            }, 500);
        }
    }

    private void stopPlaybackPolling() {
        isPollingPlayback = false;
        playbackPollHandler.removeCallbacks(null);
    }

    private class MediaPlayerCallbacks implements MediaPlayer.OnPreparedListener,
            MediaPlayer.OnBufferingUpdateListener,
            MediaPlayer.OnErrorListener,
            MediaPlayer.OnSeekCompleteListener,
            MediaPlayer.OnCompletionListener {

        @Override
        public void onPrepared(MediaPlayer mp) {
            Log.d(TAG, "onPrepared()");

            for (Listener listener : listeners) {
                listener.onAudioReady();
            }

            state = State.paused;
            if (isPlaybackDesired) {
                play();
            } else {
                for (Listener listener : listeners) {
                    listener.onPlayerPaused();
                }
            }
        }

        @Override
        public void onBufferingUpdate(MediaPlayer mp, int percent) {
            Log.d(TAG, "onBufferingUpdate(): " + percent + "%");
            for (Listener listener : listeners) {
                listener.onBufferingUpdate(percent);
            }
        }

        @Override
        public void onSeekComplete(MediaPlayer mp) {
            Log.d(TAG, "onSeekComplete() - playhead: " + mp.getCurrentPosition());
            for (Listener listener : listeners) {
                listener.onSeekCompleted();
            }
        }

        @Override
        public void onCompletion(MediaPlayer mp) {
            Log.d(TAG, "onCompletion()");
            state = State.completed;

            for (Listener listener : listeners) {
                listener.onPlayerCompleted();
            }

            stopPlaybackPolling();
        }

        @Override
        public boolean onError(MediaPlayer mp, int what, int extra) {
            Log.w(TAG, "onError()");
            state = State.error;
            stopPlaybackPolling();

            return false;
        }
    }

    /**
     * Listener that receives all possible audio player updates over time.
     */
    public interface Listener {
        void onAudioLoading();

        void onBufferingUpdate(int percent);

        void onAudioReady();

        void onPlayerPlaying();

        void onPlayerPlaybackUpdate(int position, int audioLength);

        void onPlayerPaused();

        void onPlayerStopped();

        void onPlayerCompleted();

        void onSeekStarted(); // TODO: should we pass current and desired times?

        void onSeekCompleted(); // TODO: should we pass current time?
    }

    /**
     * A no-op implementation of {@link Listener} so that clients only
     * have to implement the callbacks that they care about.
     */
    public static class EmptyListener implements Listener {

        @Override
        public void onAudioLoading() {}

        @Override
        public void onBufferingUpdate(int percent) {}

        @Override
        public void onAudioReady() {}

        @Override
        public void onPlayerPlaying() {}

        @Override
        public void onPlayerPlaybackUpdate(int position, int audioLength) {}

        @Override
        public void onPlayerPaused() {}

        @Override
        public void onPlayerStopped() {}

        @Override
        public void onPlayerCompleted() {}

        @Override
        public void onSeekStarted() {}

        @Override
        public void onSeekCompleted() {}
    }

    private enum State {
        idle,
        loading,
        paused,
        playing,
        stopped,
        completed,
        error;
    }
}
