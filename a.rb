prng = PRNG.new

50.times do
  10.times do
    color(prng.next%256, prng.next%256, prng.next%256, prng.next%256)
    line(prng.next%640, prng.next%480, prng.next%640, prng.next%480)
  end
  flip
  delay(100)
end
