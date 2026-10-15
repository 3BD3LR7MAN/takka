package com.example.takka

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Handler
import android.os.Looper
import java.io.File
import kotlin.math.PI
import kotlin.math.min
import kotlin.math.sin

/** Plays generated short PCM tones so sound feedback does not depend on the
 * device's optional system-click sound setting. Alarms use Android's alarm
 * audio usage and loop until explicitly stopped. */
class MobileAudioPlayer {
    private data class Tone(val frequency: Double, val durationMs: Int, val gapMs: Int = 70)

    private val handler = Handler(Looper.getMainLooper())
    private var activeTrack: AudioTrack? = null
    private var activeMediaPlayer: MediaPlayer? = null
    private var cleanup: Runnable? = null

    @Synchronized
    fun playEffect(effect: String, theme: String) {
        if (theme == "muted") return
        play(effectPattern(effect, theme), loop = false, alarmUsage = false)
    }

    @Synchronized
    fun playRingtone(ringtoneId: String, customPath: String? = null) {
        if (!customPath.isNullOrBlank() && File(customPath).isFile &&
            playCustomFile(customPath, loop = true, alarmUsage = true)) return
        play(ringtonePattern(ringtoneId), loop = true, alarmUsage = true)
    }

    @Synchronized
    fun startAlarm(ringtoneId: String, customPath: String? = null) {
        if (!customPath.isNullOrBlank() && File(customPath).isFile &&
            playCustomFile(customPath, loop = true, alarmUsage = true)) return
        play(ringtonePattern(ringtoneId) + Tone(0.0, 450, 0), loop = true, alarmUsage = true)
    }

    @Synchronized
    fun stopRingtone() = stopAll()

    @Synchronized
    fun stopAlarm() = stopAll()

    @Synchronized
    fun stopAll() {
        cleanup?.let(handler::removeCallbacks)
        cleanup = null
        val old = activeTrack
        activeTrack = null
        if (old != null) {
            try { old.pause() } catch (_: Exception) {}
            try { old.flush() } catch (_: Exception) {}
            try { old.stop() } catch (_: Exception) {}
            try { old.release() } catch (_: Exception) {}
        }
        val oldMedia = activeMediaPlayer
        activeMediaPlayer = null
        if (oldMedia != null) {
            try { if (oldMedia.isPlaying) oldMedia.stop() } catch (_: Exception) {}
            try { oldMedia.release() } catch (_: Exception) {}
        }
    }

    @Synchronized
    private fun playCustomFile(path: String, loop: Boolean, alarmUsage: Boolean): Boolean {
        stopAll()
        var created: MediaPlayer? = null
        try {
            created = MediaPlayer()
            created.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(if (alarmUsage) AudioAttributes.USAGE_ALARM else AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build(),
            )
            created.isLooping = loop
            created.setDataSource(path)
            created.prepare()
            val target = created
            created.setOnCompletionListener {
                synchronized(this) {
                    if (activeMediaPlayer === target) stopAll()
                }
            }
            activeMediaPlayer = created
            created.start()
            return true
        } catch (_: Exception) {
            try { created?.release() } catch (_: Exception) {}
            activeMediaPlayer = null
            return false
        }
    }

    @Synchronized
    private fun play(tones: List<Tone>, loop: Boolean, alarmUsage: Boolean) {
        stopAll()
        if (tones.isEmpty()) return

        val sampleRate = 44100
        val pcm = makePcm(tones, sampleRate)
        if (pcm.isEmpty()) return
        val attributes = AudioAttributes.Builder()
            .setUsage(if (alarmUsage) AudioAttributes.USAGE_ALARM else AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val format = AudioFormat.Builder()
            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
            .setSampleRate(sampleRate)
            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
            .build()

        var created: AudioTrack? = null
        try {
            created = AudioTrack.Builder()
                .setAudioAttributes(attributes)
                .setAudioFormat(format)
                .setTransferMode(AudioTrack.MODE_STATIC)
                .setBufferSizeInBytes(pcm.size * 2)
                .build()
            val written = created.write(pcm, 0, pcm.size, AudioTrack.WRITE_BLOCKING)
            if (written <= 0 || created.state != AudioTrack.STATE_INITIALIZED) {
                created.release()
                return
            }
            if (loop) {
                created.setLoopPoints(0, written, -1)
            }
            activeTrack = created
            created.play()
            if (!loop) {
                val expectedMs = written * 1000L / sampleRate + 120L
                val target = created
                val task = Runnable {
                    synchronized(this) {
                        if (activeTrack === target) stopAll()
                    }
                }
                cleanup = task
                handler.postDelayed(task, expectedMs)
            }
        } catch (_: Exception) {
            try { created?.release() } catch (_: Exception) {}
            activeTrack = null
        }
    }

    private fun makePcm(tones: List<Tone>, sampleRate: Int): ShortArray {
        val result = ArrayList<Short>()
        for (tone in tones) {
            val count = tone.durationMs.coerceAtLeast(1) * sampleRate / 1000
            val fade = min(500, count / 3)
            for (i in 0 until count) {
                if (tone.frequency <= 0.0) {
                    result.add(0)
                } else {
                    val edge = if (fade == 0) 1.0 else min(1.0, min(i.toDouble() / fade, (count - 1 - i).toDouble() / fade))
                    val wave = sin(2.0 * PI * tone.frequency * i / sampleRate)
                    result.add((wave * edge * 0.24 * Short.MAX_VALUE).toInt().toShort())
                }
            }
            repeat(tone.gapMs.coerceAtLeast(0) * sampleRate / 1000) { result.add(0) }
        }
        return ShortArray(result.size) { result[it] }
    }

    private fun effectPattern(effect: String, theme: String): List<Tone> {
        val notes = when (theme) {
            "digital" -> mapOf("low" to 620.0, "mid" to 880.0, "high" to 1180.0)
            "pops" -> mapOf("low" to 420.0, "mid" to 600.0, "high" to 820.0)
            "clicks" -> mapOf("low" to 950.0, "mid" to 1250.0, "high" to 1550.0)
            else -> mapOf("low" to 523.0, "mid" to 784.0, "high" to 1047.0)
        }
        fun n(key: String, duration: Int = 115, gap: Int = 65) =
            Tone(notes[key] ?: 784.0, duration, gap)
        return when (effect) {
            "task_done" -> listOf(n("mid"), n("high", 170, 0))
            "event_saved" -> listOf(n("low", 100), n("mid", 100), n("high", 180, 0))
            "delete" -> listOf(n("high", 100), n("mid", 130), n("low", 180, 0))
            "mascot" -> listOf(n("high", 140), n("mid", 110, 0))
            else -> listOf(n("mid", 65, 0))
        }
    }

    private fun ringtonePattern(id: String): List<Tone> = when (id) {
        "digital_pulse" -> listOf(Tone(660.0, 180, 100), Tone(990.0, 180, 280))
        "zen_bell" -> listOf(Tone(523.0, 280, 100), Tone(784.0, 480, 320))
        "radar" -> listOf(Tone(1200.0, 100, 90), Tone(720.0, 100, 320))
        "crystal_harp" -> listOf(Tone(659.0, 160, 65), Tone(880.0, 160, 65), Tone(1175.0, 240, 300))
        "classic_alarm" -> listOf(Tone(880.0, 240, 120), Tone(880.0, 240, 380))
        else -> listOf(Tone(784.0, 220, 100), Tone(1047.0, 380, 420))
    }
}
