local HC=require "lib.HC"
local anim8=require "lib.anim8"
local shape = require "shape"
local gui=require "lib.gui"

function createDoor(x,y,w,h,filename,color)
  local red={
    light=gui.createColor255(255,0,0),
    medium=gui.createColor255(170,0,0),
    dark=gui.createColor255(85,0,0)
  }
  local green={
    light=gui.createColor255(0,255,0),
    medium=gui.createColor255(0,170,0),
    dark=gui.createColor255(0,85,0)
  }
  local yellow={
    light=gui.createColor255(255,255,0),
    medium=gui.createColor255(170,170,0),
    dark=gui.createColor255(85,85,0)
  }
  local cyan={
    light=gui.createColor255(0,255,255),
    medium=gui.createColor255(0,170,170),
    dark=gui.createColor255(0,85,85)
  }

  local s=shape.createShape(x,y,w,h,0)
  s.type="door"
  s.draw=drawDoor
  s.color=nil

  if color==nil or color=="red" then 
    s.color=red
  elseif color=="green" then 
    s.color=green
  elseif color=="yellow" then 
    s.color=yellow
  end

  s.color=cyan  --override to test
  
  return s
end

function drawDoor(self)
  love.graphics.setColor(self.color.medium:components())
  love.graphics.rectangle("fill",self.x,self.y,self.w,self.h)
  local offset=16
  if self.w<=32 or self.h<=32 then offset=8 end

  if self.w>self.h then
    -- door is horizontal
    love.graphics.setColor(self.color.light:components())
    love.graphics.rectangle("fill",self.x-offset,self.y+offset,self.w+offset*2,self.h-offset*2)
  elseif self.h>self.w then
    -- door is verticle
    love.graphics.setColor(self.color.light:components())
    love.graphics.rectangle("fill",self.x+offset,self.y-offset,self.w-offset*2,self.h+offset*2)
  else
    -- door is square
    love.graphics.setColor(self.color.light:components())
    love.graphics.rectangle("fill",self.x+offset,self.y+offset,self.w-offset*2,self.h-offset*2)
  end

end
