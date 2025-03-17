io.stdout:setvbuf("no")
for a in pairs(arg) do print("a="..a) end

-- words for test

local sti=require "lib.sti"
local Camera=require 'lib.camera'
local anim8=require 'lib.anim8'
local windfield=require "lib.windfield"
local flux=require "lib.flux"
local gui=require "lib.gui"

require "world"
require "player"
require "bullet"
require "monster"
require "powerup"
require "conf"

version={x=0,y=-100,text="a.b"}
if buildVersion~=nil then version.text=buildVersion end

gameTitle="Bad Wizard"
  
aspect=0.5625
love.window.setTitle(gameTitle)
flags={}
flags.fullscreen=fullscreen
flags.borderless=false
if fullscreen then flags.borderless=true end
if fullscreen then flags.borderless=true end
flags.fullscreentype="desktop"
flags.display=2

love.window.setMode(resolution,resolution*aspect,flags) 
love.graphics.scale(2,2)
--love.window.setPosition(2400,462,1)

screenWidth=love.graphics.getWidth()
screenHeight=love.graphics.getHeight()

fontSheets={
  large={filename="assets/wolf-font-sheet-large.png",font=nil},
  normal={filename="assets/wolf-font-sheet.png",font=nil},
  small={filename="assets/wolf-font-sheet-small.png",font=nil}
}
fontCharacters= "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~ "
fontNormalColor=gui.createColor(1,0,0)
fontSelectedColor=gui.createColor(1,1,0)
logoImage=love.graphics.newImage("assets/coder8bit.png")
logo={x=screenWidth-logoImage:getWidth(),y=screenHeight,image=logoImage}

gameModes={title=1,playing=2,dead=3,winner=4}

-- music and sound
music={
  title={filename="assets/Intro.mp3",music=nil},
  ingame={filename="assets/Room 1 Idle.mp3",music=nil},
  combat={filename="assets/Room 1 Combat.mp3",music=nil},
}
sfx={
  shoot={filename="assets/shoot.wav",sfx=nil},
  hit={filename="assets/explode.wav",sfx=nil},
  kill={filename="assets/playerexplode.wav",sfx=nil},
  footsteps={filename="assets/Footsteps.ogg",sfx=nil}
}


menuOptions=nil
activeMenu=nil
mainMenu={}

local world 
local map
local cam=Camera()
local sidePanelWidth=400
local playerPanelHeight=155
local currentMode=gameModes.title
local waitForKeyUp=false
local numPlayers=1
local options={debug=true,showExtras=true,showCamera=true}
local currentPlayer=1
-- where players spawn
local entery={x=-1,y=-1}
-- rectangle that if touched, will exit the level
local exit={x=-1,y=-1,w=0,h=0}
-- when player steps on door, all walls of the same number are removed from the ground layer
-- TODO when a ground tile is removed, the wall has to be removed as well
local doors={}
-- what prevents a player from moving through a tile
local walls={}

-- Bring in the logo and other title parts after title is displayed
function titleTweenComplete()
  flux.to(startText,0.5,{x=screenWidth/2,y=y1})
  flux.to(instructionText,0.5,{x=screenWidth/2,y=y2}):oncomplete(
    function() flux.to(logo,0.75,{x=logo.x,y=screenHeight-logo.image:getHeight()-10}):ease("elasticout") end)
end

function fireBullet(player,dt) 
  if (player.fireRateTimer>player.fireRate or player.fireRateTimer==-1) then
    if inbrowser==false then
      sfx.shoot.sfx:stop()
      sfx.shoot.sfx:play()
    end
    
    player.fireRateTimer=0
    local distance=96/2-5 -- a little away from the edge of the player
    local x=player.x
    local y=player.y
    local angle=player.angle
    local dx=math.sin(angle)*distance
    local dy=-math.cos(angle)*distance

    print("bullet ",x,y,dx,dy,angle)
    world:addShape(createBullet(x+dx,y+dy,angle,player.color))
  end
end

