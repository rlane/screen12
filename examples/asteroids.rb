# Incomplete asteroids clone

# constants
MAIN_ACC = 0.5
ANGULAR_ACC = -0.005
BULLET_SPEED = 5.0
BULLET_LIFETIME = 60

# player ship polygon
PLAYER_COORDS = [15, 0, # front
                 -5, 7, # back right
                 -5, -7] # back left

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
    bullet = { x: $player[:x], y: $player[:y], vx: bvx, vy: bvy, ttl: BULLET_LIFETIME }
    $bullets.push(bullet)
  end
end

def move_player
  $player[:vx] += $player[:main_acc] * Math.cos($player[:angle])
  $player[:vy] += $player[:main_acc] * Math.sin($player[:angle])
  $player[:angular_velocity] += $player[:angular_acc]
  $player[:angle] += $player[:angular_velocity]
  $player[:x] = ($player[:x] + $player[:vx]) % SCREEN_WIDTH
  $player[:y] = ($player[:y] + $player[:vy]) % SCREEN_HEIGHT
end

def move_bullets
  $bullets.each do |bullet|
    bullet[:x] = (bullet[:x] + bullet[:vx]) % SCREEN_WIDTH
    bullet[:y] = (bullet[:y] + bullet[:vy]) % SCREEN_HEIGHT
    bullet[:ttl] -= 1
  end

  # Clean up dead bullets
  $bullets = $bullets.reject { |bullet| bullet[:ttl] == 0 }
end

def clear_screen
  color(0, 0, 0, 255)
  box(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, fill: true)
end

def draw_player
  color(255, 255, 255, 100)
  polygon(PLAYER_COORDS, aa: true,
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
