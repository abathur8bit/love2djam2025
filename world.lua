local sti=require "lib.sti"
-- local Grid=require("lib.jumper.grid")
-- local Pathfinder=require("lib.jumper.pathfinder")
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
  w.addPathfinder=addPathfinder
  w.createHitbox=createHitbox
  w.removeHitbox=removeHitbox
  w.removeShape=removeWorldShape
  return w
end

-- hitbox: type,id,name,object,collider,active
function createHitbox(self,x,y,w,h,type,id,name,object)
  local collider=HC.rectangle(x,y,w,h)
  local hitbox={id=id,type=type,name=name,object=object,collider=collider,active=true}
  self.hitboxes[collider]=hitbox
  return hitbox
end

function removeHitbox(self,hitbox)
  self.collider:remove(hitbox.collider)
  hitbox.active=false
end

-- Loads in a map using a filename and the STI library
function loadMap(self, filename)
  self.map=sti(filename)
  print("Map:", self.map.tiledversion)
  self.width=self.map.width*self.map.tilewidth
  self.height=self.map.height*self.map.tileheight

  -- Add pathfinder
  self:addPathfinder()
end

-- Creates a walkable map using the collider from HC
function addPathfinder(self)

  -- -- Create a test shape for the collisions (test shape is slightly smaller than a tile)
  -- local tw, th = 32, 32
  -- local collider = self.collider
  -- local shape = collider:rectangle(0, 0, tw - 2, th - 2)

  -- -- Create grid
  -- local map = {}
  -- for y = 1, self.height do
  --   map[y] = {}
  --   for x = 1, self.width do
  --     map[y][x] = 1

  --     -- Move shape and check collisions
  --     shape:moveTo((x-1)*tw + tw*0.5, (y-1)*th + th*0.5)
  --     for otherShape, delta in pairs(collider:collisions(shape)) do

  --       -- If collision is a wall, set it to value 0
  --       if otherShape.type == 'wall' then
  --         map[y][x] = 0
  --         goto continue
  --       end
  --     end
  --     ::continue::
  --   end
  -- end

  -- -- Remove shape from the collider
  -- collider:remove(shape)

  -- -- Create jumper grid object
  -- local grid = Grid(map)
  
  -- Create a pathfinder object using Jump Point Search
  -- self.pathfinderMap = map
  -- self.pathfinder = Pathfinder(grid, 'JPS', 1)
  -- self.pathfinderPaths = {}
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