function love.load(args)
  keystate={up=false,down=false,left=false,right=false,fire=false,thrust=false,buttonA=false,buttonB=false,buttonMenu=false,buttonView=false}
  
  -- only load sound and music if we are not in a browser
  if inbrowser==false then
    for key,sfxInfo in pairs(sfx) do
      print("loading sound "..sfxInfo.filename)
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
  
  
  local joysticks=love.joystick.getJoysticks()
  joystick=joysticks[1]
  
  love.graphics.setLineStyle("rough");

  local y1=screenHeight/2-fontSheets.small.font:getHeight()/2
  local y2=y1+fontSheets.small.font:getHeight()
  local offset=3
  titleText={x=screenWidth,y=0,text=gameTitle,font=fontSheets.large.font}
  creditText={x=screenWidth+30,y=titleText.y+titleText.font:getHeight()+offset+50,
    text="A game by Coder8Bit\n"..
      "Vince\n"..
      "Dr. Tune\n"..
      "Afterlite",
    font=fontSheets.small.font}
  startText={x=-1000,y=y1,text="Press Escape to start",font=fontSheets.small.font}
  instructionText={x=-1400,y=y2,text="Use your arrow keys",font=fontSheets.small.font}
  
  flux.to(titleText,0.5,{x=10,y=10}):oncomplete(titleTweenComplete)
  flux.to(creditText,0.5,{x=10,y=titleText.y+titleText.font:getHeight()+offset})
  flux.to(version,0.5,{x=0,y=screenHeight-fontSheets.small.font:getHeight()})
  
  -- Sample menu
  local x=screenWidth/2-150
  local y=screenHeight/2-100
  local w=250
  local h=300
  local menuWindowed=false
  mainMenu=gui.createMenu(
    nil,
    {"Play","Options","Quit"},
    x,y,w,h,menuWindowed,
    fontNormalColor,fontSelectedColor,
    handlemainMenu,nil,
    fontSheets.normal.font)
  menuOptions=gui.createMenu(
    nil,
    {"Show Extras","Show Camera","Back"},
    x,y,w,h,menuWindowed,
    fontNormalColor,fontSelectedColor,
    handleMenuOptions,handleMenuOptionsBack,
    fontSheets.normal.font)
  
	map=sti("maps/map-67.lua")

	-- Print version and other info
	print("STI          : " .. sti._VERSION)
	print("Map          : " .. map.tiledversion)
  print("Window Width : " .. love.graphics.getWidth())
  print("Window Height: " .. love.graphics.getHeight())

  local px,py=findPlayerSpawnPoint(map)
  if px==nil then
    px=screenWidth/2
    py=screenHeight/2
  end
  world=createWorld(map.width*map.tilewidth,map.height*map.tileheight,screenWidth,screenHeight)
  world:addPlayer (createPlayer (1,px,py,96,96,"assets/Player 1 Wizardsprites-sheet.png"))
  world:addMonster(createMonster(1,world.players[currentPlayer].x+070,world.players[currentPlayer].y+000,64,64,"assets/helmet.png"))
  world:addMonster(createMonster(1,world.players[currentPlayer].x+140,world.players[currentPlayer].y+000,64,64,"assets/helmet.png"))
  world:addMonster(createMonster(1,world.players[currentPlayer].x+000,world.players[currentPlayer].y+070,64,64,"assets/helmet.png"))
  world:addMonster(createMonster(1,world.players[currentPlayer].x+000,world.players[currentPlayer].y+140,64,64,"assets/helmet.png"))

  findWalls(map)
  findTriggers(map)
  createPowerups(map)
end

function createPowerups(map)
  if map.layers["powerups"].objects then
    print("found powerups")
    for _,powerup in pairs(map.layers["powerups"].objects) do
      if powerup.name=="bean" then
        world:addShape(createPowerup("earth",powerup.x,powerup.y,powerup.width,powerup.height))
      end
    end
  end
end

