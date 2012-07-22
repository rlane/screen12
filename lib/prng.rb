# Random number generator
class PRNG
  MAX = 2147483647

  def initialize seed=nil
    @state = seed || $lib_prng.next/2
  end

  def next
    @state = (16807*@state) % MAX
  end

  def range low, high
    range = (high - low).to_f
    low + (self.next.to_f/MAX)*range
  end
end

$lib_prng = PRNG.new RANDOM_SEED

# Returns a random floating point number between low and high
def random low, high
  $lib_prng.range low, high
end
