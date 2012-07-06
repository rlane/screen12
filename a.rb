class PRNG
  def initialize seed=42
    @state = seed
  end

  def next
    @state = (16807*@state) % 2147483647
  end
end

prng = PRNG.new

while true do
  line(0, 0, 640, 480)
  line(prng.next%640, prng.next%480, prng.next%640, prng.next%480)
end
