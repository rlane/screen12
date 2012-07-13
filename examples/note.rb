NOTE = 440

def sinewave(hz, t)
   Math.sin(2.0*Math::PI*t*hz);
end

def waveform(t)
  sinewave(NOTE, t)
end

n = AUDIO_SAMPLING_FREQ
samples = (0...n).map { |i| (waveform(i.to_f/AUDIO_SAMPLING_FREQ) * AUDIO_MAX_AMP).to_i }
sound(samples)
delay(1000)
