PLAYER_RADIUS = 15
PLAYER_SPEED = 8.0
PLAYER_BULLET_SPEED = 14
PLAYER_FIRE_TIME = 100
ENEMY_RADIUS = 12
ENEMY_FIRE_CHANCE = 0.5
ENEMY_BULLET_SPEED = 2

$score = 0
$last_fire_time = 0

$player = {
  x: 400,
  y: 500,
}

$enemies = []
$bullets = []

def create_enemy
  enemy = {
    x: random(100, SCREEN_WIDTH-100),
    y: -30.0,
    vx: 0.0,
    vy: random(1.0, 3.0),
    health: 1,
  }
  $enemies.push(enemy)
end

def randomly_create_enemies
  rate = [10.0 + ([$score,0.0].max/5000.0)**2, 80.0].min
  if random(0, 100) < rate
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

  if keys.member? 'space' and ($last_fire_time + PLAYER_FIRE_TIME < time)
    bullet = {
      x: $player[:x],
      y: $player[:y],
      vx: 0.0,
      vy: -PLAYER_BULLET_SPEED,
      dead: false,
      enemy: false,
    }
    $bullets.push(bullet)
    $last_fire_time = time
    sound("laser2")
  end
end

def move_enemies
  $enemies.each do |enemy|
    enemy[:x] += enemy[:vx]
    enemy[:y] += enemy[:vy]
    if random(0, 100) < ENEMY_FIRE_CHANCE
      $bullets << {
        x: enemy[:x],
        y: enemy[:y],
        vx: 0.0,
        vy: enemy[:vy] + ENEMY_BULLET_SPEED,
        dead: false,
        enemy: true,
      }
      sound("laser")
    end
  end
  $score -= 50 * $enemies.select { |enemy| enemy[:y] > SCREEN_HEIGHT }.size
  $enemies = $enemies.select { |enemy| enemy[:y] < SCREEN_HEIGHT }
end

def move_bullets
  $bullets.each do |bullet|
    bullet[:x] += bullet[:vx]
    bullet[:y] += bullet[:vy]
  end
  $bullets = $bullets.select { |bullet| bullet[:y] > 0 && bullet[:y] < SCREEN_HEIGHT }
end

def check_collisions
  $bullets.each do |bullet|
    if bullet[:enemy]
      if distance($player[:x], $player[:y], bullet[:x], bullet[:y]) < PLAYER_RADIUS
        $score -= 1000
        sound("hurt1")
        bullet[:dead] = true
        break
      end
    else
      $enemies.each do |enemy|
        if distance(enemy[:x], enemy[:y], bullet[:x], bullet[:y]) < ENEMY_RADIUS
          enemy[:health] -= 1
          if enemy[:health] == 0
            $score += 100
            sound("explosion#{random(1,3).round}")
          end
          bullet[:dead] = true
          break
        end
      end
    end
  end
  $enemies = $enemies.select { |enemy| enemy[:health] > 0 }
  $bullets = $bullets.select { |bullet| bullet[:dead] == false }
end

def draw_enemies
  $enemies.each do |enemy|
    image('tyrian/enemy', enemy[:x]-7, enemy[:y]-12)
  end
end

def draw_bullets
  $bullets.each do |bullet|
    if bullet[:enemy]
      image('tyrian/bullet2', bullet[:x], bullet[:y])
    else
      image('tyrian/bullet', bullet[:x], bullet[:y])
    end
  end
end

def draw_player
  image('tyrian/player', $player[:x]-18, $player[:y]-14)
end

def draw_score
  text(30, 570, "SCORE: #{$score}")
end

while true
  handle_input
  randomly_create_enemies
  move_enemies
  move_bullets
  check_collisions
  clear
  draw_enemies
  draw_bullets
  draw_player
  draw_score
  display
  delay 30
end
