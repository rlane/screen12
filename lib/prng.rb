# Random number generator
class PRNG
  MAX = 2147483647

  def initialize seed=42
    @state = seed
  end

  def next
    @state = (16807*@state) % MAX
  end

  def range low, high
    range = (high - low).to_f
    low + (self.next.to_f/MAX)*range
  end
end

$lib_prng = PRNG.new 1

# Returns a random floating point number between low and high
def random low, high
  $lib_prng.range low, high
end
