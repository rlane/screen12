prng = PRNG.new

50.times do |i|
  10.times do
    color(prng.next%256, prng.next%256, prng.next%256, prng.next%256)
    line(prng.next%SCREEN_WIDTH, prng.next%SCREEN_HEIGHT, prng.next%SCREEN_WIDTH, prng.next%SCREEN_HEIGHT)
  end
  color(255, 0, 0, 255)
  circle(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, i*5)
  flip
  delay(30)
end
