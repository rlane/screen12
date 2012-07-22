# Basic Scorched Earth clone.
# Copyright (C) 2012 Rich Lane
# This code is released under the BSD two-clause license.
#
# Use the arrow keys to adjust the angle and power of the tank gun. Hit
# space to fire. The last tank alive wins!
#
# TODO Collide bullets directly with players.
# TODO Fall damage.

NUM_PLAYERS = 3
G = 0.1 # Acceleration due to gravity (pixels/frame).
MAX_POWER = 300
STATUS_SCREEN_HEIGHT = 75
MAX_WIND = 2
BULLET_DRAG = 0.002

def setup
  $ticks = 0
  $last_fire_tick = 0
  setup_terrain()
  setup_players()
  setup_bullets()
  setup_explosions()
  setup_wind()
end

# Generate terrain using the midpoint displacement algorithm.
def setup_terrain
  # Tunables.
  initial_height = SCREEN_HEIGHT-200
  max_displacement = 100
  displacement_growth = 0.92
  iterations = 1000

  # x0 and width must be integers.
  lines = [ { x0: 0, width: 400, slope: -0.2 }, { x0: 400, width: 400, slope: 0.2 } ]

  # For each iteration, pick a random line and split it in two. Move the
  # middle point up or down by a random amount. The maximum amount it can
  # be moved decreases with each iteration.
  y0 = initial_height
  iterations.times do
    j = random(0, lines.length).to_i
    lA = lines[j]
    y1 = y0 + lA[:width]*lA[:slope]
    widthA = (lA[:width]/2).ceil
    widthB = (lA[:width]/2).floor
    if widthB == 0 then
      # skip
    else
      midy = y0+lA[:width]*lA[:slope]/2
      dy = random(-max_displacement, max_displacement)
      # y = y0 + slope*x
      # slope = (y-y0)/x
      slopeA = (midy+dy-y0)/widthA
      slopeB = (y1-midy-dy)/widthB
      lB = { x0: lA[:x0]+widthA, width: widthB, slope: slopeB }
      lines.push(lB)
      lA[:width] = widthA
      lA[:slope] = slopeA
      max_displacement = max_displacement * displacement_growth
    end
    y0 = y1
  end

  # Sort the lines by x0.
  lines = lines.sort { |a,b| a[:x0] <=> b[:x0] }

  # Build the terrain height-map from the lines.
  $terrain = {}
  y0 = initial_height
  lines.each do |l|
    ((l[:x0])...(l[:x0]+l[:width])).each do |x|
      $terrain[x] = y0 + (x-l[:x0])*l[:slope]
    end
    y0 = y0 + l[:width]*l[:slope]
  end
end

def setup_players
  $players = {}
  $live_players = NUM_PLAYERS
  NUM_PLAYERS.times do |i|
    x = random(10, SCREEN_WIDTH-10).to_i
    player = {
      x: x,
      y: $terrain[x],
      angle: 90,
      power: 100,
      health: 100,
      r: 255,
      g: 0,
      b: 0,
    }
    ((player[:x] - 8)..(player[:x] + 8)).each do |x|
      if $terrain[x] >= player[:y] then
        $terrain[x] = player[:y]-1
      end
    end
    $players[i] = player
  end
  $current_player_index = 0
  $current_player = $players[0]
end

# Pick a new non-dead player
def next_player
  if $live_players == 0 then return end
  $current_player_index = ($current_player_index + 1) % NUM_PLAYERS
  $current_player = $players[$current_player_index]
  if $current_player_index == nil or $current_player[:health] == 0 then
    return next_player()
  end
end

# Choose a color representing the player's status (current, dead, alive)
def player_status_color(player)
  if player == $current_player then
    color(220, 220, 220, 255)
  elsif player[:health] == 0 then
    color(100, 0, 0, 255)
  else
    color(127, 127, 127, 255)
  end
end

def setup_bullets
  $bullets = []
end

def setup_explosions
  $explosions = []
end

def setup_wind
  $wind = random(-MAX_WIND, MAX_WIND)
end

# If there is only one live player left return its index. Otherwise return nil.
def find_victor
  winner_index = nil
  $players.each do |i,player|
    if player[:health] > 0 then
      if winner_index then
        return nil
      else
        winner_index = i
      end
    end
  end
  return winner_index
end

def draw
  draw_sky()
  draw_terrain()
  draw_players()
  draw_bullets()
  draw_explosions()
  draw_status()
  draw_wind()
end

