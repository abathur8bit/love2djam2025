local sti=require "lib.sti"
local Grid=require("lib.jumper.grid")
local Pathfinder=require("lib.jumper.pathfinder")
local HC=require "lib.HC"

print("STI:", sti._VERSION)

require "shape"

-- create world of width x height pixels in size
function createWorld(screenWidth,screenHeight)
  w={}
  
  -- world vars
  w.players={}
  w.monsters={}
  w.shapes={}
  w.width=0
  w.height=0
  w.screenWidth=screenWidth
  w.screenHeight=screenHeight
  w.collider = HC.new(128)
  w.hitboxes={}
  w.tileSize=32
  
  -- functions
  w.update=updateWorld
  w.draw=drawWorld
  w.addShape=addWorldShape
  w.addPlayer=addPlayerShape
  w.addMonster=addMonsterShape
  w.loadMap=loadMap
  w.addPathfinder=addPathfinder
  w.addVisibility=addVisibility
  w.getPath=getPath
  w.newPath=newPath
  w.checkPositionVisible=checkPositionVisible

  w.createHitbox=createHitbox
  w.removeHitbox=removeHitbox
  w.removeShape=removeWorldShape
  w.removeShapeWithHitbox=removeShapeWithHitbox
  return w
end

-- hitbox: type,id,name,object,collider,active
function createHitbox(self,x,y,w,h,type,id,name,object)
  if not (type and id and name) then error('Insufficent Hitbox Info') end
  local collider=self.collider:rectangle(x,y,w,h)
  local hitbox={id=id,type=type,name=name,object=object,collider=collider,active=true}
  self.hitboxes[collider]=hitbox
  return hitbox
end

function removeHitbox(self,hitbox)
  self.collider:remove(hitbox.collider)
  hitbox.active=false
  self.hitboxes[hitbox]=nil
end

-- Loads in a map using a filename and the STI library
function loadMap(self, filename)
  self.players={}
  self.monsters={}
  self.shapes={}
  self.width=0
  self.height=0
  self.collider = HC.new(128)
  self.hitboxes={}
  self.pathfinder = {}

  self.map=sti("maps/"..filename..".lua")
  print("Map:", self.map.tiledversion)
  self.width=self.map.width*self.map.tilewidth
  self.height=self.map.height*self.map.tileheight
end

-- Adjust visibility map
function addVisibility(self)

  -- Create visibility map
  local map = {}
  for y = 1, self.map.height do
    map[y] = {}
    for x = 1, self.map.width do
      map[y][x] = 1
    end
  end
  self.visibilityMap = map

  -- Local funder for adjusting the visibility map
  local adjust = function(world, x, y, width, height, value, ts)
    local ts = ts or world.tileSize or 32
    for iy = math.floor(y/ts), math.floor(y/ts) + math.ceil(height/ts) do
      for ix = math.floor(x/ts), math.floor(x/ts) + math.ceil(width/ts) do
        if world.visibilityMap[iy] and world.visibilityMap[iy][ix] then
          world.visibilityMap[iy][ix]=value
        end
      end
    end
  end

  -- Iterate all hitboxes
  for collider, hitbox in pairs(self.hitboxes) do
    if hitbox.type=='wall' or (hitbox.type=='door' and hitbox.active) then
      local x1, y1, x2, y2 = collider:bbox()
      adjust(self, x1, y1, math.abs(x2-x1), math.abs(y2-y1), 0)
    end
  end
end

-- Creates a walkable map using the collider from HC
function addPathfinder(self)

  -- Create a pathfinder map that gives some clearance
  local map = {}
  for y = 1, self.map.height do
    map[y] = {}
    for x = 1, self.map.width do
      map[y][x] = 1
    end
  end
  self.pathfinder.map = map

  -- Local function for adjusting the pathfinder map
  local adjust = function(world, x, y, width, height, value, ts)
    local ts = ts or world.tileSize or 32
    for iy = math.floor(y/ts)-1, math.floor(y/ts) + math.ceil(height/ts)+1 do
      for ix = math.floor(x/ts)-1, math.floor(x/ts) + math.ceil(width/ts)+1 do
        if world.pathfinder.map[iy] and world.pathfinder.map[iy][ix] then
          world.pathfinder.map[iy][ix]=value
        end
      end
    end
  end
  
  -- Iterate all hitboxes
  for collider, hitbox in pairs(self.hitboxes) do
    if hitbox.type=='wall' or (hitbox.type=='door' and hitbox.active) then
      local x1, y1, x2, y2 = collider:bbox()
      adjust(self, x1, y1, math.abs(x2-x1), math.abs(y2-y1), 0)
    end
  end

  -- Create jumper grid object
  local grid = Grid(self.pathfinder.map)
  
  -- Create a pathfinder object using Jump Point Search
  self.pathfinder.finder = Pathfinder(grid, 'JPS', 1)
  self.pathfinder.paths = {}
