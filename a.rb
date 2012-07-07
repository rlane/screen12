prng = PRNG.new

50.times do
  10.times do
    color(prng.next%256, prng.next%256, prng.next%256, prng.next%256)
    line(prng.next%SCREEN_WIDTH, prng.next%SCREEN_HEIGHT, prng.next%SCREEN_WIDTH, prng.next%SCREEN_HEIGHT)
  end
  flip
  delay(100)
end
