class PRNG
  def initialize seed=42
    @state = seed
  end

  def next
    @state = (16807*@state) % 2147483647
  end
end