end

-- Adds a new path to the world
function getPath(self, ax, ay, bx, by, ts)
  local ts = ts or self.tileSize or 32
  local paths = self.pathfinder.paths

    -- Check if the position is visible
    if self:checkPositionVisible(ax, ay, bx, by, ts) then
      return {bx, by}
    end
  
    -- Create a new node path
    local path
  
    -- Iterate paths to see if one has already been created
    for _, worldPath in ipairs(paths) do
  
      -- Check to see if the first node is nearby
      if checkDistance(ax, ay, worldPath[1].x, worldPath[1].y, 4) then
          
        -- Iterate the path to see if any of the nodes are visible
        for i = #worldPath, 1, -1 do
          local node = worldPath[i]
          if self:checkPositionVisible(ax, ay, node.x, node.y, ts) then
  
            -- Copy the node path
            path = {}
            for j = 1, #worldPath do
              path[j] = {
                x = worldPath[j-1+i].x,
                y = worldPath[j-1+i].y,
              }
            end
            goto pathCopied
          end
        end
      end
    end

    -- Successfully copied an existing path
    ::pathCopied::
    
    -- Unable to copy an existing path, so create a new one
    if not path then

      -- Call to the pathfinder
      local newPath = self:newPath(ax, ay, bx, by, ts)
      if newPath then

        -- Copy path
        path = {}
        for i, node in ipairs(newPath) do
          path[i] = {
            x = node.x,
            y = node.y,
          }
        end
      end
    end
    return path
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

-- Creates a new path using the pathfinder
function newPath(self, ax, ay, bx, by, ts)
  local ts = ts or self.tileSize or 32
  local newPath, length = self.pathfinder.finder:getPath(math.floor(ax/ts), math.floor(ay/ts), math.floor(bx/ts), math.floor(by/ts))
  if newPath then
    local path = {}
    for node, count in newPath:iter() do
      path[#path+1] = {
        x = node._x*ts+ts*0.5,
        y = node._y*ts+ts*0.5,
      }
    end
    self.pathfinder.paths[#self.pathfinder.paths+1] = path
    return path
  end
end

-- Draw pathfinder path
function drawPath(path, ts)
  local ts = ts or 32
  love.graphics.setColor(1, 0, 0, 1)
  for i = 2, #path do
    local node = path[i]
    local pnode = path[i-1]
    love.graphics.line(
      node.x,
      node.y,
      pnode.x,
      pnode.y
    )
  end
  love.graphics.setColor(1, 1, 1, 1)
end

-- Check if a position is visible or not
function checkPositionVisible(self, ax, ay, bx, by, ts)
  local ts = ts or 32
  local map = self.visibilityMap

  -- Convert pixel coordinates into tile coordinates
  local ax, ay, bx, by = ax/ts, ay/ts, bx/ts, by/ts

  -- Get all the tiles that are intersected
  local tiles = raytraceGrid(ax, ay, bx, by)

  -- Check tiles (returning false with the function if it sees a wall (0))
  for _, tile in ipairs(tiles) do
    if map[tile.y] and map[tile.y][tile.x] == 0 then
      return false 
    end
  end
  return true
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
      tiles[#tiles+1] = {x=x, y=y}

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

function addPlayerShape(self,p)
  table.insert(self.players,p)
  addWorldShape(self,p)
end

function addMonsterShape(self,m)
  table.insert(self.monsters,m)
  addWorldShape(self,m)
end

function addWorldShape(self,s)
  if s==nil then error("shape is nil. Did you forget to return in your create function?") end
  table.insert(self.shapes,s)
  table.sort(self.shapes,
    function(a,b) 
      return a.z<b.z 
    end)
end

function removeShapeWithHitbox(self,hitbox)
  for i,s in ipairs(self.shapes) do
    if s.hitbox==hitbox then
      table.remove(self.shapes,i)
      break
    end
  end
end

function removeWorldShape(self,shape)
  for i,s in ipairs(self.shapes) do
    if s==shape then
      table.remove(self.shapes,i)
      break
    end
  end
end


function updateWorld(self,dt)
  local player=nil
  for i,s in ipairs(self.shapes) do 
    if s:update(dt) == false then 
      table.remove(self.shapes,i) 
    else
      -- wrap shape around to other side of the world
      s.x = s.x % self.width
      s.y = s.y % self.height
    end
  end
end

function drawWorld(self)
  love.graphics.setColor(1, 1, 1)
  self.map:drawLayer(self.map.layers["ground"])
  self.map:drawLayer(self.map.layers["coloring"])
  self.map:drawLayer(self.map.layers["decorations"])
  love.graphics.setColor(1,1,1,1)
  for i,s in ipairs(self.shapes) do 
    s:draw() 
  end
end