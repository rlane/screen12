PLAYER_SPEED = 8.0

$player = {
  x: 400,
  y: 500,
}

$enemies = []

def create_enemy
  enemy = {
    x: random(100, SCREEN_WIDTH-100),
    y: -30.0,
    vx: 0.0,
    vy: random(1.0, 3.0)
  }
  $enemies.push(enemy)
end

def randomly_create_enemies
  if random(0, 1000) > 970
    create_enemy
  end
end

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

def move_enemies
  $enemies.each do |enemy|
    enemy[:x] += enemy[:vx]
    enemy[:y] += enemy[:vy]
  end
  $enemies = $enemies.select { |enemy| enemy[:y] < SCREEN_HEIGHT }
end

def draw_enemies
  $enemies.each do |enemy|
    image('tyrian/enemy', enemy[:x], enemy[:y])
  end
end

def draw_player
  image('tyrian/player', $player[:x], $player[:y])
end

while true
  handle_input
  randomly_create_enemies
  move_enemies
  clear
  draw_enemies
  draw_player
  display
  delay 30
end
