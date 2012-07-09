# A simple paint program showing how to use the mouse.
RADIUS = 20
ALPHA = 4

while true
  x, y = mouse_position

  if mouse_buttons.member? 1
    color(255, 0, 0, ALPHA)
    circle(x, y, RADIUS, fill: true)
  end

  if mouse_buttons.member? 2
    color(0, 255, 0, ALPHA)
    circle(x, y, RADIUS, fill: true)
  end

  if mouse_buttons.member? 3
    color(0, 0, 255, ALPHA)
    circle(x, y, RADIUS, fill: true)
  end

  display
end
