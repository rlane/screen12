# Incomplete asteroids clone
# Use the arrow keys to move your ship and space to shoot its gun.

MAIN_ACC = 0.10
ANGULAR_ACC = -0.08
BULLET_SPEED = 5.0
BULLET_LIFETIME = 120
FIRE_TIME = 400
ASTEROID_MAX_SPEED = 0.9
ASTEROID_RADIUS = 20
NUM_ASTEROIDS = 4

# player ship polygon
PLAYER_COORDS = [15, 0, # front
                 -5, 7, # back right
                 -5, -7] # back left

# asteroid polygon
ASTEROID_COORDS = [30, 0, # middle right
                   25, 15, # top right
                   5, 20, # top middle
                   -10, 15, # top left
                   -17, 5, # middle left
                   -15, -10, # bottom left
                   7, -17] # bottom middle
                   

# create the player
$player = {
  x: SCREEN_WIDTH/2.0, y: SCREEN_HEIGHT/2.0, angle: 0.0,
  vx: 0.0, vy: 0.0, angular_velocity: 0.0,
  main_acc: 0.0, angular_acc: 0.0
}

$bullets = []
$asteroids = []

$score = 0
$last_fire_time = 0

def create_asteroids
  NUM_ASTEROIDS.times do
    asteroid = {
      x: random(0, SCREEN_HEIGHT), y: random(0, SCREEN_HEIGHT),
      vx: random(-ASTEROID_MAX_SPEED, ASTEROID_MAX_SPEED),
      vy: random(-ASTEROID_MAX_SPEED, ASTEROID_MAX_SPEED),
    }
    $asteroids.push(asteroid)
  end
end

def handle_input
  $player[:main_acc] = 0.0
  $player[:angular_acc] = 0.0

  if keys.member?('up')
    $player[:main_acc] += MAIN_ACC
  end

  if keys.member?('left')
    $player[:angular_acc] += ANGULAR_ACC
  end

  if keys.member?('right')
    $player[:angular_acc] -= ANGULAR_ACC
  end

  if (keys.member?('space') or keys.member?('down')) and
     ($last_fire_time + FIRE_TIME < time)
    angle = $player[:angle]
    bvx = $player[:vx] + BULLET_SPEED * cos(angle)
    bvy = $player[:vy] + BULLET_SPEED * sin(angle)
    bullet = { x: $player[:x], y: $player[:y], vx: bvx, vy: bvy, ttl: BULLET_LIFETIME }
    $bullets.push(bullet)
    sound("laser")
    $last_fire_time = time
  end
end

def move_player
  $player[:vx] += $player[:main_acc] * cos($player[:angle])
  $player[:vy] += $player[:main_acc] * sin($player[:angle])
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
  $bullets = $bullets.reject { |bullet| bullet[:ttl] <= 0 }
end

def move_asteroids
  $asteroids.each do |asteroid|
    asteroid[:x] = (asteroid[:x] + asteroid[:vx]) % SCREEN_WIDTH
    asteroid[:y] = (asteroid[:y] + asteroid[:vy]) % SCREEN_HEIGHT
  end
end

def collide
  $asteroids.each do |asteroid|
    $bullets.each do |bullet|
      if distance(asteroid[:x], asteroid[:y], bullet[:x], bullet[:y]) < ASTEROID_RADIUS
        bullet[:ttl] = 0
        $asteroids.delete asteroid
        sound("explosion#{random(1,3).round}")
        $score += 100
        break
      end
    end
  end
  
  if $asteroids.empty?
    create_asteroids
  end
end

def draw_score
  color(255, 255, 255, 255)
  text(SCREEN_WIDTH/2 - 10*8/2, 20, "score: #{$score}")
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
    point(bullet[:x], bullet[:y])
  end
end

def draw_asteroids
  color(255, 255, 255, 100)
  $asteroids.each do |asteroid|
    polygon(ASTEROID_COORDS, aa: true,
            position: [asteroid[:x], asteroid[:y]])
  end
end

create_asteroids
while true
  start_time = time
  handle_input
  move_player
  move_bullets
  move_asteroids
  collide
  clear
  draw_score
  draw_player
  draw_bullets
  draw_asteroids
  display
  delay(15 - (time - start_time))
end
