require "shape"

-- create world of width x height pixels in size
function createWorld(width,height,screenWidth,screenHeight)
  w={}
  
  -- world vars
  w.players={}
  w.monsters={}
  w.shapes={}
  w.width=width
  w.height=height
  w.screenWidth=screenWidth
  w.screenHeight=screenHeight
  
  -- functions
  w.update=updateWorld
  w.draw=drawWorld
  w.addShape=addWorldShape
  w.addPlayer=addPlayerShape
  w.addMonster=addMonsterShape
  return w
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
  love.graphics.setColor(1,1,1,1)
  for i,s in ipairs(self.shapes) do 
    s:draw() 
  end
end

