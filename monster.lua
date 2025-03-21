local shape=require "shape"
local anim8=require 'lib.anim8'
local gui=require "lib.gui"
local math = math

-- List of behaviours for the enemies to use
local Behaviours = {

  -- Basic behaviour, if you see an enemy, move towards them
  basic = function(monster, dt)
    local ts = monster.world.tileSize

    -- Check players to see if it can see one
    for key, player in pairs(monster.world.players) do
      if monster.world:checkPositionVisible(monster.x, monster.y, player.x, player.y) then
        
        -- Set new movement target for the player
        monster.targetMove = {{x = player.x, y = player.y}}
        goto continue
      end
    end
    ::continue::
  end,

  -- Sense behaviour, if the enemy is close enough to a player, then will start to path towards their position around the map
  sense = function(monster, dt)
    local ts = monster.world.tileSize

    -- Check players to see if it can see one
    for key, player in pairs(monster.world.players) do
      if monster.world:checkPositionVisible(monster.x, monster.y, player.x, player.y) then
        
        -- Set new movement target for the player
        monster.targetMove = {{x = player.x, y = player.y}}
        goto continue
      end
      
      -- Can't see the player, has no target move, see if it can 'sense' them (up to 8 tiles away)
      if not monster.targetMove and checkDistance(monster.x, monster.y, player.x, player.y, ts * 8) then

        -- Path to that position
        monster.targetMove = monster.world:getPath(monster.x, monster.y, player.x, player.y)
        goto continue
      end
    end
    ::continue::
  end,

  -- Follow behaviour, the monster will follow a nearby monster

}

function createMonster(world,id,x,y,w,h,filename,name,behaviour)
  local behaviour = behaviour or 'basic'
  local s=shape.createShape(x,y,w,h,0,gui.createColor(1,1,1,1))
  s.type="monster"
  s.name=name
  s.behaviourUpdate=Behaviours[behaviour]
  s.world=world
  s.id=id
  s.z=9 -- make sure it's under the player
  s.score=0
  s.health=INITIAL_PLAYER_HEALTH
  s.fireRate=0.2
  s.fireRateTimer=s.fireRate
  s.keyPressed=false
  s.speed=100
  s.animType="idle"
  s.direction="downright"
  s.update=updateMonster
  s.checkCollisions=checkMonsterCollisions
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

  -- Behaviour
  self:behaviourUpdate(dt)

  -- Follow path
  if self.targetMove then
    self:followPath(dt)
  end

  -- Check collisions
  self:checkCollisions(dt)

  -- Animations
  self.current=self.anims[self.animType][self.direction]  -- set the correct animation
  self.current:update(dt) -- update anim8
end

-- Draw function
function drawMonster(self)
  self.current:draw(self.sheet,self.x,self.y,nil,self.scale,self.scale,self.w/2,self.h/2) -- draw anim8
end

-- Check collisions
function checkMonsterCollisions(self, dt)
  local world = self.world

  -- Move collider
  self.hitbox.collider:moveTo(self.x, self.y)

  -- Check collisions in the HC collider for the world
  for shape, delta in pairs(world.collider:collisions(self.hitbox.collider)) do
    local hitbox=world.hitboxes[shape]
    if hitbox~=nil and hitbox.active==true then
      local hitboxName,hitboxNumber=parseNameNumber(hitbox.name)
      local number=hitboxNumber --using hitboxNumber in for loop seems to go out of scope, or assigning to local var

      -- Walls and doors
      if hitbox.type=="wall" or hitbox.type=="door" then

        -- Bump monster back as they hit a wall
        self.x=self.x+delta.x
        self.y=self.y+delta.y

        -- Move collider
        self.hitbox.collider:moveTo(self.x, self.y)
      
      -- Bullets
      elseif hitbox.type=='bullet' then
        -- Take damage
      end
    end
  end
end

-- Follow node path
function followPath(self, dt)
  local ts = self.world.tileSize or 32
    
  -- Check for target and distance
  local target = self.targetMove[1]
  if target and checkDistance(self.x, self.y, target.x, target.y, ts*2) then
    
    -- Remove target and move to the next
    for i = 1, #self.targetMove do
      
      -- Remove the first one from the list and replace the others
      self.targetMove[i] = self.targetMove[i+1]
    end
  end

  -- Move to the next goal
  if self.targetMove[1] then
    local speed = self.speed*dt
    local r = math.atan2(self.targetMove[1].y - self.y, self.targetMove[1].x - self.x)
    self.x, self.y = self.x+math.cos(r)*speed, self.y+math.sin(r)*speed
  else self.targetMove = nil end
end

-- Check distance
function checkDistance(ax, ay, bx, by, distance)
  local a, b = ax-bx, ay-by
  local c = a*a + b*b
  if c <= distance*distance then
    return true
  end
  return false
end

-- Destroy monster
function destroy(self)
  local world = self.world

  -- Destroy hitbox
  world.collider:remove(self.hitbox)

  -- Iterate through world's monster table and remove self from the list
  for i = #world.monsters, 1, -1 do
    if world.monsters[i]==self then
      world.monsters[#world.monsters], world.monsters[i] = nil, world.monsters[#world.monsters]
      goto continue
    end
  end
  ::continue::
  return true
end