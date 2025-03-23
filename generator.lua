local shape=require "shape"

function createGenerator(world,x,y,w,h,spawnSpeed)
  local s=shape.createShape(x,y,w,h)
  s.world=world
  s.spawnSpeed=spawnSpeed
  s.timer=spawnSpeed
  s.update=updateGenerator
  s.draw=drawGenerator
  s.createHitbox=createGeneratorHitbox
  return s
end

function updateGenerator(self,dt)
  --[[
  if 
  ]]
end

function drawGenerator()
  -- do nothing
end

function createGeneratorHitbox(self)
  -- no hitbox
end

