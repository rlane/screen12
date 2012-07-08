# Incomplete asteroids clone

# constants
MAIN_ACC = 1.0
ANGULAR_ACC = -0.01

# player variables
$x = SCREEN_WIDTH/2.0
$y = SCREEN_HEIGHT/2.0
$angle = 0.0
$vx = 0.0
$vy = 0.0
$angular_velocity = 0.0
$main_acc = 0.0
$angular_acc = 0.0

def handle_input
  $main_acc = 0.0
  $angular_acc = 0.0

  if keys.member?('up')
    $main_acc += MAIN_ACC
  end

  if keys.member?('down')
    $main_acc -= MAIN_ACC
  end

  if keys.member?('left')
    $angular_acc += ANGULAR_ACC
  end

  if keys.member?('right')
    $angular_acc -= ANGULAR_ACC
  end
end

def move_player
  $vx += $main_acc * Math.cos($angle)
  $vy += $main_acc * Math.sin($angle)
  $angular_velocity += $angular_acc
  $angle += $angular_velocity
  $x += $vx
  $y += $vy

  if $x > SCREEN_WIDTH
    $x -= SCREEN_WIDTH
  end

  if $x < 0
    $x += SCREEN_WIDTH
  end

  if $y > SCREEN_HEIGHT
    $y -= SCREEN_HEIGHT
  end

  if $y < 0
    $y += SCREEN_HEIGHT
  end
end

def clear_screen
  color(0, 0, 0, 255)
  box(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, fill: true)
end

def draw_player
  color(255, 255, 255, 100)
  r = 20
  da = 2.4
  x1 = $x + r*Math.cos($angle)
  y1 = $y + r*Math.sin($angle)
  x2 = $x + r*Math.cos($angle+da)
  y2 = $y + r*Math.sin($angle+da)
  x3 = $x + r*Math.cos($angle-da)
  y3 = $y + r*Math.sin($angle-da)
  line(x1, y1, x2, y2, aa: true)
  line(x2, y2, x3, y3, aa: true)
  line(x3, y3, x1, y1, aa: true)
  flip
end

while true
  handle_input
  move_player
  clear_screen
  draw_player
  delay 30
end
