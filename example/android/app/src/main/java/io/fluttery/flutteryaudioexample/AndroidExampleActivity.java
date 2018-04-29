package io.fluttery.flutteryaudioexample;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.Rect;
import android.media.MediaPlayer;
import android.media.audiofx.Visualizer;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.support.annotation.NonNull;
import android.support.v7.app.AppCompatActivity;
import android.util.AttributeSet;
import android.util.Log;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.SeekBar;

import io.fluttery.flutteryaudio.AudioPlayer;
import io.fluttery.flutteryaudio.AudioVisualizer;

public class AndroidExampleActivity extends AppCompatActivity {

    private static final String TAG = "AndroidExampleActivity";

    private static final String STREAM_URL = "https://api.soundcloud.com/tracks/260578593/stream?secret_token=s-tj3IS&client_id=LBCcHmRB8XSStWL6wKH2HPACspQlXg2P";

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

        final VisualizerView visualizerView = new VisualizerView(this);
        visualizerView.init();
        ((LinearLayout) findViewById(R.id.linearlayout)).addView(visualizerView);

        AudioVisualizer.instance.activate(new Visualizer.OnDataCaptureListener() {
            @Override
            public void onWaveFormDataCapture(Visualizer visualizer, final byte[] waveform, int samplingRate) {
//                runOnUiThread(new Runnable() {
//                    @Override
//                    public void run() {
//                        visualizerView.updateVisualizer(waveform);
//                    }
//                });
            }

            @Override
            public void onFftDataCapture(Visualizer visualizer, final byte[] fft, int samplingRate) {
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
//                        Log.d(TAG, "On FFT data");
                        visualizerView.updateVisualizer(fft);
                    }
                });
            }
        });
    }

    @Override
    protected void onPause() {
        AudioVisualizer.instance.deactivate();

        audioPlayer.release();
        super.onPause();
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

    public static class VisualizerView extends View {

        private byte[] mBytes;
        private float[] mPoints;
        private Rect mRect = new Rect();
        private Paint mForePaint = new Paint();

        public VisualizerView(Context context) {
            super(context);
            init();
        }

        private void init() {
            mBytes = null;
            mForePaint.setStrokeWidth(1f);
            mForePaint.setAntiAlias(true);
            mForePaint.setColor(Color.rgb(0, 128, 255));
        }

        public void updateVisualizer(byte[] bytes) {
            mBytes = bytes;
            invalidate();
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
//            renderWaveform(canvas);
//            renderFft(canvas);
            renderFftHistogram(canvas);
        }

        private void renderWaveform(@NonNull Canvas canvas) {
            if (mBytes == null) {
                return;
            }
            if (mPoints == null || mPoints.length < mBytes.length * 4) {
                mPoints = new float[mBytes.length * 4];
            }
            mRect.set(0, 0, getWidth(), getHeight());
            for (int i = 0; i < mBytes.length - 1; i++) {
                mPoints[i * 4] = mRect.width() * i / (mBytes.length - 1);
                mPoints[i * 4 + 1] = mRect.height() / 2
                        + ((byte) (mBytes[i] + 128)) * (mRect.height() / 2) / 128;
                mPoints[i * 4 + 2] = mRect.width() * (i + 1) / (mBytes.length - 1);
                mPoints[i * 4 + 3] = mRect.height() / 2
                        + ((byte) (mBytes[i + 1] + 128)) * (mRect.height() / 2)
                        / 128;
            }
            canvas.drawLines(mPoints, mForePaint);
        }

        private void renderFft(@NonNull Canvas canvas) {
            if (mBytes == null) {
                return;
            }
            if (mPoints == null || mPoints.length < mBytes.length * 4) {
                mPoints = new float[mBytes.length * 4];
            }
            mRect.set(0, 0, getWidth(), getHeight());

            int bytesToProcess = mBytes.length / 3;
            int widthPerSample = mRect.width() / (bytesToProcess / 2);
            for (int i = 0; i < bytesToProcess - 1; i++) {
                mPoints[i * 4] = i * widthPerSample;
                mPoints[i * 4 + 1] = mBytes[i];
                mPoints[i * 4 + 2] = (i + 1) * widthPerSample;
                mPoints[i * 4 + 3] = mBytes[i + 1];
            }
            canvas.drawLines(mPoints, mForePaint);
        }

        private void renderFftHistogram(@NonNull Canvas canvas) {
            if (mBytes == null) {
                return;
            }

            mRect.set(0, 0, getWidth(), getHeight());

            int bytesToProcess = mBytes.length / 10;
            int[] histogram = createHistogram(mBytes, 0, bytesToProcess, 10);
            int pointsToGraph = histogram.length;
            int widthPerSample = mRect.width() / (pointsToGraph - 1);

            if (mPoints == null || mPoints.length < pointsToGraph * 4) {
                mPoints = new float[pointsToGraph * 4];
            }

            for (int i = 0; i < histogram.length - 1; i++) {
//                Log.d(TAG, "Histogram group " + i + ": " + histogram[i]);
                mPoints[i * 4] = i * widthPerSample;
                mPoints[i * 4 + 1] = histogram[i];
                mPoints[i * 4 + 2] = (i + 1) * widthPerSample;
                mPoints[i * 4 + 3] = histogram[i + 1];
            }

            Path path = new Path();
            path.moveTo(mRect.width(), 0.0f);
            path.lineTo(0.0f, 0.0f);
            path.lineTo(mPoints[0], mPoints[1]);
            for (int i = 2; i < mPoints.length - 4; i = i + 2) {
                path.cubicTo(
                        mPoints[i - 2] + 50.0f, mPoints[i - 1],
                        mPoints[i] - 50.0f, mPoints[i + 1],
                        mPoints[i], mPoints[i + 1]
                );
            }

            path.lineTo(mRect.width(), 0.0f);
            path.close();

            canvas.drawPath(path, mForePaint);
        }

        private int[] createHistogram(byte[] raw, int start, int end, int bucketCount) {
//            Log.d(TAG, "Create histogram from start: " + start + " to: " + end);
            int samplesPerBucket = (end - start + 1) / bucketCount;
            int samplesTaken = (end - start + 1) - ((end - start + 1) % samplesPerBucket) - 1;
            int[] histogram = new int[bucketCount];
            int numInBucket = 0;
            int currBucket = 0;

            int loopStart = start;
            if (start == 0) {
                loopStart = 2;
                histogram[0] += mBytes[0];
            } else if (start == 1) {
                loopStart = 2;
            }
            for (int i = loopStart; i <= start + samplesTaken; i = i + 2) {
                if ((i - loopStart) % 2 == 1) {
                    continue;
                }

                int bucketIndex = (i - start) / samplesPerBucket;
                numInBucket = currBucket == bucketIndex ? numInBucket + 1 : 0;
                currBucket = bucketIndex;
//                Log.d(TAG, "i: " + i + ", samples per bucket: " + samplesPerBucket + ", index: " + bucketIndex + ", numInBucket: " + numInBucket);
                histogram[bucketIndex] += Math.abs(raw[i]);
            }

            return histogram;
        }
    }
}