function findWalls(map)
  local xoff,yoff=0,0
  if map.layers["walls"].objects then
    for i,obj in pairs(map.layers["walls"].objects) do
      -- print("wall at ",obj.id,obj.x,obj.y,obj.width,obj.height)
      
      -- TODO collison 
--      local wall=world:newRectangleCollider(obj.x+xoff,obj.y+yoff,obj.width,obj.height)
--      table.insert(walls,wall)
    end
  end
end

function findTriggers(map)
  local xoff,yoff=0,0
  if map.layers["triggers"].objects then
    for i,obj in pairs(map.layers["triggers"].objects) do
      -- print("trigger at ",obj.id,obj.x,obj.y,obj.width,obj.height,obj.name)
      
--      local wall=world:newRectangleCollider(obj.x+xoff,obj.y+yoff,obj.width,obj.height)
--      wall:setType("kinematic")
--      table.insert(walls,wall)
    end
  end
end

function findPlayerSpawnPoint(map)
  if map.layers["enter_exit"].objects then
    print("enter exit layer found")
    for _,obj in pairs(map.layers["enter_exit"].objects) do
      if obj.name=="enter" then
        print("found enter point at ",obj.x,obj.y)
        -- return the center of the spawn point
        return obj.x+obj.width/2,obj.y+obj.height/2
      end
    end
  end
  return nil
end

function handlemainMenu(menu) 
  local index=menu.selectedIndex
  local text=menu.options[index]
--  print("handle menu called with menu",index,text)
  if text=="Quit" then
    love.event.quit() -- user selected quit
  elseif index==2 then
    updateOptionMenuItems()
    activeMenu=menuOptions
  elseif index==1 then
    activeMenu=nil  --close menu
    currentMode=gameModes.playing
    if inbrowser==false then
      music.title.music:stop()
      music.ingame.music:play()
    end
  end
end

function updateOptionMenuItems() 
  local crosshairOption="Show Extras: "
  local cameraOption="Show Camera: "
  if options.showExtras then 
    crosshairOption=crosshairOption.."Yes"
  else 
    crosshairOption=crosshairOption.."No"
  end
  if options.showCamera then 
    cameraOption=cameraOption.."Yes"
  else 
    cameraOption=cameraOption.."No"
  end
  menuOptions.options = {crosshairOption,cameraOption,"Back"}
end

function handleMenuOptions(menu)
  local index=menu.selectedIndex
  local text=menu.options[index]
  if index==3 then 
    activeMenu=mainMenu 
  elseif index==1 then
    if options.showExtras then 
      options.showExtras=false
    else
      options.showExtras=true
    end
    updateOptionMenuItems()
  elseif index==2 then
    if options.showCamera then
      options.showCamera=false
    else
      options.showCamera=true
    end
    updateOptionMenuItems()
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
  processInput()
  world:update(dt)
  handlePlayerCameraMovement(dt)
  checkTriggers()
  if world.players[currentPlayer].firing then
    fireBullet(world.players[currentPlayer],dt)
  end

  world.players[currentPlayer].score=world.players[currentPlayer].score+1   -- TODO remove when real score is ready
end

function handlePlayerCameraMovement(dt)
  --restrict player position, look at player, and keep entire map visible
  local mw=map.width * map.tilewidth
  local mh=map.height * map.tileheight
  
  if world.players[currentPlayer].x-world.players[currentPlayer].w/2 < 0  then world.players[currentPlayer].x=   world.players[currentPlayer].w/2 end
  if world.players[currentPlayer].y-world.players[currentPlayer].h/2 < 0  then world.players[currentPlayer].y=   world.players[currentPlayer].h/2 end
  if world.players[currentPlayer].x+world.players[currentPlayer].w/2 > mw then world.players[currentPlayer].x=mw-world.players[currentPlayer].w/2 end
  if world.players[currentPlayer].y+world.players[currentPlayer].h/2 > mh then world.players[currentPlayer].y=mh-world.players[currentPlayer].h/2 end
  
  cam:lookAt(world.players[currentPlayer].x,world.players[currentPlayer].y)
  --keep entire map visible to camera
