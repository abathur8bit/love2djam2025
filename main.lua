io.stdout:setvbuf("no")
flux = require "lib.flux"
gui = require "lib.gui"
require "conf"

gameTitle = "Love Jam 2025 Game"
aspect=0.5625
love.window.setTitle(gameTitle)
flags = {}
flags.fullscreen=fullscreen
flags.borderless=false
if fullscreen then flags.borderless=true end
flags.fullscreentype="desktop"
 flags.display=2

love.window.setMode(resolution,resolution*aspect,flags) 
love.graphics.scale(2,2)

screenWidth = love.graphics.getWidth()
screenHeight = love.graphics.getHeight()

fontSheets = {
  large={filename="assets/wolf-font-sheet-large.png",font=nil},
  normal={filename="assets/wolf-font-sheet.png",font=nil},
  small={filename="assets/wolf-font-sheet-small.png",font=nil}
}
fontCharacters =  "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~ "
fontNormalColor=gui.createColor(1,0,0)
fontSelectedColor=gui.createColor(1,1,0)
logoImage=love.graphics.newImage("assets/coder8bit.png")
logo = {x=screenWidth-logoImage:getWidth(),y=screenHeight,image=logoImage}

gameModes = {title=1,playing=2,dead=3,winner=4}
currentMode=gameModes.title
waitForKeyUp=false

-- music and sound
music = {
--  title={filename="assets/title.mp3",music=nil},
--  ingame={filename="assets/ingame.mp3",music=nil},
}
local sfx = {
--  explode={filename="assets/playerexplode.wav",sfx=nil}
}


activeMenu = nil
menuMain = {}

-- Bring in the logo and other title parts after title is displayed
function titleTweenComplete()
  flux.to(startText,0.5,{x=screenWidth/2,y=y1})
  flux.to(instructionText,0.5,{x=screenWidth/2,y=y2}):oncomplete(
    function() flux.to(logo,0.75,{x=logo.x,y=screenHeight-logo.image:getHeight()-10}):ease("elasticout") end)
end

function love.load(args)
  keystate={up=false,down=false,left=false,right=false,fire=false,thrust=false,buttonA=false,buttonB=false,buttonMenu=false,buttonView=false}

  -- only load sound and music if we are not in a browser
  if inbrowser==false then
    for key,sfxInfo in pairs(sfx) do
      sfxInfo.sfx=love.audio.newSource(sfxInfo.filename,"static")
    end
    for key,musicInfo in pairs(music) do
      print("loading music "..musicInfo.filename)
      musicInfo.music=love.audio.newSource(musicInfo.filename,"static")
      musicInfo.music:setLooping(true)
    end
--    music.title.music:play()
  end
  
  -- load fonts listed in fontsheets
  for key,fontInfo in pairs(fontSheets) do
    fontInfo.font=love.graphics.newImageFont(fontInfo.filename,fontCharacters)
  end
  
  
  local joysticks = love.joystick.getJoysticks()
  joystick = joysticks[1]
  
  love.graphics.setLineStyle("rough");

  local y1=screenHeight/2-fontSheets.small.font:getHeight()/2
  local y2=y1+fontSheets.small.font:getHeight()
  local offset=3
  titleText = {x=screenWidth,y=0,text=gameTitle,font=fontSheets.large.font}
  creditText = {x=screenWidth+30,y=titleText.y+titleText.font:getHeight()+offset+50,
    text="A game by Coder8Bit\n"..
      "Vince\n"..
      "Dr. Tunes\n"..
      "OneSmallGhost",
    font=fontSheets.small.font}
  startText = {x=-1000,y=y1,text="Press Escape to start",font=fontSheets.small.font}
  instructionText = {x=-1400,y=y2,text="Controls",font=fontSheets.small.font}
  
  flux.to(titleText,0.5,{x=10,y=10}):oncomplete(titleTweenComplete)
  flux.to(creditText,0.5,{x=10,y=titleText.y+titleText.font:getHeight()+offset})
  
  -- Sample menu
  local x = screenWidth/2-150
  local y = screenHeight/2-100
  local w = 250
  local h = 300
  local menuWindowed=false
  menuMain = gui.createMenu(
    nil,
    {"Play","Options","Quit"},
    x,y,w,h,menuWindowed,
    fontNormalColor,fontSelectedColor,
    handleMenuMain,nil,
    fontSheets.normal.font)
  menuOptions = gui.createMenu(
    nil,
    {"One","Two","Back"},
    x,y,w,h,menuWindowed,
    fontNormalColor,fontSelectedColor,
    handleMenuOptions,handleMenuOptionsBack,
    fontSheets.normal.font)
