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
  w.adjustPathfinder=adjustPathfinder
  w.addPathfinder=addPathfinder
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

  -- Create pathfinder map
  local map = {}
  for y = 1, self.map.height do
    map[y] = {}
    for x = 1, self.map.width do
      map[y][x] = 1
    end
  end
  self.pathfinder.map=map
end

-- Creates a walkable map using the collider from HC
function addPathfinder(self)
  
  -- Iterate all hitboxes
  for collider, hitbox in pairs(self.hitboxes) do
    if hitbox.type=='wall' or (hitbox.type=='door' and hitbox.active) then
      local x1, y1, x2, y2 = collider:bbox()
      self:adjustPathfinder(x1, y1, math.abs(x2-x1), math.abs(y2-y1), 0)
    end
  end

  -- Create jumper grid object
  local grid = Grid(self.pathfinder.map)
  
  -- Create a pathfinder object using Jump Point Search
  self.pathfinder.finder = Pathfinder(grid, 'JPS', 1)
  self.pathfinder.paths = {}
end

-- Adjust a pathfinder
function adjustPathfinder(self, x, y, width, height, value, ts)
  local ts = ts or self.tileSize or 32
  for iy = math.floor(y/ts), math.ceil(y/ts+height/ts) do
    for ix = math.floor(x/ts), math.ceil(x/ts+width/ts) do
      if self.pathfinder.map[iy] and self.pathfinder.map[iy][ix] then
        self.pathfinder.map[iy][ix]=value
      end
    end
  end
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
      if checkDistance(ax/ts, ay/ts, worldPath[1].x, worldPath[1].y, 4) then

        -- Check to see if the first node visible
        if self:checkPositionVisible(worldPath[1].x*ts, worldPath[1].y*ts, bx, by, ts) then
          
          -- Iterate the path to see if any other nodes are visible
          for i = #worldPath, 1, -1 do
            local node = worldPath[i]
            if self:checkPositionVisible(ax, ay, node.x, node.y, ts) then
    
              -- Copy the node path
              path = {}
              for j = 1, #worldPath do
                path[j] = worldPath[j-1+i]
              end
              goto pathCopied
            end
          end
        end
      end
    end

    -- Successfully copied an existing path
    ::pathCopied::
    
    -- Unable to copy an existing path, so create a new one
    if not path then
      path = self:newPath(ax, ay, bx, by, ts)
    end
    return path
end

-- Check distance
function checkDistance(ax, ay, bx, by, distance)
  local c = ax*ax + bx*bx
  if c <= distance*distance then
    return true
  end
  return false
end

-- Creates a new path using the pathfinder
function newPath(self, ax, ay, bx, by, ts)
  local ts = ts or self.tileSize or 32
  local path, length = self.pathfinder.finder:getPath(ax/ts, ay/ts, bx/ts, by/ts)
  if path then 
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
      node.x * ts + ts*0.5,
      node.y * ts + ts*0.5,
      pnode.x * ts + ts*0.5,
      pnode.y * ts + ts*0.5
    )
  end
  love.graphics.setColor(1, 1, 1, 1)
end

-- Check if a position is visible or not
function checkPositionVisible(self, ax, ay, bx, by, ts)
  local ts = ts or 32
  local map = self.pathfinder.map

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
      -- wrap shap around to other side of the world
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