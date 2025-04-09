local shape=require "shape"
local anim8=require 'lib.anim8'
local gui=require "lib.gui"
local math = math
local Monsters = require('monsters.monster_stats')

function createMonsterHitbox(self)
  self.hitbox=self.world:createHitbox(self.x,self.y,self.w,self.h,self.type,self.id,self.name,self)
end

function createMonster(world,id,x,y,name)

  -- Get enemy stats and
  local stats = Monsters[name]()

  -- Create shape object
  local s=shape.createShape(x,y,stats.w,stats.h,0,gui.createColor(1,1,1,1))

  -- Copy all the stats over
  for key, value in pairs(stats) do
    s[key] = value
  end

  -- Setting values
  s.type="monster"
  s.name=name
  s.world=world
  s.id=id
  s.z=9 -- make sure it's under the player
  s.score=0
  s.maxHealth=s.health
  s.keyPressed=false

  -- Set variables for attacking and moving
  s.idleTimer=0.0
  s.idleTimerDelay=5
  s.fireRateTimer=s.fireRate
  s.targetAttack=nil
  s.targetMove=nil
  s.targetMoveTimeout=0

  -- Animations
  s.grid=anim8.newGrid(s.w,s.h,s.sheet:getWidth(),s.sheet:getHeight())
  s.animType="idle"
  s.direction="downright"
  s.anims={
    idle={
      up        = anim8.newAnimation(s.grid("1-15",1),0.15),
      down      = anim8.newAnimation(s.grid("1-15",1),0.15),
      right     = anim8.newAnimation(s.grid("1-15",1),0.15),
      left      = anim8.newAnimation(s.grid("1-15",1),0.15),
      upleft    = anim8.newAnimation(s.grid("1-15",1),0.15),
      upright   = anim8.newAnimation(s.grid("1-15",1),0.15),
      downright = anim8.newAnimation(s.grid("1-15",1),0.15),
      downleft  = anim8.newAnimation(s.grid("1-15",1),0.15),
    },
    walk={
      up        = anim8.newAnimation(s.grid('1-15',2),0.15),
      down      = anim8.newAnimation(s.grid('1-15',2),0.15),
      right     = anim8.newAnimation(s.grid('1-15',2),0.15),
      left      = anim8.newAnimation(s.grid('1-15',2),0.15),
      upleft    = anim8.newAnimation(s.grid('1-15',2),0.15),
      upright   = anim8.newAnimation(s.grid('1-15',2),0.15),
      downright = anim8.newAnimation(s.grid('1-15',2),0.15),
      downleft  = anim8.newAnimation(s.grid('1-15',2),0.15),
    },
    hit={
      up        = anim8.newAnimation(s.grid('1-8',3),0.15,function() s.animType="idle" end),
      down      = anim8.newAnimation(s.grid('1-8',3),0.15,function() s.animType="idle" end),
      right     = anim8.newAnimation(s.grid('1-8',3),0.15,function() s.animType="idle" end),
      left      = anim8.newAnimation(s.grid('1-8',3),0.15,function() s.animType="idle" end),
      upleft    = anim8.newAnimation(s.grid('1-8',3),0.15,function() s.animType="idle" end),
      upright   = anim8.newAnimation(s.grid('1-8',3),0.15,function() s.animType="idle" end),
      downright = anim8.newAnimation(s.grid('1-8',3),0.15,function() s.animType="idle" end),
      downleft  = anim8.newAnimation(s.grid('1-8',3),0.15,function() s.animType="idle" end),
    },
  }

  -- Set up functions
  s.update=updateMonster
  s.checkCollisions=checkMonsterCollisions
  s.draw=drawMonster
  s.getPath=getPath
  s.checkPositionVisible=checkPositionVisible
  s.monsterFireBullet=monsterFireBullet
  s.destroy=destroy
  s.followPath=followPath
  s.createHitbox=createMonsterHitbox
  s.playHitAnim=playHitAnim

  -- Set up animations
  s.current=s.anims[s.animType][s.direction]
  return s
end

function playHitAnim(self)
  if self.animType~="hit" then
    self.animType="hit"
    self.current:gotoFrame(1)
  end
end

