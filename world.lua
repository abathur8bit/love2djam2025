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
  
  -- functions
  w.update=updateWorld
  w.draw=drawWorld
  w.addShape=addWorldShape
  w.addPlayer=addPlayerShape
  w.addMonster=addMonsterShape
  w.loadMap=loadMap
  w.adjustPathfinder=adjustPathfinder
  w.addPathfinder=addPathfinder
  w.createHitbox=createHitbox
  w.removeHitbox=removeHitbox
  w.removeShape=removeWorldShape
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
  self.pathfinderMap=map
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
  local grid = Grid(self.pathfinderMap)
  
  -- Create a pathfinder object using Jump Point Search
  self.pathfinder = Pathfinder(grid, 'JPS', 1)
  self.pathfinderPaths = {}
end

-- Adjust a pathfinder
function adjustPathfinder(self, x, y, width, height, value)
  for iy = math.floor(y/32), math.ceil(y/32+height/32) do
    for ix = math.floor(x/32), math.ceil(x/32+width/32) do
      if self.pathfinderMap[iy] and self.pathfinderMap[iy][ix] then
        self.pathfinderMap[iy][ix]=value
      end
    end
  end
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