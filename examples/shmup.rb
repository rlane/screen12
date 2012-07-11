tyrian1 = load_image("resources/tyrian1.png", 0xBF, 0xDC, 0xBF)
tyrian2 = load_image("resources/tyrian2.png", 0xBF, 0xDC, 0xBF)

i = 0
while true
  clear
  i += 1
  x = 400 + 300*(Math.cos(Math::PI*time/4000.0))
  blit(tyrian1, x, 400, 125, 154, 37, 28)
  blit(tyrian2, x, 100, 30, 2, 17, 25)
  display
  keys
  delay 30
end
