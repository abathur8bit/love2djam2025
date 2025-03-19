local shape=require "shape"
local anim8=require 'lib.anim8'
local gui=require "lib.gui"

behaviours={"dumb","smart"}
function createMonster(id,x,y,w,h,filename,world,behaviour)
  local s=shape.createShape(x,y,w,h,0,gui.createColor(1,1,1,1))
  s.type="monster"
  s.behaviour=behaviour
  s.world=world
  s.hitbox=world.collider:rectangle(x,y,w,h)
  s.id=id
  s.z=9 -- make sure it's under the player
  s.score=0
  s.health=INITIAL_PLAYER_HEALTH
  s.fireRate=0.2
  s.fireRateTimer=s.fireRate
  s.keyPressed=false
  s.speed=300
  s.animType="idle"
  s.direction="downright"
  s.update=updateMonster
  s.draw=drawMonster
  s.idleTimer=0.0
  s.idleTimerDelay=5
  s.sheet=love.graphics.newImage(filename)
  s.grid=anim8.newGrid(s.w,s.h,s.sheet:getWidth(),s.sheet:getHeight())
  s.animType="walk"
  s.direction="downright"
  s.keyPressed=false
  s.speed=300
  s.fireRate=0.2
  s.fireRateTimer=s.fireRate
  s.anims={}
  s.anims.idle={
    up        = anim8.newAnimation(s.grid(1,1),0.15),
    down      = anim8.newAnimation(s.grid(1,1),0.15),
    right     = anim8.newAnimation(s.grid(1,1),0.15),
    left      = anim8.newAnimation(s.grid(1,1),0.15),
    upleft    = anim8.newAnimation(s.grid(1,1),0.15),
    upright   = anim8.newAnimation(s.grid(1,1),0.15),
    downright = anim8.newAnimation(s.grid(1,1),0.15),
    downleft  = anim8.newAnimation(s.grid(1,1),0.15),
  }
  s.anims.walk={
    up        = anim8.newAnimation(s.grid('1-4',1),0.15),
    down      = anim8.newAnimation(s.grid('1-4',1),0.15),
    right     = anim8.newAnimation(s.grid('1-4',1),0.15),
    left      = anim8.newAnimation(s.grid('1-4',1),0.15),
    upleft    = anim8.newAnimation(s.grid('1-4',1),0.15),
    upright   = anim8.newAnimation(s.grid('1-4',1),0.15),
    downright = anim8.newAnimation(s.grid('1-4',1),0.15),
    downleft  = anim8.newAnimation(s.grid('1-4',1),0.15),
  }
  s.current=s.anims[s.animType][s.direction]

  return s
end

function updateMonster(self,dt)
  self.current=self.anims[self.animType][self.direction]  -- set the correct animation
  self.current:update(dt) -- update anim8
end

function drawMonster(self)
  self.current:draw(self.sheet,self.x,self.y,nil,self.scale,self.scale,self.w/2,self.h/2)
end

-- Check if a position is visible or not
function checkPositionVisible(self, x, y)

  -- -- Get monster position and convert to pathfinding position
  -- local mx, my = math.floor(self.x / 32), math.floor(self.y / 32)

  -- -- Get x/y and convert to pathfinding position
  -- local px, py = math.floor(x / 32), math.floor(y / 32)

  -- for x1
end