local HC=require "lib.HC"
local anim8=require "lib.anim8"
local shape = require "shape"
local gui=require "lib.gui"

function createDoor(x,y,w,h,filename)
  local s=shape.createShape(x,y,w,h,0)
  s.color={
    light=gui.createColor255(0,255,255),
    medium=gui.createColor255(0,170,170),
    dark=gui.createColor255(0,85,85)
  }

  s.type="door"
  s.draw=drawDoor

  return s
end

function drawDoor1(self)
  local x,y=self.x,self.y
  local w,h=self.w,self.h
  local o=16
  if self.w<=32 or self.h<=32 then o=8 end

  love.graphics.setColor(self.color.medium:components())
  love.graphics.rectangle("fill",x,y,w,h)

  if self.w>self.h then
    -- door is horizontal
    love.graphics.setColor(self.color.light:components())
    love.graphics.rectangle("fill",self.x-offset,self.y+offset,self.w+offset*2,self.h-offset*2)

    local x,y=self.x,self.y
    local w,h=self.w,self.h
    love.graphics.polygon("fill",x,y, x+w+offset*2,y, s)
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

function drawDoor2(self)
  local x,y=self.x,self.y
  local w,h=self.w,self.h
  local o=16
  if self.w<=32 or self.h<=32 then o=8 end

  if self.w>self.h then
    -- door is horizontal
    -- base with angled sides
    love.graphics.setColor(self.color.medium:components())
    love.graphics.polygon("fill",x-o,y+o, x,y, x+w,y, x+w+o,y+o, x+w+o,y+h-o, x+w,y+h, x,y+h,x-o,y+h-o, x,y)
    -- top bar
    love.graphics.setColor(self.color.light:components())
    love.graphics.polygon("fill",x-o,y+o, x+w+o,y+o, x+w+o,y+h-o, x-o,y+h-o)
    --outline to make more distinctive
    love.graphics.setColor(self.color.dark:components())
    love.graphics.polygon("line",x-o,y+o, x,y, x+w,y, x+w+o,y+o, x+w+o,y+h-o, x+w,y+h, x,y+h,x-o,y+h-o)
    
  elseif self.h>self.w then
    -- door is verticle
    love.graphics.setColor(self.color.medium:components())
    love.graphics.polygon("fill",x,y, x+o,y-o, x+w-o,y-o, x+w,y, x+w,y+h, x+w-o,y+h+o, x+o,y+h+o, x,y+h, x,y)
    --top bar
    love.graphics.setColor(self.color.light:components())
    love.graphics.polygon("fill",x+o,y-o, x+w-o,y-o, x+w-o,y+h+o, x+o,y+h+o, x+o,y-o)
    --outline to make more distinctive
    love.graphics.setColor(self.color.dark:components())
    love.graphics.polygon("line",x,y, x+o,y-o, x+w-o,y-o, x+w,y, x+w,y+h, x+w-o,y+h+o, x+o,y+h+o, x,y+h, x,y, x+o,y-o)

  else
    -- door is square
    love.graphics.setColor(self.color.medium:components())
    love.graphics.rectangle("fill",self.x,self.y,self.w,self.h)
    love.graphics.setColor(self.color.light:components())
    love.graphics.rectangle("fill",self.x+o,self.y+o,self.w-o*2,self.h-o*2)
  end

end

function drawDoor(self)
  drawDoor2(self)
end

