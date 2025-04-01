local shape=require "shape"
local gui=require "lib.gui"
local anim8=require "lib.anim8"


function createWorm(world,shooter,x,y,angle,color)
  local s=shape.createShape(x,y,16,16,angle,color)
  s.world=world
  s.type="worm"
  s.update=updateWorm
  s.draw=drawWorm
  s.sheet=love.graphics.newImage("assets/walker-16x16.png")
  s.grid=anim8.newGrid(s.w,s.h,s.sheet:getWidth(),s.sheet:getHeight())
  s.anims={}
  s.anims.walk=anim8.newAnimation(s.grid("1-10",2),0.1)
  s.currentAnim=s.anims.walk
  s.scale=3
  return s
end

function drawWorm(self)
  love.graphics.setColor(self.color:components())
  self.currentAnim:draw(self.sheet,self.x,self.y,nil,self.scale,self.scale,self.w*self.scale/2,self.h*self.scale/2)
end

function updateWorm(self,dt)
  self.currentAnim:update(dt)
end