--  if cam.x < screenWidth/2 then cam.x=screenWidth/2 end
--  if cam.y < screenHeight/2 then cam.y=screenHeight/2 end
--  if cam.x > mw-screenWidth/2 then cam.x=mw-screenWidth/2 end
--  if cam.y > mh-screenHeight/2 then cam.y=mh-screenHeight/2 end
  if cam.x<sidePanelWidth then cam.x=sidePanelWidth end
  if cam.y < screenHeight/2 then cam.y=screenHeight/2 end
  if cam.x > mw-screenWidth/2 then cam.x=mw-screenWidth/2 end
  if cam.y > mh-screenHeight/2 then cam.y=mh-screenHeight/2 end
end

function checkTriggers()
  world.players[currentPlayer].color=gui.createColor(1,1,1)
  for i,obj in pairs(map.layers["triggers"].objects) do
    if checkRect(world.players[currentPlayer].x-world.players[currentPlayer].w/2,world.players[currentPlayer].y-world.players[currentPlayer].h/2,world.players[currentPlayer].w,world.players[currentPlayer].h,obj.x,obj.y,obj.width,obj.height) then
      if string.find(obj.name,"door") then
        world.players[currentPlayer].color=gui.createColor(0,1,0)
        local doorNum = parseDoorNumber(obj.name)
        local tx,ty=map:convertPixelToTile(obj.x,obj.y)
        local tx,ty=map:convertPixelToTile(obj.x,obj.y)
        print("found tile at ",tx,ty,obj.id)
        map:setLayerTile("ground",tx,ty,13)
--        openWalls(doorNum)
      else
        world.players[currentPlayer].color=gui.createColor(1,0,0)
      end
    end
  end
end

function parseDoorNumber(door)
  local i=string.find(door,"-")
  assert(i,"door name should be like door-01")
  i=i+1
  local n=string.sub(door,i)
  return n
end

function openWalls(doorNum)
  map:convertPixelToTile (x, y)
  Map:setLayerTile (layer, x, y, gid)
end

function checkRect(x,y,w,h,rx,ry,rw,rh)
  local left1=x
  local right1=x+w
  local top1=y
  local bottom1=y+h
  local left2=rx
  local right2=rx+rw
  local top2=ry
  local bottom2=ry+rh
  
  return left1<right2 and right1 > left2
                      and top1 < bottom2
                      and bottom1 > top2 
end

function readInput(dt)
  for key in pairs(keystate) do keystate[key]=false end   -- set all keys to not pressed
  
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

function processInput()
  readInput()
  world.players[currentPlayer].keypressed=false
  world.players[currentPlayer].firing=false

  if keystate.up and keystate.left then
    world.players[currentPlayer].keypressed=true
    world.players[currentPlayer].direction="upleft"
  elseif keystate.up and keystate.right then
    world.players[currentPlayer].keypressed=true
    world.players[currentPlayer].direction="upright"
  elseif keystate.down and keystate.left then
    world.players[currentPlayer].keypressed=true
    world.players[currentPlayer].direction="downleft"
  elseif keystate.down and keystate.right then
    world.players[currentPlayer].keypressed=true
    world.players[currentPlayer].direction="downright"
  elseif keystate.up then
    world.players[currentPlayer].keypressed=true
    world.players[currentPlayer].direction="up"
  elseif keystate.down then
    world.players[currentPlayer].keypressed=true
    world.players[currentPlayer].direction="down"
  elseif keystate.left then
    world.players[currentPlayer].keypressed=true
    world.players[currentPlayer].direction="left"
  elseif keystate.right then
    world.players[currentPlayer].keypressed=true
    world.players[currentPlayer].direction="right"
  elseif keystate.buttonA then
    world.players[currentPlayer].firing=true
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
  if options.showExtras then
    gui.crosshair(screenWidth/2,screenHeight/2,1,0,0,1,true)
  end
end

