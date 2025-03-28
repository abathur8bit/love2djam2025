local gui = {}

-- Just a widget to hold x,y,w,h,color and have draw and update functions
function gui.createWidget(x,y,width,height,widgetType)
  w={}
  w.x=x
  w.y=y
  w.w=width
  w.h=height
  w.type=widgetType
  w.color=gui.createColor(1,1,1,1)
  w.visible=true
  w.draw=function(self) end
  w.update=function(self) end
  
  return w
end

-- Create color table with red,green,blue,alpha, setColor(), components() and compare(). If alpha isn't supplied, defaults to 1.
-- local color=gui.createColor(1,1,1,1)
-- love.graphics.setColor(color:components())
-- setColor(r,g,b,a)
-- setColor255(r,g,b,a) - Set the color using 0-255, which is mapped to 0-1. 
function gui.createColor(red,green,blue,alpha)
  if alpha==nil then alpha=1 end
  c={}
  c.red=red or 1
  c.green=green or 1
  c.blue=blue or 1
  c.alpha=alpha or 1
  c.setColor=function(self,r,g,b,a) self.red=r; self.green=g; self.blue=b; self.alpha=a end
  c.setColor255=function(self,r,g,b,a) self.red=r/255; self.green=g/255; self.blue=b/255; self.alpha=a/255; end
  c.compare=function(self,c) return self.red==c.red and self.green==c.green and self.blue==c.blue and self.alpha==c.alpha end
  c.colors=function(self) return self.red,self.green,self.blue end
  c.components=function(self) return self.red,self.green,self.blue,self.alpha end
  return c
end

-- create color table using 0-255 as r,g,b,a values, which get converted to 0-1.
function gui.createColor255(red,green,blue,alpha)
  if alpha==nil then alpha=255 end
  return gui.createColor(red/255,green/255,blue/255,alpha/255)
end


-- Center text at the given point. 
function gui.centerText(text,x,y,centerVertically)
	local font       = love.graphics.getFont()
	local textWidth  = font:getWidth(text)
	local textHeight = font:getHeight()
  
  if centerVertically==nil then centerVertically=true end -- default to true
  if centerVertically then 
    love.graphics.print(text, x, y, 0, 1, 1, textWidth/2, textHeight/2)
  else
    love.graphics.print(text, x, y, 0, 1, 1, textWidth/2, 0)
  end
end

-- Right aligns text at given point
function gui.rightText(text,x,y)
	local font       = love.graphics.getFont()
	local textWidth  = font:getWidth(text)
	local textHeight = font:getHeight()
	love.graphics.print(text, x, y, 0, 1, 1, textWidth, 0)
end

-- draw a 10x10 crosshair in the color specified, or the current color if color is not specified
function gui.crosshair(x,y,r,g,b,a,fullscreen)
  local w=10
  local h=10
  if fullscreen~=nil and fullscreen then
    w=love.graphics.getWidth()
    h=love.graphics.getHeight()
  end
  
  if r==nil then 
    -- use whatever color is already active
    love.graphics.line(x,y-h,x,y+h)
    love.graphics.line(x-w,y,x+w,y)
  else
    -- use the color provided
    love.graphics.setColor(r,g,b,a)
    love.graphics.line(x,y-h,x,y+h)
    love.graphics.line(x-w,y,x+w,y)
  end
end



-- creates a menu that will draw itself and call handler(menu) when the user presses *enter*. 
-- Call selectNext and selectPrevious for up/down arrow movements.
-- Call handle() when user hits *enter* or otherwise selects the menu item (ie joystick A, mouse clicked).
-- Keep in mind that if windowed==true the window should be large enough to hold all menu items
-- as this isn't calculated.
function gui.createMenu(title,options,x,y,width,height,windowed,normalColor,selectedColor,handleSelect,handleBack,font)
  if normalColor==nil then normalColor=gui.createColor255(3,251,255) end
  if selectedColor==nil then selectedColor=gui.createColor(1,1,0) end
  if fontHeight==nil then fontHeight=27 end

  local w=gui.createWidget(x,y,width,height,"menu")
  w.title=title
  w.options=options
  w.selectedIndex=1 --select the first item
  w.windowed=windowed
  w.offset=50 -- amount to offset the text inside the window
  w.normalColor=normalColor
  w.selectedColor=selectedColor
  w.font=font
  w.fontHeight=font:getHeight()
  w.draw=gui.menuDraw
  w.selectNext=gui.menuSelectNext
  w.selectPrevious=gui.menuSelectPrevious
  w.handle=gui.menuHandleChoice
  w.handleSelect=handleSelect
  w.handleBack=handleBack
  w.keystate=gui.menuKeystate
  w.mousemoved=gui.menuMouseMoved
  w.keys={buttonA=false,up=false,down=false,left=false,right=false,buttonB=false}
  
  return w
