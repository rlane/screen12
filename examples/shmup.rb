i = 0
while true
  clear
  i += 1
  x = 400 + 300*(Math.cos(i/60.0)/Math::PI)
  image_int(x, 300, 48, 140, 24, 28, 0xBF, 0xDC, 0xBF, "resources/sample.png")
  image_int(x, 400, 125, 154, 37, 28, 0xBF, 0xDC, 0xBF, "resources/sample.png")
  display
  keys
  delay 15
end
