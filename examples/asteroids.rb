# Incomplete asteroids clone

# constants
MAIN_ACC = 0.5
ANGULAR_ACC = -0.005
BULLET_SPEED = 5.0

# create the player
$player = {
  x: SCREEN_WIDTH/2.0, y: SCREEN_HEIGHT/2.0, angle: 0.0,
  vx: 0.0, vy: 0.0, angular_velocity: 0.0,
  main_acc: 0.0, angular_acc: 0.0
}

$bullets = []

def handle_input
  $player[:main_acc] = 0.0
  $player[:angular_acc] = 0.0

  if keys.member?('up')
    $player[:main_acc] += MAIN_ACC
  end

  if keys.member?('down')
    $player[:main_acc] -= MAIN_ACC
  end

  if keys.member?('left')
    $player[:angular_acc] += ANGULAR_ACC
  end

  if keys.member?('right')
    $player[:angular_acc] -= ANGULAR_ACC
  end

  if keys.member?('space')
    angle = $player[:angle]
    bvx = $player[:vx] + BULLET_SPEED * Math.cos(angle)
    bvy = $player[:vy] + BULLET_SPEED * Math.sin(angle)
    bullet = { x: $player[:x], y: $player[:y], vx: bvx, vy: bvy }
    $bullets.push(bullet)
  end
end

def move_player
  $player[:vx] += $player[:main_acc] * Math.cos($player[:angle])
  $player[:vy] += $player[:main_acc] * Math.sin($player[:angle])
  $player[:angular_velocity] += $player[:angular_acc]
  $player[:angle] += $player[:angular_velocity]
  $player[:x] += $player[:vx]
  $player[:y] += $player[:vy]

  if $player[:x] > SCREEN_WIDTH
    $player[:x] -= SCREEN_WIDTH
  end

  if $player[:x] < 0
    $player[:x] += SCREEN_WIDTH
  end

  if $player[:y] > SCREEN_HEIGHT
    $player[:y] -= SCREEN_HEIGHT
  end

  if $player[:y] < 0
    $player[:y] += SCREEN_HEIGHT
  end
end

def move_bullets
  $bullets.each do |bullet|
    bullet[:x] += bullet[:vx]
    bullet[:y] += bullet[:vy]

    if bullet[:x] > SCREEN_WIDTH
      bullet[:x] -= SCREEN_WIDTH
    end

    if bullet[:x] < 0
      bullet[:x] += SCREEN_WIDTH
    end

    if bullet[:y] > SCREEN_HEIGHT
      bullet[:y] -= SCREEN_HEIGHT
    end

    if bullet[:y] < 0
      bullet[:y] += SCREEN_HEIGHT
    end
  end
end

def clear_screen
  color(0, 0, 0, 255)
  box(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, fill: true)
end

def draw_player
  color(255, 255, 255, 100)
  coords = [15, 0,
            -5, 7,
            -5, -7]
  polygon(coords, aa: true,
          position: [$player[:x], $player[:y]],
          rotation: $player[:angle])
end

def draw_bullets
  color(255, 255, 255, 200)
  $bullets.each do |bullet|
    line(bullet[:x], bullet[:y], bullet[:x], bullet[:y])
  end
end

while true
  handle_input
  move_player
  move_bullets
  clear_screen
  draw_player
  draw_bullets
  flip
  delay 15
end
