local shape=require "shape"

function createGenerator(world,x,y,w,h,spawnRate)
  local s=shape.createShape(x,y,w,h)
  s.world=world
  s.spawnRate=spawnRate
  s.timer=spawnRate
  s.update=updateGenerator
  s.draw=drawGenerator
  s.createHitbox=createGeneratorHitbox
  return s
end

function updateGenerator(self,dt)
  if self.spawnRate>0 then
    self.timer=self.timer-dt
    if self.timer<=0 then
      self.timer=self.spawnRate
      self.world:addMonster(createMonster(self.world,1,self.x,self.y,64,64,"assets/helmet.png","monster","basic"))
    end
  end
end

function drawGenerator()
  -- do nothing
end

function createGeneratorHitbox(self)
  -- no hitbox
end

