$amp_norm = 1.0
$scale = 1.0
$start_time = 0.0

def sinewave(hz, t)
   Math.sin(2.0*Math::PI*t*hz);
end

def squarewave(hz, t)
  if sinewave(hz, t) < 0.0
    -1.0
  else
    1.0
  end
end

def sawtoothwave(hz, t)
  cycle = t*hz
  (cycle - cycle.floor) * 2 - 1
end

def trianglewave(hz, t)
  offset = AUDIO_SAMPLING_FREQ/(8.0*hz)
  a = sawtoothwave(hz, t-offset) * 2 + 1
  if (a > 1)
    2 - a
  else
    a
  end
end

def noise
  random(-1.0, 1.0)
end

def adshr(a, d, s, h, r, t)
  if (t < 0)
    0.0
  elsif t <= a
    t/a
  elsif t <= a+d
    dt = t-a;
    1 + dt * -(1-s)/d
  elsif t <= a+d+h
    s
  elsif t <= a+d+h+r
    dt = t-(a+d+h)
    s + dt * -s/r
  else
    0.0
  end
end

def slide(amt, len, t)
  if (t < 0)
      1.0
  elsif (t > len)
      1.0 + amt
  else
      1.0 + (t/len)*amt
  end
end

def waveform t
  sinewave(440, t) * adshr(0.1, 0.1, 0.6, 0.2, 0.1, t);
end

def build(duration)
  n = (AUDIO_SAMPLING_FREQ*duration).to_i
  (0...n).map { |i| (waveform(i.to_f/AUDIO_SAMPLING_FREQ) * AUDIO_MAX_AMP).to_i }
end

def draw
  clear
  color(255, 255, 255, 100)
  prev_x = prev_y = 0.0 
  n = (SCREEN_WIDTH * $scale).to_i + 1
  n.times do |i|
    index = ($start_time*AUDIO_SAMPLING_FREQ).to_i + i
    a = ($samples[index]||0.0)*($amp_norm/AUDIO_MAX_AMP)
    x = i/$scale
    y = SCREEN_HEIGHT - (a*-0.5+0.5)*(SCREEN_HEIGHT-1)
    if (x != 0)
      line(prev_x, prev_y, x, y, aa: true)
    end
    prev_x = x
    prev_y = y
  end
end

len = 1.0
$samples = build(len)
sound($samples)

while true
  ks = keys
  time_speed = 0
  scale_speed = 1.0
  time_accel = 10.0*$scale/AUDIO_SAMPLING_FREQ
  scale_accel = 0.1
  if ks.member? 'space'
    sound($samples)
    delay(len*1000)
  elsif ks.member? 'd'
    time_speed += time_accel
  elsif ks.member? 'a'
    time_speed -= time_accel
  elsif ks.member? 'z'
    scale_speed += scale_accel
  elsif ks.member? 'x'
    scale_speed -= scale_accel
  end
  $start_time += time_speed
  $scale *= scale_speed
  draw
  display
  delay(32)
end
