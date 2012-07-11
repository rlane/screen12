PLAYER_SPEED = 8.0

$player = {
  x: 400,
  y: 500,
}

def handle_input
  if keys.member? 'left'
    $player[:x] -= PLAYER_SPEED
  end

  if keys.member? 'right'
    $player[:x] += PLAYER_SPEED
  end

  if keys.member? 'up'
    $player[:y] -= PLAYER_SPEED
  end

  if keys.member? 'down'
    $player[:y] += PLAYER_SPEED
  end
end

def draw_enemies
  x = 400 + 300*(Math.cos(Math::PI*time/4000.0))
  image('tyrian/enemy', x, 100)
end

def draw_player
  image('tyrian/player', $player[:x], $player[:y])
end

while true
  handle_input
  clear
  draw_enemies
  draw_player
  display
  delay 30
end