end

function handleMenuMain(menu) 
  local index=menu.selectedIndex
  local text=menu.options[index]
--  print("handle menu called with menu",index,text)
  if text=="Quit" then
    love.event.quit() -- user selected quit
  elseif index==2 then
    activeMenu=menuOptions
  elseif index==1 then
    activeMenu=nil  --close menu
    currentMode=gameModes.playing
  end
end

function handleMenuOptions(menu)
  local index=menu.selectedIndex
  local text=menu.options[index]
  if index==3 then 
    activeMenu=menuMain 
  else 
    activeMenu=nil 
  end --close menu
end

function handleMenuOptionsBack(menu) 
  local index=menu.selectedIndex
  local text=menu.options[index]
  print("handle back called with menu",index,text)
  activeMenu=menuMain
end

function love.keypressed(key)
  print("key pressed ",key)
  if key == "escape" then 
    if activeMenu==nil then
      activeMenu=menuMain 
    else
      activeMenu=nil  --close menu
    end
  end
end

function love.update(dt)
  flux.update(dt)
  
  for key in pairs(keystate) do keystate[key] = false end   -- set all keys to not pressed
  if joystick~=nil then
    local hat=joystick:getHat(1)
    if hat=="l" then keystate.left=true end
    if hat=="r" then keystate.right=true end
    if hat=="u" then keystate.up=true end
    if hat=="d" then keystate.down=true end
    
    if joystick:isDown(1) then keystate.buttonA=true end
    if joystick:isDown(2) then keystate.buttonB=true end
    if joystick:isDown(8) then keystate.buttonMenu=true end
      if activeMenu==nil then
        activeMenu=menuMain 
      else
        activeMenu=nil  --close menu
      end
    end
  end
  
  if love.keyboard.isDown("a") or love.keyboard.isDown("left") then keystate.left=true end
  if love.keyboard.isDown("d") or love.keyboard.isDown("right") then keystate.right=true end
  if love.keyboard.isDown("w") or love.keyboard.isDown("up") then keystate.up=true end
  if love.keyboard.isDown("s") or love.keyboard.isDown("down") then keystate.down=true end
  if love.keyboard.isDown("space") or love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") or love.keyboard.isDown("return") then 
    keystate.buttonA=true 
  end
  
  if activeMenu ~= nil then
--    activeMenu:update(dt)
    activeMenu:keystate(keystate)
  else 
    if currentMode==gameModes.playing then 
        -- some play logic
    end
  end
end

function love.draw()
  if activeMenu ~= nil then
      local red,green,blue=22/255,103/255,194/255 -- a dark cyan
      love.graphics.clear(red,green,blue,1)
    activeMenu:draw()
  elseif currentMode==gameModes.title then
    drawTitle()
  else
      love.graphics.setFont(fontSheets.large.font)
      love.graphics.setColor(fontNormalColor:components())
      gui.centerText("Impressive gameplay",screenWidth/2,screenHeight/2)
  end
end

function drawTitle() 
  local x,y=titleText.x,titleText.y
  local fontLarge = fontSheets.large
  local fontSmall = fontSheets.small
  love.graphics.setColor(fontNormalColor:components())
--  love.graphics.line(screenWidth/2,0,screenWidth/2,screenHeight)
--  love.graphics.line(0,screenHeight/2,screenWidth,screenHeight/2)
  love.graphics.setFont(titleText.font)
  love.graphics.print(titleText.text,titleText.x,titleText.y)
  y=y+fontLarge.font:getHeight()
  love.graphics.setFont(creditText.font)
  love.graphics.print(creditText.text,creditText.x,creditText.y)
  
  x,y=screenWidth/2,screenHeight/2
  gui.centerText(startText.text,startText.x,startText.y)
  gui.centerText(instructionText.text,instructionText.x,instructionText.y)
  love.graphics.setColor(1,1,1,1)
  x=10
  love.graphics.draw(logo.image,logo.x,logo.y)
end