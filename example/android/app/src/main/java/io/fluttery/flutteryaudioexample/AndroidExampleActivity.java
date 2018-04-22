package io.fluttery.flutteryaudioexample;

import android.media.MediaPlayer;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.View;
import android.widget.SeekBar;

import io.fluttery.flutteryaudio.AudioPlayer;

public class AndroidExampleActivity extends AppCompatActivity {

    private static final String TAG = "AndroidExampleActivity";

    private static final String SOUNDCLOUD_ID_ELECTRO_MONOTONY = "266891990";
    private static final String SOUNDCLOUD_ID_DEBUT_TRANCE = "260578593";
    private static final String SOUNDCLOUD_ID_DEBUT = "258735531";
    private static final String SOUNDCLOUD_ID_MASTERS_TRANCE = "9540779";
    private static final String SOUNDCLOUD_ID_MASTERS_TRIBAL = "9540352";
    private static final String SOUNDCLOUD_OTHER = "295692063";
    private static final String STREAM_URL = "https://api.soundcloud.com/tracks/" + SOUNDCLOUD_ID_DEBUT_TRANCE +"/stream?secret_token=s-tj3IS&client_id=LBCcHmRB8XSStWL6wKH2HPACspQlXg2P";

    private AudioPlayer audioPlayer;
    private AudioPlayerListener audioPlayerListener;
    private SeekBar seekBar;
    private boolean draggingSeekBar = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_android_example);

        final MediaPlayer mediaPlayer = new MediaPlayer();
        audioPlayer = new AudioPlayer(mediaPlayer);

        audioPlayerListener = new AudioPlayerListener();
        audioPlayer.addListener(audioPlayerListener);

        findViewById(R.id.button_load).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                audioPlayer.load(STREAM_URL);
            }
        });
        findViewById(R.id.button_play).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                audioPlayer.play();
            }
        });
        findViewById(R.id.button_pause).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                audioPlayer.pause();
            }
        });
        findViewById(R.id.button_stop).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                audioPlayer.stop();
            }
        });

        seekBar = findViewById(R.id.seekbar);
        seekBar.setEnabled(false);
        seekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {

            private int dragPositionInMillis;

            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (fromUser) {
                    dragPositionInMillis = progress;
                }
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
                Log.d(TAG, "onStartTrackingTouch()");
                draggingSeekBar = true;
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
                Log.d(TAG, "onStopTrackingTouch()");
                if (draggingSeekBar) {
                    Log.d(TAG, "Drag position in millis: " + dragPositionInMillis);
                    audioPlayer.seek(dragPositionInMillis);
                }
                draggingSeekBar = false;
            }
        });
    }

    @Override
    protected void onResume() {
        super.onResume();
    }

    @Override
    protected void onPause() {
        super.onPause();
        audioPlayer.release();
    }

    private class AudioPlayerListener extends AudioPlayer.EmptyListener {
        @Override
        public void onAudioReady() {
            Log.d(TAG, "onAudioReady()");
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    seekBar.setEnabled(true);
                    seekBar.setMax(audioPlayer.audioLength());
                }
            });
        }

        @Override
        public void onPlayerPlaying() {
            Log.d(TAG, "onPlayerPlaying()");
        }

        @Override
        public void onPlayerPlaybackUpdate(int position, int audioLength) {
            Log.d(TAG, "Setting playback position to: " + position);
            if (!draggingSeekBar) {
                seekBar.setProgress(position);
            }
        }

        @Override
        public void onSeekStarted() {

        }

        @Override
        public void onSeekCompleted() {

        }
    }
}
