i = 0
while true
  clear
  i += 1
  x = 400 + 300*(Math.cos(Math::PI*time/4000.0))
  image('tyrian/player', x, 400)
  image('tyrian/enemy', x, 100)
  display
  keys
  delay 30
end
