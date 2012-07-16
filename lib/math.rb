# Todo benchmark some of these against C implementations
PI = Math::PI

def distance x1, y1, x2, y2
  Math.sqrt((x1 - x2)**2 + (y1 - y2)**2)
end

def deg2rad deg
  deg * 2*PI/360
end

def sin angle
  Math.sin(deg2rad(angle))
end

def cos angle
  Math.cos(deg2rad(angle))
end

def tan angle
  Math.tan(deg2rad(angle))
end
