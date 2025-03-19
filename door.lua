local HC=require "lib.HC"
local anim8=require "lib.anim8"
local shape = require "shape"
local gui=require "lib.gui"

function createDoor(x,y,w,h,filename)
  local s=shape.createShape(x,y,w,h,0)
  s.type="door"
  s.image=love.graphics.newImage(filename)
  s.draw=drawDoor
  s.color={
    light=gui.createColor255(255,0,0),
    medium=gui.createColor255(170,0,0),
    dark=gui.createColor255(85,0,0)
  }

  return s
end

function drawDoor(self)
  -- love.graphics.draw(self.image,self.x,self.y,self.angle,self.scale,self.scale)
  love.graphics.setColor(self.color.medium:components())
  love.graphics.rectangle("fill",self.x,self.y,self.w,self.h)
  if self.w>self.h then
    -- door is horizontal
    local offset=16
    love.graphics.setColor(self.color.light:components())
    love.graphics.rectangle("fill",self.x-offset,self.y+offset,self.w+offset*2,self.h-offset*2)
  elseif self.h>self.w then
    -- door is verticle
    local offset=16
    love.graphics.setColor(self.color.light:components())
    love.graphics.rectangle("fill",self.x+offset,self.y-offset,self.w-offset*2,self.h+offset*2)
  else
    -- door is square
  end

end
