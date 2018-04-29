package io.fluttery.flutteryaudio;

import android.media.audiofx.Equalizer;
import android.media.audiofx.Visualizer;
import android.support.annotation.NonNull;

public class AudioVisualizer {

    public static final AudioVisualizer instance = new AudioVisualizer();

    private static final String TAG = "AudioVisualizer";

    private Visualizer visualizer;

    public boolean isActive() {
        return visualizer != null;
    }

    public void activate(@NonNull Visualizer.OnDataCaptureListener listener) {
        // TODO: handle playerId in non-static way
        // TODO: support multiple AuidioPlayers
        visualizer = new Visualizer(AudioPlayer.playerId);
        visualizer.setCaptureSize(Visualizer.getCaptureSizeRange()[1]);
        visualizer.setDataCaptureListener(
                listener,
                Visualizer.getMaxCaptureRate() / 2,
                false,
                true
        );
        visualizer.setEnabled(true);

        Equalizer equalizer = new Equalizer(0, AudioPlayer.playerId);
        equalizer.setEnabled(true);
    }

    public void deactivate() {
        visualizer.release();
        visualizer = null;
    }

}
