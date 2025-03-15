io.stdout:setvbuf("no")
local sti  = require "lib.sti"
local Camera = require 'lib.camera'
local anim8 = require 'lib.anim8'
local windfield = require "lib.windfield"
local flux = require "lib.flux"
local gui = require "lib.gui"

require "conf"
version = {x=0,y=-100,text="a.b"}
if buildVersion~=nil then version.text=buildVersion end

gameTitle = "Bad Wizard"
  
aspect=0.5625
love.window.setTitle(gameTitle)
flags = {}
flags.fullscreen=fullscreen
flags.borderless=false
if fullscreen then flags.borderless=true end
if fullscreen then flags.borderless=true end
flags.fullscreentype="desktop"
flags.display=2

love.window.setMode(resolution,resolution*aspect,flags) 
love.graphics.scale(2,2)
--love.window.setPosition(2400,462,1)

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
  title={filename="assets/Intro.mp3",music=nil},
  ingame={filename="assets/Room 1 Idle.mp3",music=nil},
  combat={filename="assets/Room 1 Combat.mp3",music=nil},
}
local sfx = {
  footsteps={filename="assets/Footsteps.ogg",sfx=nil}
}


activeMenu = nil
mainMenu = {}

local map
local cam = Camera()
local world

-- Bring in the logo and other title parts after title is displayed
function titleTweenComplete()
  flux.to(startText,0.5,{x=screenWidth/2,y=y1})
  flux.to(instructionText,0.5,{x=screenWidth/2,y=y2}):oncomplete(
    function() flux.to(logo,0.75,{x=logo.x,y=screenHeight-logo.image:getHeight()-10}):ease("elasticout") end)
end

function loadCharacter() 
  char={}
  
  char.score=0
  char.idleTimer=0.0
  char.idleTimerDelay=5
  char.sheet=love.graphics.newImage("assets/Wizardsprites.png")
  char.grid=anim8.newGrid(96,96,char.sheet:getWidth(),char.sheet:getHeight())
  char.animType="walk"
  char.direction="downright"
  char.keyPressed=false
  char.x=screenWidth/2
  char.y=screenHeight/2
  char.w=96
  char.h=96
  char.scale=1
  char.speed=300
  
  char.anims={}
  
  char.anims.idle={}
  char.anims.idle.up        = anim8.newAnimation(char.grid(21,1),0.15)
  char.anims.idle.down      = anim8.newAnimation(char.grid(17,1),0.15)
  char.anims.idle.right     = anim8.newAnimation(char.grid(29,1),0.15)
  char.anims.idle.left      = anim8.newAnimation(char.grid(25,1),0.15)
  char.anims.idle.upleft    = anim8.newAnimation(char.grid(13,1),0.15)
  char.anims.idle.upright   = anim8.newAnimation(char.grid(9,1),0.15)
  char.anims.idle.downright = anim8.newAnimation(char.grid(1,1),0.15)
  char.anims.idle.downleft  = anim8.newAnimation(char.grid(5,1),0.15)
  
  char.anims.walk={}
  char.anims.walk.up        = anim8.newAnimation(char.grid('21-24',1),0.15)
  char.anims.walk.down      = anim8.newAnimation(char.grid('17-20',1),0.15)
  char.anims.walk.right     = anim8.newAnimation(char.grid('29-32',1),0.15)
  char.anims.walk.left      = anim8.newAnimation(char.grid('25-28',1),0.15)
  char.anims.walk.upleft    = anim8.newAnimation(char.grid('13-16',1),0.15)
  char.anims.walk.upright   = anim8.newAnimation(char.grid('9-12',1),0.15)
  char.anims.walk.downright = anim8.newAnimation(char.grid('1-4',1),0.15)
  char.anims.walk.downleft  = anim8.newAnimation(char.grid('5-8',1),0.15)
end

