local shape=require "shape"

local monsters = {basic=6,sense=4,basic_ranger=3,sense_ranger=2}
local monster_weightings = 0
for key, value in pairs(monsters) do
  monster_weightings = monster_weightings + value
end

function createGenerator(world,x,y,w,h,spawnRate)
  local s=shape.createShape(x,y,w,h)
  s.world=world
  s.spawnRate=spawnRate
  s.timer=0
  s.counter=10
  s.update=updateGenerator
  s.draw=drawGenerator
  s.createHitbox=createGeneratorHitbox
  return s
end

function updateGenerator(self,dt)
  if self.spawnRate>0 and self.counter>0 then
    if self.world:checkPositionVisible(self.x,self.y,self.world.players[1].x,self.world.players[1].y) then
      self.timer=self.timer-dt
      if self.timer<=0 then
        self.counter=self.counter-1
        self.timer=self.spawnRate

        -- Choose a random monster to spawn
        local n = math.random(1, monster_weightings)
        

        self.world:addMonster(createMonster(self.world,1,self.x,self.y,64,64,"assets/helmet.png","monster","basic"))
      end
    end
  end
end

function drawGenerator()
  -- do nothing
end

function createGeneratorHitbox(self)
  -- no hitbox
end