-- Update function
function updateMonster(self,dt)

  -- Behaviour
  self:behaviour(dt)

  -- Follow path
  if self.targetMove then
    self:followPath(dt)
  end

  -- Check collisions
  self:checkCollisions(dt)

  -- Animations if we are not playing hit, then play idle or walk
  if self.animType~="hit" then
    if self.targetMove then
      self.animType="walk"
    else
      self.animType="idle"
    end
  end
  self.current=self.anims[self.animType][self.direction]  -- set the correct animation
  self.current:update(dt) -- update anim8
end

-- Draw function
function drawMonster(self)
  love.graphics.setFont(fontSheets.small.font)
  love.graphics.setColor(1,1,1,1)
  self.current:draw(self.sheet,self.x,self.y,nil,self.scale,self.scale,self.w/2,self.h/2) -- draw anim8

  -- draw how much health is left
  love.graphics.setColor(1,0,0)
  -- gui.centerText(self.health,self.x,self.y-self.h/2)
  love.graphics.setLineWidth(1)
  local barHeight=2
  drawPercentBar(self.x-self.w/2,self.y-self.w/2-barHeight,self.w,barHeight,self.health/self.maxHealth)
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
      if hitbox.type=="wall" or (hitbox.type=="door" and hitbox.active) then

        -- Bump monster back as they hit a wall
        self.x=self.x+delta.x
        self.y=self.y+delta.y

        -- Move collider
        self.hitbox.collider:moveTo(self.x, self.y)
      
      -- Bullets
      elseif hitbox.type=='bullet' then
        -- Take damage

      -- Player
      elseif hitbox.type=='player' and self.meleeTimer <= 0 then
        local player = hitbox.object
        player.health = player.health - self.meleeDamage
        self.meleeTimer = 1
        self:destroy()
        playSfx(sfx.monsterMeleePlayer)
      end
    end
  end
end

-- Follow node path
function followPath(self, dt)
  local ts = self.world.tileSize or 32
    
  -- Check for target and distance
  if self.targetMove then
    local target = self.targetMove[1]
    local target2 = self.targetMove[2]
    if target and target2 then
      
      -- Check distance to the target and if the next target is visible
      if checkDistance(self.x, self.y, target.x, target.y, ts*0.5) and self.world:checkPositionVisible(self.x, self.y, target2.x, target2.y) then

        -- Reset target move timeout
        self.targetMoveTimeout = 0
      
        -- Remove target and move to the next
        for i = 1, #self.targetMove do
          
          -- Remove the first one from the list and replace the others
          self.targetMove[i] = self.targetMove[i+1]
        end
      end
    elseif target and checkDistance(self.x, self.y, target.x, target.y, ts*0.5) then
      self.targetMove = nil
    end
  end

  -- Timeout if the monster can't reach it's movement target
  self.targetMoveTimeout = self.targetMoveTimeout + dt
  if self.targetMoveTimeout > 8 then
    self.targetMove = nil
    self.targetMoveTimeout = 0
  end

  -- Move to the next goal
  if self.targetMove and self.targetMove[1] then
    local speed = self.speed*dt
    local r = math.atan2(self.targetMove[1].y - self.y, self.targetMove[1].x - self.x)
    self.x, self.y = self.x+math.cos(r)*speed, self.y+math.sin(r)*speed
  else
    self.targetMove = nil
    self.targetMoveTimeout = 0
  end
end

-- Fire bullet
function monsterFireBullet(self, mx, my)

  -- Attack
  if self.fireRateTimer <= 0 then
    local x, y = self.x, self.y
    local theta = math.atan2(my - y, mx - x)
    self.world:addShape(createBullet(self.world, self, x, y, theta + math.pi*0.5))
    self.fireRateTimer = self.fireRate
  end
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
  world:removeHitbox(self.hitbox)
  self.hitbox.active = false

  -- Iterate through world's monster table and remove self from the list
  for i = #world.monsters, 1, -1 do
    if world.monsters[i] == self then
      world.monsters[#world.monsters], world.monsters[i] = nil, world.monsters[#world.monsters]
      break
    end
  end
  for i = #world.shapes, 1, -1 do
    if world.shapes[i] == self then
      world.shapes[#world.shapes], world.shapes[i] = nil, world.shapes[#world.shapes]
      break
    end
  end
  return true
end