function loadMonster()
  monster={}
  
  monster.idleTimer=0.0
  monster.idleTimerDelay=5
  monster.sheet=love.graphics.newImage("assets/helmet.png")
  monster.grid=anim8.newGrid(64,64,monster.sheet:getWidth(),monster.sheet:getHeight())
  monster.animType="walk"
  monster.direction="right"
  monster.direction="right"
  monster.keyPressed=false
  monster.x=screenWidth/2+100
  monster.y=screenHeight/2+128
  monster.w=64
  monster.h=64
  monster.scale=1
  monster.speed=300
  
  monster.anims={}
  
  monster.anims.idle={}
  monster.anims.idle.up        = anim8.newAnimation(monster.grid(1,1),0.15)
  monster.anims.idle.down      = anim8.newAnimation(monster.grid(1,1),0.15)
  monster.anims.idle.right     = anim8.newAnimation(monster.grid(1,1),0.15)
  monster.anims.idle.left      = anim8.newAnimation(monster.grid(1,1),0.15)
  monster.anims.idle.upleft    = anim8.newAnimation(monster.grid(1,1),0.15)
  monster.anims.idle.upright   = anim8.newAnimation(monster.grid(1,1),0.15)
  monster.anims.idle.downright = anim8.newAnimation(monster.grid(1,1),0.15)
  monster.anims.idle.downleft  = anim8.newAnimation(monster.grid(1,1),0.15)
  
  monster.anims.walk={}
  monster.anims.walk.up        = anim8.newAnimation(monster.grid('1-8',1),0.15)
  monster.anims.walk.down      = anim8.newAnimation(monster.grid('1-8',1),0.15)
  monster.anims.walk.right     = anim8.newAnimation(monster.grid('1-8',1),0.15)
  monster.anims.walk.left      = anim8.newAnimation(monster.grid('1-8',1),0.15)
  monster.anims.walk.upleft    = anim8.newAnimation(monster.grid('1-8',1),0.15)
  monster.anims.walk.upright   = anim8.newAnimation(monster.grid('1-8',1),0.15)
  monster.anims.walk.downright = anim8.newAnimation(monster.grid('1-8',1),0.15)
  monster.anims.walk.downleft  = anim8.newAnimation(monster.grid('1-8',1),0.15)
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
    music.title.music:play()
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
      "Dr. Tune\n"..
      "Afterlite",
    font=fontSheets.small.font}
  startText = {x=-1000,y=y1,text="Press Escape to start",font=fontSheets.small.font}
  instructionText = {x=-1400,y=y2,text="Use your arrow keys",font=fontSheets.small.font}
  
  flux.to(titleText,0.5,{x=10,y=10}):oncomplete(titleTweenComplete)
  flux.to(creditText,0.5,{x=10,y=titleText.y+titleText.font:getHeight()+offset})
  flux.to(version,0.5,{x=0,y=screenHeight-fontSheets.small.font:getHeight()})
  
  -- Sample menu
  local x = screenWidth/2-150
  local y = screenHeight/2-100
  local w = 250
  local h = 300
  local menuWindowed=false
  mainMenu = gui.createMenu(
    nil,
    {"Play","Options","Quit"},
    x,y,w,h,menuWindowed,
    fontNormalColor,fontSelectedColor,
    handlemainMenu,nil,
    fontSheets.normal.font)
  menuOptions = gui.createMenu(
    nil,
    {"One","Two","Back"},
    x,y,w,h,menuWindowed,
    fontNormalColor,fontSelectedColor,
    handleMenuOptions,handleMenuOptionsBack,
    fontSheets.normal.font)
  
  loadCharacter()
  loadMonster()
  world = windfield.newWorld(0,0,true)
	map = sti("maps/map-67.lua")

	-- Print version and other info
	print("STI          : " .. sti._VERSION)
	print("Map          : " .. map.tiledversion)
  print("Window Width : " .. love.graphics.getWidth())
  print("Window Height: " .. love.graphics.getHeight())

  char.collider=world:newBSGRectangleCollider(char.x,char.y,32,64,8)
  char.collider:setFixedRotation(true)
  
  walls = {}
  local xoff,yoff=0,0
  if map.layers["walls"].objects then
    for i,obj in pairs(map.layers["walls"].objects) do
      print("wall at ",obj.id,obj.x,obj.y,obj.width,obj.height)
      
      local wall = world:newRectangleCollider(obj.x+xoff,obj.y+yoff,obj.width,obj.height)
      wall:setType("static")
      table.insert(walls,wall)
    end
  end
end

function handlemainMenu(menu) 
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
    music.title.music:stop()
    music.ingame.music:play()
  end
end

function handleMenuOptions(menu)
  local index=menu.selectedIndex
  local text=menu.options[index]
  if index==3 then 
    activeMenu=mainMenu 
  else 
    activeMenu=nil 
  end --close menu
end

function handleMenuOptionsBack(menu) 
  local index=menu.selectedIndex
  local text=menu.options[index]
  activeMenu=mainMenu
end

function love.keypressed(key)
  if key == "escape" then 
    if activeMenu==nil then
      activeMenu=mainMenu 
    else
      activeMenu=nil  --close menu
    end
  end
end

