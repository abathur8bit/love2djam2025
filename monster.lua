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
      
      -- Can't see the player, has no target move, see if it can 'sense' them (up to 8 tiles away)
      elseif not monster.targetMove and checkDistance(monster.x, monster.y, player.x, player.y, ts * 8) then

        -- Path to that position
        monster.targetMove = monster.world:getPath(monster.x, monster.y, player.x, player.y)
        goto continue
      end
    end
    ::continue::
  end,

  -- Basic ranger
  basic_ranger = function(monster, dt)
    local ts = monster.world.tileSize

    -- Reduce attack cooldown
    monster.fireRateTimer = monster.fireRateTimer - dt

    -- Check players to see if it can see one
    for key, player in pairs(monster.world.players) do
      if monster.world:checkPositionVisible(monster.x, monster.y, player.x, player.y) then

        -- Check distance
        if not checkDistance(monster.x, monster.y, player.x, player.y, ts * 8) then
          
          -- Set new movement target for the player
          monster.targetMove = {{x = player.x, y = player.y}}
        else

          -- Remove targetMove
          monster.targetMove = nil
        end

        -- Check distance in range
        if checkDistance(monster.x, monster.y, player.x, player.y, ts * monster.fireRange) then
          
          -- Fire a bullet
          monster:monsterFireBullet(player.x, player.y)
        end
        goto continue
      end
    end
    ::continue::
  end,

  -- Sense ranger
  sense_ranger = function(monster, dt)
    local ts = monster.world.tileSize

    -- Reduce attack cooldown
    monster.fireRateTimer = monster.fireRateTimer - dt

    -- Check players to see if it can see one
    for key, player in pairs(monster.world.players) do
      if monster.world:checkPositionVisible(monster.x, monster.y, player.x, player.y) then

        -- Check distance
        if not checkDistance(monster.x, monster.y, player.x, player.y, ts * 8) then
          
          -- Set new movement target for the player
          monster.targetMove = {{x = player.x, y = player.y}}
        else

          -- Remove targetMove
          monster.targetMove = nil
        end

        -- Check distance in range
        if checkDistance(monster.x, monster.y, player.x, player.y, ts * monster.fireRange) then
          
          -- Fire a bullet
          monster:monsterFireBullet(player.x, player.y)
        end
        goto continue

      -- Can't see the player, has no target move, see if it can 'sense' them (up to 8 tiles away)
      elseif not monster.targetMove and checkDistance(monster.x, monster.y, player.x, player.y, ts * 8) then

        -- Path to that position
        monster.targetMove = monster.world:getPath(monster.x, monster.y, player.x, player.y)
        goto continue
      end
    end
    ::continue::
  end,

  -- Boss
  boss = function(monster, dt)
    local ts = monster.world.tileSize

    -- Phase timer
    monster.phaseTimer = monster.phaseTimer or 10
    monster.phaseTimer = math.max(0, monster.phaseTimer - dt)
    monster.phase = monster.phase or 1
    monster.targetMoveTimeout=999

    -- Phase 1-- Chase the player and fire a burst of 3 shots
    if monster.phase == 1 then
      print('boss on phase 1')
    
      -- Check players to see if it can see one
      for key, player in pairs(monster.world.players) do
        if monster.world:checkPositionVisible(monster.x, monster.y, player.x, player.y) then

          -- Check distance
          if not checkDistance(monster.x, monster.y, player.x, player.y, ts * 3) then
            
            -- Set new movement target for the player
            monster.targetMove = {{x = player.x, y = player.y}}
          else

            -- Remove targetMove
            monster.targetMove = nil
          end

          -- Check distance in range
          if checkDistance(monster.x, monster.y, player.x, player.y, ts * 50) then

            -- Get angle of shot
            local theta = math.atan2(player.y - monster.y, player.x - monster.x) + math.pi*0.5
    
            -- Fire a barrage of bullets
            local angle_space = 0.14
            for i = 1, 3 do
              if i==1 then
                monster:monsterFireBullet(player.x, player.y)
              elseif i%2==0 then
                monster:monsterFireBullet(
                  monster.x + math.cos(theta - angle_space * math.floor(i*0.5)) * 50,
                  monster.y + math.sin(theta - angle_space * math.floor(i*0.5)) * 50
                )
              else
                monster:monsterFireBullet(
                  monster.x + math.cos(theta + angle_space * math.floor(i*0.5)) * 50,
                  monster.y + math.sin(theta + angle_space * math.floor(i*0.5)) * 50
                )
              end
            end
          end
          goto continue
        end
      end
      ::continue::
      
      -- Move to one of the corners and change to Phase 2
      if monster.phaseTimer <= 0 then
        monster.phase = 2
        monster.phaseTimer = 10
        monster.fireRate = 2.5

        -- Set a movement target
        local world = monster.world
        local map = world.map
        local list = {}
        if map.layers["generators"] then
          for _,generator in pairs(map.layers["generators"].objects) do
            if generator.name=="boss" then
              list[#list + 1] = {x = generator.x, y = generator.y}
            end
          end
        end

        -- Set new movement target for the boss
        monster.targetMove = {list[math.random(1, #list)]}
      end

    -- Phase 2
    elseif monster.phase == 2 then
      print('boss on phase 2')

      -- Check for no movement
      if not monster.targetMove then

        -- Fire Rate
        monster.fireRateTimer = monster.fireRateTimer - dt

        -- Check players to see if it can see one
        for key, player in pairs(monster.world.players) do
          if monster.world:checkPositionVisible(monster.x, monster.y, player.x, player.y) then

            -- Check distance in range
            if checkDistance(monster.x, monster.y, player.x, player.y, ts * 50) then

              -- Get angle of shot
              local theta = math.atan2(player.y - monster.y, player.x - monster.x) + math.pi*0.5
      
              -- Fire a barrage of bullets
              local angle_space = 0.08
              for i = 1, 17 do
                if i==1 then
                  monster:monsterFireBullet(player.x, player.y)
                elseif i%2==0 then
                  monster:monsterFireBullet(
                    monster.x + math.cos(theta - angle_space * math.floor(i*0.5)) * 50,
                    monster.y + math.sin(theta - angle_space * math.floor(i*0.5)) * 50
                  )
                else
                  monster:monsterFireBullet(
                    monster.x + math.cos(theta + angle_space * math.floor(i*0.5)) * 50,
                    monster.y + math.sin(theta + angle_space * math.floor(i*0.5)) * 50
                  )
                end
              end
            end
            goto continue
          end
        end
        ::continue::

        -- If it's the end of the phase, change to phase 1
        if monster.phaseTimer <= 0 then
          monster.fireRate = 1.25
          monster.phase = 1
          monster.phaseTimer = 10
        end
      end
    end
  end,
}

function createMonsterHitbox(self)
  self.hitbox=self.world:createHitbox(self.x,self.y,self.w,self.h,self.type,self.id,self.name,self)
end

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
  s.keyPressed=false
  s.speed=100
  s.animType="idle"
  s.direction="downright"
  s.update=updateMonster
  s.checkCollisions=checkMonsterCollisions
  s.draw=drawMonster
  s.getPath=getPath
  s.checkPositionVisible=checkPositionVisible
  s.monsterFireBullet=monsterFireBullet
  s.destroy=destroy
  s.followPath=followPath
  s.createHitbox=createMonsterHitbox
  s.idleTimer=0.0
  s.idleTimerDelay=5
  s.sheet=love.graphics.newImage(filename)
  s.grid=anim8.newGrid(s.w,s.h,s.sheet:getWidth(),s.sheet:getHeight())
  s.animType="walk"
  s.direction="downright"
  s.keyPressed=false
  s.fireRate=2
  s.fireRange=14
  s.firePower='monster'
  s.fireRateTimer=s.fireRate
  s.targetAttack=nil
  s.targetMove=nil
  s.targetMoveTimeout=0
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
  love.graphics.setFont(fontSheets.small.font)
  love.graphics.setColor(1,1,1,1)
  self.current:draw(self.sheet,self.x,self.y,nil,self.scale,self.scale,self.w/2,self.h/2) -- draw anim8
  love.graphics.setColor(1,0,0)
  gui.centerText(self.health,self.x,self.y-self.h/2)
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
  if self.targetMoveTimeout > 8 then self.targetMove = nil end

  -- Move to the next goal
  if self.targetMove and self.targetMove[1] then
    local speed = self.speed*dt
    local r = math.atan2(self.targetMove[1].y - self.y, self.targetMove[1].x - self.x)
    self.x, self.y = self.x+math.cos(r)*speed, self.y+math.sin(r)*speed
  else self.targetMove = nil end
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