def handle_input
  ks = keys

  if ks.member?('left') then
    $current_player[:angle] = $current_player[:angle] + 1
  end
  if ks.member?('right') then
    $current_player[:angle] = $current_player[:angle] - 1
  end
  if ks.member?('up') and $current_player[:power] < MAX_POWER then
    $current_player[:power] = $current_player[:power] + 1
  end
  if ks.member?('down') and $current_player[:power] > 0 then
    $current_player[:power] = $current_player[:power] - 1
  end
  if ks.member?('space') and
     $bullets.size == 0 and
     $last_fire_tick < $ticks - 16 then
    fire()
    $last_fire_tick = $ticks
  end
  if ks.member?('return') and
     $bullets.size == 0 and
     $last_fire_tick < $ticks - 16 then
    fire_secret()
    $last_fire_tick = $ticks
  end
end

def fire
  player = $current_player
  speed = player[:power]/10
  bullet = {
    player: player,
    x: player[:x],
    y: player[:y],
    vx: cos(player[:angle])*speed,
    vy: -sin(player[:angle])*speed,
    exp_radius: 30,
    exp_damage: 100,
  }
  $bullets.push(bullet)
end

def fire_secret
  player = $current_player
  speed = player[:power]/10
  10.times do
    a = player[:angle] + random(-3, 3)
    bullet = {
      player: player,
      x: player[:x],
      y: player[:y],
      vx: cos(a)*speed,
      vy: -sin(a)*speed,
      exp_radius: 10,
      exp_damage: 40,
    }
    $bullets.push(bullet)
  end
end

# Drag increases with the square of the difference in velocity between
# the object and the air. Returns the acceleration due to drag.
def bullet_drag(v)
  a = v**2 * BULLET_DRAG
  if v > 0 then a = -a end # Oppose velocity.
  return a
end

# Do bullet physics and check for collisions with terrain or the sides of the screen.
def tick_bullets
  collided = false

  $bullets.each do |bullet|
    bullet[:x] = bullet[:x] + bullet[:vx]
    bullet[:y] = bullet[:y] + bullet[:vy]
    bullet[:vx] = bullet[:vx] + bullet_drag(bullet[:vx]-$wind)
    bullet[:vy] = bullet[:vy] + bullet_drag(bullet[:vy]) + G
    ix = bullet[:x].round
    if ix < 0 or ix >= SCREEN_WIDTH then
      bullet[:dead] = true
      collided = true
    elsif bullet[:y] > $terrain[ix] then
      bullet[:y] = $terrain[ix]
      $explosions.push({ x: bullet[:x], y: bullet[:y], r: bullet[:exp_radius], ttl: 20, lifetime: 20 })
      damage_players(bullet[:x], bullet[:y], bullet[:exp_radius], bullet[:exp_damage])
      deform_terrain(ix, bullet[:y], bullet[:exp_radius])
      bullet[:dead] = true
      collided = true
    end
  end

  $bullets = $bullets.select { |bullet| !bullet[:dead] }

  if collided
    after_bullet_collision()
  end
end

# Find the players in the damage radius of an explosion and reduce their health.
def damage_players(x, y, r, s)
  $players.each do |i,player|
    #p [:damage_players, i, player]
    d = distance(x, y, player[:x], player[:y])
    if player[:health] > 0 and d < r then
      # Damage attenuates linearly with distance (in 2d).
      e = s*(1-(d/r))
      player[:health] = [player[:health] - e, 0].max
      if player[:health] == 0 then
        $live_players = $live_players - 1
      end
    end
  end
end

# Remove a circular chunk of terrain.
def deform_terrain(x, y, r)
  (([x-r,0].max)..([x+r,SCREEN_WIDTH-1].min)).each do |x2|
    dx = x2 - x
    dy = Math.sqrt(r*r - dx*dx)
    ty = $terrain[x2]
    missing = ty + dy - y
    missing = [missing, 0].max
    missing = [missing, 2*dy].min
    $terrain[x2] = ty + (2*dy - missing)
  end

  # Drop players
  $players.each do |i,player|
    ty = $terrain[player[:x].floor]
    if player[:y] < ty-1 then
      player[:y] = ty-1
    end
  end
end

# If all the bullets have collided switch to the next player.
def after_bullet_collision
  if $bullets.size == 0
    next_player()
  end
end

def draw_sky
  top = STATUS_SCREEN_HEIGHT+1
  alpha = $bullets.size > 0 ? 127 : 255
  (top..SCREEN_HEIGHT).each do |i|
    f = i.to_f/(SCREEN_HEIGHT-top)
    color(30*f, 30*f, 200*f, alpha)
    line(0, i, SCREEN_WIDTH-1, i)
  end
