tileset = load_image("resources/sample.png", 0xBF, 0xDC, 0xBF)

i = 0
while true
  clear
  i += 1
  x = 400 + 300*(Math.cos(Math::PI*time/4000.0))
  blit(tileset, 10, 10)
  blit(tileset, x, 300, 48, 140, 24, 28)
  blit(tileset, x, 400, 125, 154, 37, 28)
  display
  keys
  delay 30
end