end

function gui.menuKeystate(self,keystate)
  for key,value in pairs(self.keys) do
    if keystate[key] ~= self.keys[key] then
      if keystate[key] then 
        gui.keypressed(self,key)
      else
        gui.keyreleased(self,key)
      end
    end
  end
end

function gui.keypressed(self,key)
  self.keys[key]=true
end

function gui.keyreleased(self,key)
  self.keys[key]=false
  if key=="buttonA" then gui.menuHandleChoice(self) end
  if key=="up" then gui.menuSelectPrevious(self) end
  if key=="down" then gui.menuSelectNext(self) end
  if key=="buttonB" then gui.menuHandleBack(self) end
end

-- Draws menu items one below the other. If menu has a window, 
-- the menu items will be offset by window.offset which defaults to 50.
-- Keep that in mind when you specify the window size.
function gui.menuDraw(self)
  if self.visible then
    local offset=0
    local x=self.x
    local y=self.y
    if self.windowed then 
      -- if showing a window, then we need to offset text and draw the window
      offset=self.offset
      gui.window(x,y,self.w,self.h)
    end
    -- crosshair(x,y,1,0,0,1)
    x=x+offset
    y=y+offset
    if self.font~=nil then love.graphics.setFont(self.font) end
    local color=self.normalColor
    if self.title~=nil then
      love.graphics.setColor(color:components())
      love.graphics.print(self.title,x,y)
      y=y+self.fontHeight+self.fontHeight/2
    end
    for k,v in pairs(self.options) do
      color=self.normalColor
      if k==self.selectedIndex then color=self.selectedColor end
      love.graphics.setColor(color:components())
      love.graphics.print(v,x,y)
      y=y+self.fontHeight
    end
  end
end

function gui.menuSelectPrevious(self)
  self.selectedIndex=self.selectedIndex-1
  if self.selectedIndex<1 then 
    self.selectedIndex=#self.options
  end
end

function gui.menuSelectNext(self)
  self.selectedIndex=self.selectedIndex+1
  if self.selectedIndex>#self.options then 
    self.selectedIndex=1
  end
end

function gui.menuHandleChoice(self)
  if self.handleSelect~=nil then 
    local index=self.selectedIndex
    local text=self.options[index]
    self:handleSelect() 
  end
end

function gui.menuHandleBack(self)
  if self.handleBack~=nil then 
    local index=self.selectedIndex
    local text=self.options[index]
    self:handleBack() 
  end
end
  

-- Draws a cyan/greenish neon bordered window with a rounded radious of 20 if not specified.
-- Neon is only on inside.
function gui.window(wx,wy,ww,wh,radius)
  local red,green,blue=3/255,251/255,255/255
  local xs=wx
  local ys=wy
  local ws=ww
  local hs=wh
  local r=20
  local r2=20
  if radius~=nil then r=radius ; r2=radius end
  local alphaStart=0.25
  local alphaStop=0.0
  local steps=20
  local alphaStep=-((alphaStart-alphaStop)/steps)
  local x,y,w,h=xs,ys,ws,hs

  love.graphics.setColor(red,green,blue,0.15)
  love.graphics.rectangle("fill",x,y,w,h,r2,r2)
  
  -- inside
  for i=alphaStart,alphaStop,alphaStep do
    love.graphics.setColor(red,green,blue,i)
    love.graphics.rectangle("line",x,y,w,h,r,r)
    x=x+1
    y=y+1
    w=w-2
    h=h-2
  end
  
  -- bright border
  x,y,w,h=xs,ys,ws,hs
  love.graphics.setColor(red,green,blue,1)
  love.graphics.rectangle("line",x,y,w,h,r2,r2)
  x=x+1
  y=y+1
  w=w-2
  h=h-2
  love.graphics.rectangle("line",x,y,w,h,r2,r2)
  x=x+1
  y=y+1
  w=w-2
  h=h-2
end

return gui