function love.update(dt)
  flux.update(dt)
  processInput(dt)
  char.keypressed=false
  if keystate.up and keystate.left then
    char.keypressed=true
    char.direction="upleft"
  elseif keystate.up and keystate.right then
    char.keypressed=true
    char.direction="upright"
  elseif keystate.down and keystate.left then
    char.keypressed=true
    char.direction="downleft"
  elseif keystate.down and keystate.right then
    char.keypressed=true
    char.direction="downright"
  elseif keystate.up then
    char.keypressed=true
    char.direction="up"
  elseif keystate.down then
    char.keypressed=true
    char.direction="down"
  elseif keystate.left then
    char.keypressed=true
    char.direction="left"
  elseif keystate.right then
    char.keypressed=true
    char.direction="right"
  end
  
  if char.keypressed then 
    char.animType="walk" 
    sfx.footsteps.sfx:play()
  else 
    char.animType="idle"
    sfx.footsteps.sfx:stop()
  end
  char.current=char.anims[char.animType][char.direction]
  char.current:update(dt)
  monster.current=monster.anims[monster.animType][monster.direction]
  monster.current:update(dt)
  
  local vx=0
  local vy=0
  if char.keypressed == true then
    if char.direction=="up" then 
      vy=char.speed*-1
    elseif char.direction=="down" then
      vy=char.speed
    elseif char.direction=="right" then
      vx=char.speed
    elseif char.direction=="left" then
      vx=char.speed*-1
    elseif char.direction=="upleft" then 
      vx=char.speed*-1
      vy=char.speed*-1
    elseif char.direction=="upright" then
      vx=char.speed
      vy=char.speed*-1
    elseif char.direction=="downright" then
      vx=char.speed
      vy=char.speed
    elseif char.direction=="downleft" then
      vx=char.speed*-1
      vy=char.speed
    end
  end
  
  char.collider:setLinearVelocity(vx,vy)
  
  --restrict player position, look at player, and keep entire map visible
  local mw = map.width * map.tilewidth
  local mh = map.height * map.tileheight
  
  if char.x-char.w/2 < 0 then char.x = char.w/2 end
  if char.y-char.h/2 < 0 then char.y = char.h/2 end
  if char.x+char.w/2 > mw then char.x = mw-char.w/2 end
  if char.y+char.h/2 > mh then char.y = mh-char.h/2 end
  
  cam:lookAt(char.x,char.y)
  --keep entire map visible to camera
  if cam.x < screenWidth/2 then cam.x = screenWidth/2 end
  if cam.y < screenHeight/2 then cam.y = screenHeight/2 end
  if cam.x > mw-screenWidth/2 then cam.x = mw-screenWidth/2 end
  if cam.y > mh-screenHeight/2 then cam.y = mh-screenHeight/2 end
  
  world:update(dt)
  char.x = char.collider:getX()
  char.y = char.collider:getY()  
  
  char.score=char.score+1
  char.score=char.score+1
end

function processInput(dt)
  for key in pairs(keystate) do keystate[key] = false end   -- set all keys to not pressed
  
  if joystick~=nil then
    local hat=joystick:getHat(1)
    if hat=="l" then keystate.left=true end
    if hat=="r" then keystate.right=true end
    if hat=="u" then keystate.up=true end
    if hat=="d" then keystate.down=true end
    
    if joystick:isDown(1) then keystate.buttonA=true end
    if joystick:isDown(2) then keystate.buttonB=true end
    if joystick:isDown(8) then 
      keystate.buttonMenu=true 
      if activeMenu==nil then
        activeMenu=mainMenu 
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
--    if currentMode==gameModes.playing then 
--        -- some play logic
--    end
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
    drawGame()
  end
end

function drawGame()
  cam:attach()
    local panelWidth=400
    local panelHeight=screenHeight
    local offset=-(panelWidth/2)
    love.graphics.setColor(1, 1, 1)
    map:drawLayer(map.layers["ground"])
    map:drawLayer(map.layers["coloring"])
    map:drawLayer(map.layers["decorations"])
    love.graphics.setColor(1,1,0,1)
    char.current:draw(char.sheet,char.x,char.y,nil,char.scale,char.scale,offset)
    monster.current:draw(monster.sheet,monster.x,monster.y,nil,monster.scale,monster.scale,offset)
  cam:detach()
  drawSidePanel(panelWidth,panelHeight)
end

function drawSidePanel(w,h)
  local offset=20
  local panelColor=gui.createColor255(85,0,85)
  local fontColor=gui.createColor255(153,229,80)
  love.graphics.setColor(panelColor:components())
  love.graphics.rectangle("fill",0,0,w,h)
  
  love.graphics.setColor(fontColor:components())
  love.graphics.setFont(fontSheets.large.font)
  love.graphics.print(gameTitle,6,6)
  local y=fontSheets.large.font:getHeight()+offset+offset
  local panelHeight=155
  drawPlayerPanel(1,0,y,w,panelHeight,fontColor)
  y=y+panelHeight+offset
  drawPlayerPanel(2,0,y,w,panelHeight,fontColor)
end

function drawPlayerPanel(playerNumber,x,y,w,h,fontColor)
  love.graphics.setColor(1,1,1,0.1)
  love.graphics.rectangle("fill",x,y,w,h)
  local offset=5
  y=y+offset
  x=x+offset
  w=w-offset*2
  h=h-offset*2
  
  local score=char.score -- TODO use real player score
  local health=char.score/4 -- TODO use real player health
  local font=fontSheets.normal.font
  
  love.graphics.setColor(fontColor:components())
  love.graphics.setFont(font)
  gui.centerText(string.format("PLAYER %d",playerNumber),x+w/2,y,false)
  y=y+font:getHeight()
  love.graphics.print("SCORE",x,y)
  gui.rightText("HEALTH",x+w,y)
  y=y+font:getHeight()
  love.graphics.print(string.format("%07d",score),x,y)
  gui.rightText(string.format("%04d",health),x+w,y)
  
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
  drawVersion()
end

function drawVersion() 
  love.graphics.setColor(fontNormalColor:components())
  love.graphics.setFont(fontSheets.small.font)
  love.graphics.print("v"..version.text,version.x,version.y)
end