-- draw the game, like the player, monsters, map, etc
function drawGame()
  cam:attach()
    love.graphics.setColor(1, 1, 1)
    map:drawLayer(map.layers["ground"])
    map:drawLayer(map.layers["coloring"])
    map:drawLayer(map.layers["decorations"])
    world:draw()
    if options.showExtras then
      gui.crosshair(world.players[currentPlayer].x,world.players[currentPlayer].y,world.players[currentPlayer].color:components())
      drawTriggers()
    end
  cam:detach()
  drawSidePanel(sidePanelWidth,screenHeight)
  if options.showCamera then drawCamera() end
end

function drawTriggers() 
  for i,obj in pairs(map.layers["triggers"].objects) do
    love.graphics.rectangle("line",obj.x,obj.y,obj.width,obj.height)
  end
  love.graphics.rectangle("line",world.players[currentPlayer].x-world.players[currentPlayer].w/2,world.players[currentPlayer].y-world.players[currentPlayer].h/2,world.players[currentPlayer].w,world.players[currentPlayer].h)
end

function drawCamera()
  love.graphics.setFont(fontSheets.small.font)
  love.graphics.setColor(1,1,1,1)
  local firing="no"
  if world.players[currentPlayer].firing then firing="yes" end
  love.graphics.print(string.format("camera %dx%d player firing %s",cam.x,cam.y,firing),10,screenHeight-love.graphics.getFont():getHeight())
  
  local tx,ty=map:convertPixelToTile(world.players[currentPlayer].x,world.players[currentPlayer].y)
  local props=map:getTileProperties("ground",1,1)
  for key,value in pairs(props) do print("key value",key,value) end
--  love.graphics.print("tile id "..
end

-- side panel contains the title, level number, player panels
function drawSidePanel(w,h)
  local offset=20
  local panelColor=gui.createColor255(0,0,0,128)
  local fontColor=gui.createColor255(153,229,80)
  love.graphics.setColor(panelColor:components())
  love.graphics.rectangle("fill",0,0,w,h)
  
  love.graphics.setColor(fontColor:components())
  love.graphics.setFont(fontSheets.large.font)
  love.graphics.print(gameTitle,6,6)
  local y=fontSheets.large.font:getHeight()+offset
  love.graphics.setFont(fontSheets.normal.font)
  gui.centerText(string.format("LEVEL %d",666),w/2,y,false)
  y=y+fontSheets.large.font:getHeight()+offset+offset
  drawPlayerPanel(1,0,y,w,playerPanelHeight,gui.createColor255(153,229,80),gui.createColor255(106,190,48,255))
  y=y+playerPanelHeight+offset
  drawPlayerPanel(2,0,y,w,playerPanelHeight,gui.createColor255(102,225,243),gui.createColor255(43, 125, 199,255))
  y=y+playerPanelHeight+offset
  drawPlayerPanel(3,0,y,w,playerPanelHeight,gui.createColor255(221,229,235),gui.createColor255(145,148,151,255))
  y=y+playerPanelHeight+offset
  drawPlayerPanel(4,0,y,w,playerPanelHeight,gui.createColor255(243,214,18),gui.createColor255(227,120,3,255))
end

-- player panel contains the players score, hp, and power ups
function drawPlayerPanel(playerNumber,x,y,w,h,fontColor,bgColor)
  love.graphics.setColor(bgColor:components())
  love.graphics.rectangle("fill",x,y,w,h)
  local offset=5
  y=y+offset
  x=x+offset
  w=w-offset*2
  h=h-offset*2
  
  local score=world.players[currentPlayer].score -- TODO use real player score
  local health=world.players[currentPlayer].score/4 -- TODO use real player health
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

-- draw the title page
function drawTitle() 
  local x,y=titleText.x,titleText.y
  local fontLarge=fontSheets.large
  local fontSmall=fontSheets.small
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

-- draw just the version number
function drawVersion() 
  love.graphics.setColor(fontNormalColor:components())
  love.graphics.setFont(fontSheets.small.font)
  love.graphics.print("v"..version.text,version.x,version.y)
end