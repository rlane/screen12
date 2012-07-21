SOUND_CACHE = Hash.new { |h,k| h[k] = load_sound("resources/#{k}.wav") }

def sound snd
  if snd.is_a? String
    chunk = SOUND_CACHE[snd]
    play_sound(chunk)
  elsif snd.is_a? Array
    chunk = load_raw_sound(snd)
    play_sound(chunk)
    release_sound(chunk)
  else
    raise "unexpected sound argument type: #{snd.class}"
  end
end

NOTES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
TUNE = 2.0**(1.0/12)
A4 = 440.00

def frequency(octave, note)
  raise "no such note #{note.inspect}" unless NOTES.member?(note)
  half_steps = (octave - 4)*NOTES.size + (NOTES.index(note) - NOTES.index('A'))
  A4 * (TUNE**half_steps)
end

def envelope(frac)
  if frac < 0.75/2 then frac/0.75
  elsif frac < 0.75 then 1 - frac/0.75
  else 0
  end
end

def note_waveform(octave, note, duration, volume)
  freq = frequency(octave, note)
  amp = AUDIO_MAX_AMP * volume
  st = nil
  wave = lambda { |t| envelope(t/duration) * Math.sin(2.0*Math::PI*t*freq) }
  n = (AUDIO_SAMPLING_FREQ*duration).to_i
  (0...n).map { |i| (wave[i.to_f/AUDIO_SAMPLING_FREQ] * amp).to_i }
end

def play_parse str, opts={}
  waveform = []
  octave = 4
  tempo = 120 # quarter notes per minute
  duration = 4 # default note is a quarter note
  volume = opts[:volume] || 0.5
  total_len = 0.0
  str.split.each do |token|
    # TODO convert to regexes when mruby supports them
    token.upcase!
    if token == '<' then octave -= 1
    elsif token == '>' then octave += 1
    elsif token[0] == 'L' then duration = token[1..-1].to_i
    elsif token[0] == 'T' then tempo = token[1..-1].to_i
    elsif token[0] == 'O' then octave = token[1..-1].to_i
    elsif ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'P'].member? token[0..0]
      if token[1..1] == '#' or token[1..1] == '+'
        note = token[0..0] + '#'
        note_duration_str = token[2..-1]
      else
        note = token[0..0]
        note_duration_str = token[1..-1]
      end
      if not note_duration_str.empty?
        note_duration = note_duration_str.to_i
      else
        note_duration = duration
      end
      len = 4*60.0/(tempo*note_duration)
      total_len += len
      if note != 'P'
        waveform.concat(note_waveform(octave, note, len, volume))
      else
        waveform.concat(note_waveform(octave, 'A', len, 0))
      end
    else
      raise("unexpected play token #{token.inspect}")
    end
  end
  [waveform, total_len]
end

$play_end_time = -1

def play str, opts={}
  waveform, total_len = play_parse(str, opts)
  sound(waveform)
  waveform.clear
  delay(total_len*1000) if opts[:delay]
  end_time = time + total_len*1000
  $play_end_time = [$play_end_time, end_time].max
end

def playing?
  $play_end_time > time
end
