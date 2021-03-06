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
