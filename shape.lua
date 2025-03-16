local gui=require "lib.gui"
local shape={}
INITIAL_PLAYER_HEALTH=1000
function shape.createShape(x,y,w,h,scale,color)
  s={}
  s.x=x
  s.y=y
  s.w=w
  s.h=h
  s.color=color
  s.scale=scale
  s.update=function() print("update shape") end
  s.draw=function() print("draw shape") end
  return s
end

function shape.createPlayer(id,x,y,w,h,scale) 
  s=shape.createShape(x,y,w,h,scale,gui.createColor(1,1,1,1))
  s.id=id
  s.score=0
  s.health=INITIAL_PLAYER_HEALTH
  s.fireRate=0.2
  s.fireRateTimer=s.fireRate
  s.keyPressed=false
  s.speed=300
  s.animType="idle"
  s.direction="downright"
  s.update=shape.updatePlayer
  s.draw=shape.drawPlayer
  return s
end

function shape.updatePlayer(self,dt)
  print("update player",self.id)
end

function shape.drawPlayer(self)
  print("draw player ",self.id)
end

return shape