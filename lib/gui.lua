local flux=require "lib.flux"
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

-- Convert a hex color like "FFFFFF" to 255,255,255. Also treats "FFF" or "111" as "FFFFFF" or "111111".
function gui.hex2decColor(hex)
  assert(string.len(hex)==3 or string.len(hex)==6,"Hex value must be 3 or 6 characters long")  -- must be in format "FFF" or "FFFFFF"
  if string.len(hex)==6 then
    r=tonumber(string.sub(hex,1,2),16)
    g=tonumber(string.sub(hex,3,4),16)
    b=tonumber(string.sub(hex,5,6),16)
  elseif string.len(hex)==3 then
    r=tonumber(string.sub(hex,1,1)..string.sub(hex,1,1),16)
    g=tonumber(string.sub(hex,2,2)..string.sub(hex,2,2),16)
    b=tonumber(string.sub(hex,3,3)..string.sub(hex,3,3),16)
  end
  return r,g,b
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
function gui.createMenu(title,options,x,y,width,height,windowed,normalColor,selectedColor,handleSelect,handleBack,font,fontLarge)
  if normalColor==nil then normalColor=gui.createColor255(3,251,255) end
  if selectedColor==nil then selectedColor=gui.createColor(1,1,0) end
  if fontLarge==nil then fontLarge=font end
  local w=gui.createWidget(x,y,width,height,"menu")
  w.title=title
  w.options=options
  w.selectedIndex=1 --select the first item
  w.windowed=windowed
  w.offset=50 -- amount to offset the text inside the window
  w.normalColor=normalColor
  w.selectedColor=selectedColor
  w.font=font
  w.fontLarge=fontLarge
  w.fontHeight=font:getHeight()
  w.draw=gui.menuDraw
  w.selectNext=gui.menuSelectNext
  w.selectPrevious=gui.menuSelectPrevious
  w.handle=gui.menuHandleChoice
  w.handleSelect=handleSelect
  w.handleBack=handleBack
  w.mousemoved=gui.menuMouseMoved
  w.keypressed=gui.keypressed         -- user calls
  w.gamepadpressed=gui.gamepadpressed -- user calls
  w.getOptions=gui.getOptions
  w.activate=gui.activate
  w.deactivate=gui.deactivate
  w.update=gui.update
  w.posStart=love.graphics.getWidth()+400
  w.posStop=love.graphics.getWidth()/2+100
  w.x=w.posStop
  w.y=0
  return w
end

function gui.activate(self)
  self.x=self.posStart
  flux.to(self,0.5,{x=self.posStop,y=self.y}):ease("backinout")
  return self
end

function gui.deactivate(self,finished)
  print("deactivate")
  flux.to(self,0.5,{x=self.posStart,y=self.y}):ease("backinout"):oncomplete(finished)
end

function gui.keypressed(self,key)
  if key=="up" then self.selectPrevious(self) end
  if key=="down" then self.selectNext(self) end
  if key=="return" then self.handle(self) end
  if key=="escape" then self.handleBack() end
end

function gui.gamepadpressed(self,joystick,button)
  if button=="dpup" then self.selectPrevious(self) end
  if button=="dpdown" then self.selectNext(self) end
  if button=="a" then self.handle(self) end
  if button=="start" or button=="b" then self:handleBack() end
end

-- Draws menu items one below the other. If menu has a window, 
-- the menu items will be offset by window.offset which defaults to 50.
-- Keep that in mind when you specify the window size.
function gui.menuDraw(self)
  gui.drawMenu2(self)
end

function gui.drawMenu2(self)
  local ydif=5
  local xdif=-(1/5)
  local sw=love.graphics.getWidth()
  local sh=love.graphics.getHeight()
  local w=sw/2
  local h=sh
  local x=self.x
  local y=0
  local offset=200
  local padding=20
  love.graphics.setColor(0,1,1,0.9)
  love.graphics.polygon(
    "fill",
    x,y+h,
    x+offset,0,
    x+w,0,
    x+w-offset,h
    )

    x=x+offset+padding
    y=y+padding
    if self.fontLarge~=nil then love.graphics.setFont(self.fontLarge) end
    local color=self.normalColor
    if self.title~=nil then
      love.graphics.setColor(color:components())
      love.graphics.print(self.title,x,y)
      y=y+self.fontHeight*3
      x=x+(self.fontHeight*3)*xdif
    end
    if self.font~=nil then love.graphics.setFont(self.font) end
    local optionText=gui.getOptions(self)
    x=x-padding
    for k,v in pairs(optionText) do
      color=self.normalColor
      if k==self.selectedIndex then color=self.selectedColor end
      love.graphics.setColor(color:components())
      love.graphics.print(v,x+padding,y)
      y=y+self.fontHeight*2
      x=x+(self.fontHeight*2)*xdif
    end
end

function gui.drawMenu1(self)
  if self.visible then
    local red,green,blue=22/255,103/255,194/255 -- a dark cyan
    love.graphics.clear(red,green,blue,1)
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
    local optionText=gui.getOptions(self)
    for k,v in pairs(optionText) do
      color=self.normalColor
      if k==self.selectedIndex then color=self.selectedColor end
      love.graphics.setColor(color:components())
      love.graphics.print(v,x,y)
      y=y+self.fontHeight
    end
  end
end

function gui.getOptions(self,index)
  local optionText
  if type(self.options)=="function" then
    -- this is a function, so call the function to build the option text values
    optionText=self:options()
  else
    optionText=self.options
  end
  if not index then return optionText end
  return optionText[index]
end

function gui.menuSelectPrevious(self)
  self.selectedIndex=self.selectedIndex-1
  if self.selectedIndex<1 then
    self.selectedIndex=#gui.getOptions(self)
  end
end

function gui.menuSelectNext(self)
  self.selectedIndex=self.selectedIndex+1
  if self.selectedIndex>#gui.getOptions(self) then
    self.selectedIndex=1
  end
end

function gui.menuHandleChoice(self)
  if self.handleSelect then
    local optionsText=gui.getOptions(self)
    local index=self.selectedIndex
    local text=optionsText[index]
    self:handleSelect(index,text)
  end
end

function gui.menuHandleBack(self)
  if self.handleBack~=nil then 
    local optionsText=gui.getOptions(self)
    local index=self.selectedIndex
    local text=optionsText[index]
    self:handleBack(index,text)
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
