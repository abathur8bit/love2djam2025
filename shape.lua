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
  s.update=function() end
  s.draw=function() end
  s.adjustRect=shape.adjustRect
  s.createHitbox=function() end
  return s
end


-- Returns a x,y,w,h of the shapes rectangle shrunk by x,y on the left, right, top and bottom
function shape.adjustRect(self,x,y)
  return self.x+x,self.y+y,self.w-x,self.h-y
end

return shape