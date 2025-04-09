local shape=require "shape"
local anim8=require "lib.anim8"
local Monsters = require('monsters.monster_stats')
local MonstersData = {}
for key, value in pairs(Monsters) do
  MonstersData[key] = value
end

-- Weightings for Monsters
local Weightings = {basic=6,sense=4,basic_ranger=3,sense_ranger=2}
local MonsterList = {}
local generatorSheet=love.graphics.newImage("assets/generate-sheet-64x64-sheet.png")
-- local generatorSheet=love.graphics.newImage("assets/monster-gen1-sheet-128x128.png")

for key, value in pairs(Weightings) do
  for i = 1, value do
    MonsterList[#MonsterList+1] = MonstersData[key]()
  end
end

function createGenerator(world,x,y,w,h,spawnRate)
  w=64  -- TODO lee hacking size to test
  h=64
  local s=shape.createShape(x,y,w,h)
  s.sheet=generatorSheet
  s.world=world
  s.spawnRate=spawnRate
  s.timer=0
  s.counter=10
  s.update=updateGenerator
  s.draw=drawGenerator
  s.createHitbox=createGeneratorHitbox

  s.grid=anim8.newGrid(s.w,s.h,s.sheet:getWidth(),s.sheet:getHeight())
  s.anim=anim8.newAnimation(s.grid("1-15",1),0.07,function() s.anim:pause() s.anim:gotoFrame(1) end)
  s.anim:pause()
  s.anim:pauseAtEnd()
  s.anim:gotoFrame(1)
  s.paused=true
  return s
end

function updateGenerator(self,dt)
  self.anim:update(dt)
  if self.spawnRate>0 and self.counter>0 then
    if self.world:checkPositionVisible(self.x,self.y,self.world.players[1].x,self.world.players[1].y) then
      self.timer=self.timer-dt
      if self.timer<=0 then
        self.counter=self.counter-1
        self.timer=self.spawnRate

        -- Choose a random monster to spawn
        local monster = MonsterList[math.random(1, #MonsterList)]
        local monsterName=monster.name
        self.world:addMonster(createMonster(self.world,1,self.x,self.y,monsterName))
        self.anim:resume()
        self.anim:gotoFrame(1)
        self.paused=false
        playSfx(sfx.monsterGenerate)
      end
    end
  end
end

function drawGenerator(self)
  -- if not self.paused then
    love.graphics.setColor(1,1,1,1)
    self.anim:draw(self.sheet,self.x-self.w/2,self.y-self.h/2)
  -- end
end

function createGeneratorHitbox(self)
  -- no hitbox
end

