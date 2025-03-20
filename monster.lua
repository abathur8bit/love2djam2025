local shape=require "shape"
local anim8=require 'lib.anim8'
local gui=require "lib.gui"
local math = math

behaviours={"dumb","smart"}
function createMonster(world,id,x,y,w,h,filename,name,behaviour)
  local s=shape.createShape(x,y,w,h,0,gui.createColor(1,1,1,1))
  s.type="monster"
  s.name=name
  s.behaviour=behaviour
  s.world=world
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
  s.getPath=getPath
  s.checkPositionVisible=checkPositionVisible
  s.destroy=destroy
  s.followPath=followPath
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
  s.targetAttack=nil
  s.targetMove=nil
  s.hitbox=world:createHitbox(x,y,w,h,s.type,s.id,s.name,s)
  s.anims={
    idle={
      up        = anim8.newAnimation(s.grid(1,1),0.15),
      down      = anim8.newAnimation(s.grid(1,1),0.15),
      right     = anim8.newAnimation(s.grid(1,1),0.15),
      left      = anim8.newAnimation(s.grid(1,1),0.15),
      upleft    = anim8.newAnimation(s.grid(1,1),0.15),
      upright   = anim8.newAnimation(s.grid(1,1),0.15),
      downright = anim8.newAnimation(s.grid(1,1),0.15),
      downleft  = anim8.newAnimation(s.grid(1,1),0.15),
    },
    walk={
      up        = anim8.newAnimation(s.grid('1-4',1),0.15),
      down      = anim8.newAnimation(s.grid('1-4',1),0.15),
      right     = anim8.newAnimation(s.grid('1-4',1),0.15),
      left      = anim8.newAnimation(s.grid('1-4',1),0.15),
      upleft    = anim8.newAnimation(s.grid('1-4',1),0.15),
      upright   = anim8.newAnimation(s.grid('1-4',1),0.15),
      downright = anim8.newAnimation(s.grid('1-4',1),0.15),
      downleft  = anim8.newAnimation(s.grid('1-4',1),0.15),
    },
  }
  s.current=s.anims[s.animType][s.direction]
  return s
end

-- Update function
function updateMonster(self,dt)
  local ts = self.world.tileSize

  -- Check players to see if it can see one
  for key, player in pairs(self.world.players) do
    if self.world:checkPositionVisible(self.x, self.y, player.x, player.y) then
      
      -- Set new movement target for the player
      self.targetMove = {{x = math.floor(player.x/ts), y = math.floor(player.y/ts)}}
      goto continue
    end
  end
  ::continue::

  -- If it doesn't have a target to move it, get a new target to move to
  if not self.targetMove then
    
  end

  -- Follow path
  if self.targetMove then
    self:followPath(dt)
  end

  -- Animations
  self.current=self.anims[self.animType][self.direction]  -- set the correct animation
  self.current:update(dt) -- update anim8
end

function drawMonster(self)
  self.current:draw(self.sheet,self.x,self.y,nil,self.scale,self.scale,self.w/2,self.h/2)
end

-- Follow node path
function followPath(self, dt)
  local ts = self.world.tileSize or 32
    
  -- Get target to move to
  local target = self.targetMove[1]

  -- Check distance
  if checkDistance(self.x/ts, self.y/ts, target.x, target.y, 2) then
    
    -- Remove target and move to the next
    for i = 1, #self.targetMove do
      
      -- Remove the first one from the list and replace the others
      self.targetMove[i] = self.targetMove[i+1]
    end
  end

  -- Move to the next goal
  if self.targetMove[1] then
    local speed = self.speed*dt
    local r = math.atan2(self.targetMove[1].y*ts - self.y, self.targetMove[1].x*ts - self.x)
    self.x, self.y = self.x+math.cos(r)*speed, self.y+math.sin(r)*speed
  end
end

-- Check distance
function checkDistance(ax, ay, bx, by, distance)
  local c = ax*ax + bx*bx
  if c <= distance*distance then
    return true
  end
  return false
end

-- Create a path to a location
function getPath(self, x, y)
  self.path = self.world:getPathfinderPath(self.x, self.y, x, y)
end

-- Destroy monster
function destroy(self)

  -- Destroy hitbox
  self.world.collider:remove(self.hitbox)
end