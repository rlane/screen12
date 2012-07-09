PADDLE_HEIGHT = 100
PADDLE_WIDTH = 20
PADDLE_SPEED = 5
INITIAL_BALL_SPEED = 5
BALL_RADIUS = 10
BALL_SPEEDUP = 1.1
BALL_DEFLECTION = 4.0

$player1_score = 0
$player2_score = 0

def reset_game
  $player1 = {
    x: 100,
    y: SCREEN_HEIGHT/2,
  }

  $player2 = {
    x: SCREEN_WIDTH-100,
    y: SCREEN_HEIGHT/2,
  }

  $ball = {
    x: SCREEN_WIDTH/2,
    y: SCREEN_HEIGHT/2,
    vx: INITIAL_BALL_SPEED,
    vy: 0,
  }
end

def handle_input
  if keys.member? 'w'
    $player1[:y] -= PADDLE_SPEED
  end

  if keys.member? 's'
    $player1[:y] += PADDLE_SPEED
  end

  if keys.member? 'up'
    $player2[:y] -= PADDLE_SPEED
  end

  if keys.member? 'down'
    $player2[:y] += PADDLE_SPEED
  end
end

def enforce_boundary
  [$player1, $player2].each do |player|
    miny = PADDLE_HEIGHT/2
    if player[:y] < miny
      player[:y] = miny
    end

    maxy = SCREEN_HEIGHT-PADDLE_HEIGHT/2
    if player[:y] > maxy
      player[:y] = maxy
    end
  end
end

def move_ball
  $ball[:x] += $ball[:vx]
  $ball[:y] += $ball[:vy]

  # Check if someone scored a goal.

  if $ball[:x] > SCREEN_WIDTH
    $player1_score += 1
    reset_game
  end

  if $ball[:x] < 0
    $player2_score += 1
    reset_game
  end

  # Bounce off the top and bottom of the screen.
  if $ball[:y] < 0 or $ball[:y] > SCREEN_HEIGHT
    $ball[:vy] = -$ball[:vy]
  end

  # Bounce off the paddles, speeding up when it does.
  [$player1, $player2].each do |player|
    if $ball[:x] > player[:x] - PADDLE_WIDTH/2 and
       $ball[:x] < player[:x] + PADDLE_WIDTH/2 and
       $ball[:y] > player[:y] - PADDLE_HEIGHT/2 - BALL_RADIUS/2 and
       $ball[:y] < player[:y] + PADDLE_HEIGHT/2 + BALL_RADIUS/2
       $ball[:vx] = -BALL_SPEEDUP*$ball[:vx]
       $ball[:vy] += BALL_DEFLECTION*($ball[:y] - player[:y])/PADDLE_HEIGHT
    end
  end

  # Prevent the ball from becoming so fast it skips over the paddle.

  if $ball[:vx] > PADDLE_WIDTH
    $ball[:vx] = PADDLE_WIDTH
  end

  if $ball[:vx] < -PADDLE_WIDTH
    $ball[:vx] = -PADDLE_WIDTH
  end
end

def draw_players
  [$player1, $player2].each do |player|
    color(100, 100, 200, 255)
    box(player[:x]-PADDLE_WIDTH/2, player[:y]-PADDLE_HEIGHT/2, player[:x]+PADDLE_WIDTH/2, player[:y]+PADDLE_HEIGHT/2, fill: true)
  end
end

def draw_ball
  color(200, 100, 100, 255)
  circle($ball[:x], $ball[:y], BALL_RADIUS, fill: true)
end

def draw_scores
  y = 20
  color(200, 200, 200, 255)
  text(1*SCREEN_WIDTH/4 - 8*11/2, y, "Player 1: #{$player1_score}")
  text(3*SCREEN_WIDTH/4 - 8*11/2, y, "Player 2: #{$player2_score}")
end

reset_game
while true
  handle_input
  enforce_boundary
  move_ball
  clear
  draw_players
  draw_ball
  draw_scores
  display
  delay(16)
end
