local shape=require "shape"
local anim8=require 'lib.anim8'
local gui=require "lib.gui"
local math = math

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
  s.getPath=getPath
  s.checkPositionVisible=checkPositionVisible
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

function updateMonster(self,dt)
  self.current=self.anims[self.animType][self.direction]  -- set the correct animation
  self.current:update(dt) -- update anim8
end

function drawMonster(self)
  self.current:draw(self.sheet,self.x,self.y,nil,self.scale,self.scale,self.w/2,self.h/2)
end

-- 

-- Create a path to a location
function getPath(self, x, y)
  local map = self.world.pathfindingMap

  -- Check if the position is visible
  if checkPositionVisible(map, self.x, self.y, x, y) then
    return {x, y}
  end

  -- Iterate paths to see if one has already been created
  for _, path in ipairs(self.world.paths) do

    -- Check to see if the end position is the same
    if path[1].x == x and path[1].y == y then
      
    end
  end

  -- Create a table of nodes to walk to
  local nodes = {}
  
  -- Get monster position and convert to pathfinding position
  local mx, my = self.x / 32, self.y / 32

  -- Get x/y and convert to pathfinding position
  local px, py = x / 32, y / 32

  -- Use the pathfinder to create a node map
  local path, length = self.world.pathfinder:getPath(mx, my, px, py)

  --[[Iterate backwards through the node list and remove any that are unecessary
  for i = #path, 1, -1 do
    if checkPositionVisible(map, path[i].x, path[i].y, x, y) then
      path[i] = nil
    end
  end]]

  -- Add path to world paths

  return path, length
end

-- Check if a position is visible or not
function checkPositionVisible(map, mx, my, px, py)

  -- Get monster position and convert to pathfinding position
  local mx, my = mx / 32, my / 32

  -- Get x/y and convert to pathfinding position
  local px, py = px / 32, py / 32

  -- Get all the tiles that are intersected
  local tiles = raytraceGrid(mx, my, px, py)

  -- Check tiles (returning false with the function if it sees a wall (0))
  for _, tile in ipairs(tiles) do
    if map[tile.y] and map[tile.y][tile.x] == 0 then
      return false 
    end
  end
end

-- Raytrace function for grid
function raytraceGrid(x0, y0, x1, y1)

  -- Table of tiles visited
  local tiles = {}

  -- Get angle
  local dx = math.abs(x1 - x0)
  local dy = math.abs(y1 - y0)

  -- Get starting location (floored)
  local x = math.floor(x0)
  local y = math.floor(y0)

  -- Locals for number of tiles and increments
  local n = 1
  local x_inc, y_inc
  local error

  if dx == 0 then
      x_inc = 0
      error = math.huge  -- Represents infinity in Lua
  elseif x1 > x0 then
      x_inc = 1
      n = n + math.floor(x1) - x
      error = (math.floor(x0) + 1 - x0) * dy
  else
      x_inc = -1
      n = n + x - math.floor(x1)
      error = (x0 - math.floor(x0)) * dy
  end

  if dy == 0 then
      y_inc = 0
      error = error - math.huge  -- Represents infinity in Lua
  elseif y1 > y0 then
      y_inc = 1
      n = n + math.floor(y1) - y
      error = error - (math.floor(y0) + 1 - y0) * dx
  else
      y_inc = -1
      n = n + y - math.floor(y1)
      error = error - (y0 - math.floor(y0)) * dx
  end

  -- Iterate through all tiles that it visits
  while n > 0 do

      -- Add to list of tiles
      tiles[#tiles + 1] = {x, y}

      if error > 0 then
          y = y + y_inc
          error = error - dx
      else
          x = x + x_inc
          error = error + dy
      end

      n = n - 1
  end
  return tiles
end