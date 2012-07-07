prng = PRNG.new

50.times do |i|
  10.times do
    color(prng.next%256, prng.next%256, prng.next%256, prng.next%256)
    line(prng.next%SCREEN_WIDTH, prng.next%SCREEN_HEIGHT, prng.next%SCREEN_WIDTH, prng.next%SCREEN_HEIGHT)
  end
  color(255, 0, 0, 255)
  circle(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, i*5)
  color(255, 0, 100, 255)
  circle(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, i*3, fill: true)
  color(255, 255, 0, 100)
  box(i*10, 40, i*10 + 50, 90)
  box(i*10, 100, i*10 + 50, 150, fill: true)
  flip
  delay(30)
end
