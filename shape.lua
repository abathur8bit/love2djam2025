local gui=require "lib.gui"
local shape={}
INITIAL_PLAYER_HEALTH=1000

-- Defaults to z=10 and vx,vy=0
function shape.createShape(x,y,w,h,angle,color)
  s={}
  s.x=x
  s.y=y
  s.z=10
  s.w=w
  s.h=h
  s.angle=angle
  s.vx=0
  s.vy=0
  s.color=color
  s.scale=1
  s.update=function() print("update shape") end
  s.draw=function() print("draw shape") end
  return s
end

return shape