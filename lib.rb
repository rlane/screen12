## Random number generator functions
class PRNG
  MAX = 2147483647

  def initialize seed=42
    @state = seed
  end

  def next
    @state = (16807*@state) % MAX
  end

  def range low, high
    range = (high - low).to_f
    low + (self.next.to_f/MAX)*range
  end
end

$lib_prng = PRNG.new 1
def random low, high
  $lib_prng.range low, high
end


## Image functions
COLORKEYS = {
  "resources/tyrian1.png" => [0xBF, 0xDC, 0xBF],
  "resources/tyrian2.png" => [0xBF, 0xDC, 0xBF],
  "resources/tyrian3.png" => [0xBF, 0xDC, 0xBF],
}

IMAGES = {
  # name => [filename, x, y, w, h]
  'tyrian/player' => ["resources/tyrian1.png", 125, 154, 37, 28],
  'tyrian/enemy' => ["resources/tyrian2.png", 30, 2, 17, 25],
  'tyrian/bullet' => ["resources/tyrian3.png", 112, 42, 3, 11],
  'tyrian/bullet2' => ["resources/tyrian3.png", 147, 100, 5, 12],
}

IMAGE_CACHE = Hash.new { |h,k| h[k] = load_image(k, *(COLORKEYS[k] || [-1,-1,-1])) }

def image name, x, y
  raise "no such image: #{name}" unless IMAGES.member? name
  filename, cx, cy, cw, ch = IMAGES[name]
  surface = IMAGE_CACHE[filename]
  blit surface, x, y, cx, cy, cw, ch
  nil
end


## Math functions
# Todo benchmark some of these against C implementations
PI = Math::PI

def distance x1, y1, x2, y2
  Math.sqrt((x1 - x2)**2 + (y1 - y2)**2)
end

def deg2rad deg
  deg * 2*PI/360
end

def sin angle
  Math.sin(deg2rad(angle))
end

def cos angle
  Math.cos(deg2rad(angle))
end

def tan angle
  Math.tan(deg2rad(angle))
end


## Audio functions
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

def play_parse str
  waveform = []
  octave = 4
  tempo = 120 # quarter notes per minute
  duration = 4 # default note is a quarter note
  volume = 0.5
  total_len = 0.0
  str.split.each do |token|
    token.upcase!
    if token == '<' then octave -= 1
    elsif token == '>' then octave += 1
    elsif token[0] == 'L' then duration = token[1..-1].to_i
    elsif token[0] == 'T' then tempo = token[1..-1].to_i
    elsif token[0] == 'O' then octave = token[1..-1].to_i
    elsif NOTES.member? token[0..0]
      if token[1..1] == '#'
        note = token[0..1]
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
      waveform.concat(note_waveform(octave, note, len, volume))
    else
      puts("unexpected play token #{token.inspect}")
    end
  end
  [waveform, total_len]
end

def play str, opts={}
  waveform, total_len = play_parse(str)
  sound(waveform)
  waveform.clear
  delay(total_len*1000) if opts[:delay]
end