end

def draw_terrain
  (0...SCREEN_WIDTH).each do |i|
    h = $terrain[i]

    # Draw a vertical line from the bottom
    color(36, 142, 36, 255)
    line(i, SCREEN_HEIGHT, i, h.ceil)

    # Antialias by drawing a point with transparency equal to the
    # fraction of a pixel that was ignored above.
    frac = h-h.ceil
    if frac > 0 then
      color(36, 142, 36, frac*255)
      box(i, h.ceil, 1, 1)
    end
  end
end

def draw_players
  $players.each do |i,player|
    color(player[:r], player[:g], player[:b], 255)
    box(player[:x]-6, player[:y], player[:x]+6, player[:y]-8, fill: true)
    l = 13
    line(player[:x], player[:y]-6,
       player[:x] + l*cos(player[:angle]),
       player[:y]-6 - l*sin(player[:angle]))
    player_status_color(player)
    text(player[:x]-5, player[:y]+6, i.to_s)
  end
end

def draw_bullets
  top = STATUS_SCREEN_HEIGHT
  $bullets.each do |bullet|
    if bullet[:y] > top
      color(200, 200, 200, 255)
      box(bullet[:x]-1, bullet[:y]-1, bullet[:x]+1, bullet[:y]+1, fill: true)
    else
      color(200, 200, 200, 255)
      l = 5
      line(bullet[:x]-l, top+l, bullet[:x], top)
      line(bullet[:x]+l, top+l, bullet[:x], top)
    end
  end
end

def draw_explosions
  $explosions.each do |exp|
    color(251, 130, 48, 255)
    r = exp[:r] * exp[:ttl]/exp[:lifetime]
    circle(exp[:x], exp[:y], r, fill: true)
    exp[:ttl] = exp[:ttl] - 1
  end
  $explosions = $explosions.select { |exp| exp[:ttl] > 0 }
end

def draw_status
  color(0, 0, 0, 255)
  box(0, 0, SCREEN_WIDTH-1, STATUS_SCREEN_HEIGHT-1, fill: true)
  color(150, 150, 150, 255)
  line(0, STATUS_SCREEN_HEIGHT, SCREEN_WIDTH-1, STATUS_SCREEN_HEIGHT)
  x = 5
  padding = 40
  $players.each do |i,player|
    player_status_color(player)
    y = 5
    dy = 17
    text(x, y+0*dy, "player #{i}")
    text(x, y+1*dy, "health: #{player[:health].to_i}")
    text(x, y+2*dy, "angle: #{player[:angle].to_i}")
    text(x, y+3*dy, "power: #{player[:power].to_i}")
    x = x + 15*10 + padding
    color(150, 150, 150, 255)
    line(x-padding/2, 0, x-padding/2, STATUS_SCREEN_HEIGHT)
  end
end

def draw_wind
  color(79, 64, 19, 255)
  scale = 100
  cx = SCREEN_WIDTH/2
  wx = cx + $wind*scale/MAX_WIND
  wy = SCREEN_HEIGHT-30
  text(cx-20, wy-20, "wind")
  line(cx, wy+3, cx, wy-3)
  dir = $wind > 0 ? 1 : -1
  wsx = cx+scale*dir
  line(wsx, wy+3, wsx, wy-3)
  line(cx, wy, wx, wy)
  line(wx, wy, wx-3*dir, wy-3)
  line(wx, wy, wx-3*dir, wy+3)
end

setup
while true
  $ticks = $ticks + 1
  game_over = $live_players <= 1
  if not game_over then
    handle_input()
    tick_bullets()
  end
    
  draw

  if game_over then
    keys
    color(230, 230, 230, 255)
    if $live_players == 1 then
      winning_player_index = find_victor()
      str = "Player #{winning_player_index} wins!"
      text(SCREEN_WIDTH/2-str.length*5, SCREEN_HEIGHT/2, str)
    else
      text(SCREEN_WIDTH/2-5*5, SCREEN_HEIGHT/2, "Draw!")
    end
  end

  if $ticks < 30*3 then
    centerText = lambda { |y, str| text(SCREEN_WIDTH/2-str.length*5, y, str) }
    color(200, 200, 200, 255-255*$ticks/90.0)
    centerText[460, "Use the arrow keys to control your tank's gun."]
    centerText[445, "Press the space key to fire."]
  end

  display
  delay(30)
end
