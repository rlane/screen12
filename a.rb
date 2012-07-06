class PRNG
  def initialize seed=42
    @state = seed
  end

  def next
    @state = (16807*@state) % 2147483647
  end
end

prng = PRNG.new

50.times do
  color(prng.next%256, prng.next%256, prng.next%256, prng.next%256)
  line(prng.next%640, prng.next%480, prng.next%640, prng.next%480)
end
