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

def sin angle
  Math.sin(angle)
end

def cos angle
  Math.cos(angle)
end

def tan angle
  Math.tan(angle)
end
