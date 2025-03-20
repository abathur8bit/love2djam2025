local anim8=require 'lib.anim8'
local shape=require "shape"
local gui=require "lib.gui"
local flux=require "lib.flux"

powerupType={"earth","fire","water"}

function createPowerup(world,powerupType,x,y,w,h)
  local s=shape.createShape(x,y,16,16,0,gui.createColor(1,1,1,1))
  s.type="powerup"
  s.hitbox=world:createHitbox(x,y,w,h,s.type,powerupType,powerupType,s)
  s.z=9 -- put
  s.scaleMin=4
  s.scaleMax=6
  s.scaleDir=1
  s.scale=math.random(s.scaleMin,s.scaleMax)
  s.powerupType=powerupType
  s.update=updatePowerup
  s.draw=drawPowerup
  s.speed=8
  s.sheet=love.graphics.newImage("assets/rotatingCoffeeBean-Sheet.png")
  assert(s,"powerup image not available")
  s.grid=anim8.newGrid(s.w,s.h,s.sheet:getWidth(),s.sheet:getHeight())
  s.anim=anim8.newAnimation(s.grid("1-8",1),0.15)
  s.anim:gotoFrame(math.random(4))  -- select a random frame so all powerups are not rotating in sync
  return s
end

function drawPowerup(self)
  love.graphics.setColor(self.color:components())
  self.anim:draw(self.sheet,self.x,self.y,nil,self.scale,self.scale,self.w/2,self.h/2)
end

function updatePowerup(self,dt)
  self.anim:update(dt)
  self.scale=self.scale+self.speed*self.scaleDir*dt
  if self.scale>self.scaleMax or self.scale<self.scaleMin then
    self.scaleDir=self.scaleDir*-1  -- reverse scale direction
  end
end