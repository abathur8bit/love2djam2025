io.stdout:setvbuf("no")
local sti=require "lib.sti"
local Camera=require 'lib.camera'
local anim8=require 'lib.anim8'
local windfield=require "lib.windfield"
local flux=require "lib.flux"
local gui=require "lib.gui"
local player

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
local sfx={
  footsteps={filename="assets/Footsteps.ogg",sfx=nil}
}


menuOptions=nil
activeMenu=nil
mainMenu={}

local map
local cam=Camera()
local sidePanelWidth=400
local playerPanelHeight=155
local currentMode=gameModes.title
local waitForKeyUp=false
local numPlayers=1
local options={debug=true,showCrosshairs=true,showCamera=true}
local players={}
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

function loadCharacter() 
  char={}
  
  char.x=screenWidth/2
  char.y=screenHeight/2
  char.w=96
  char.h=96
  char.scale=1
  char.color=gui.createColor(1,1,1)
  char.score=0
  char.idleTimer=0.0
  char.idleTimerDelay=5
  char.sheet=love.graphics.newImage("assets/Player 1 Wizardsprites-sheet.png")
  char.grid=anim8.newGrid(char.w,char.h,char.sheet:getWidth(),char.sheet:getHeight())
  char.animType="walk"
  char.direction="downright"
  char.keyPressed=false
  char.speed=300
  char.fireRate=0.2
  char.fireRateTimer=char.fireRate
  
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
  
  monster.x=screenWidth/2+100
  monster.y=screenHeight/2+128
  monster.w=64
  monster.h=64
  monster.idleTimer=0.0
  monster.idleTimerDelay=5
  monster.sheet=love.graphics.newImage("assets/helmet.png")
  monster.grid=anim8.newGrid(monster.w,monster.w,monster.sheet:getWidth(),monster.sheet:getHeight())
  monster.animType="walk"
  monster.direction="right"
  monster.direction="right"
  monster.keyPressed=false
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
  monster.anims.walk.up        = anim8.newAnimation(monster.grid('1-4',1),0.15)
  monster.anims.walk.down      = anim8.newAnimation(monster.grid('1-4',1),0.15)
  monster.anims.walk.right     = anim8.newAnimation(monster.grid('1-4',1),0.15)
  monster.anims.walk.left      = anim8.newAnimation(monster.grid('1-4',1),0.15)
  monster.anims.walk.upleft    = anim8.newAnimation(monster.grid('1-4',1),0.15)
  monster.anims.walk.upright   = anim8.newAnimation(monster.grid('1-4',1),0.15)
  monster.anims.walk.downright = anim8.newAnimation(monster.grid('1-4',1),0.15)
  monster.anims.walk.downleft  = anim8.newAnimation(monster.grid('1-4',1),0.15)
end

function fireBullet(player,dt) 
  if (player.fireRateTimer>player.fireRate or player.fireRateTimer==-1) then
    if inbrowser==false then
      sfx.fire:stop()
      sfx.fire:play()
    end
    
    player.fireRateTimer=0
  end
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
    {"Show Crosshairs","Show Camera","Back"},
    x,y,w,h,menuWindowed,
    fontNormalColor,fontSelectedColor,
    handleMenuOptions,handleMenuOptionsBack,
    fontSheets.normal.font)
  
  loadCharacter()
  loadMonster()
	map=sti("maps/map-67.lua")

	-- Print version and other info
	print("STI          : " .. sti._VERSION)
	print("Map          : " .. map.tiledversion)
  print("Window Width : " .. love.graphics.getWidth())
  print("Window Height: " .. love.graphics.getHeight())

  
  local xoff,yoff=0,0
  if map.layers["walls"].objects then
    for i,obj in pairs(map.layers["walls"].objects) do
      print("wall at ",obj.id,obj.x,obj.y,obj.width,obj.height)
      
      -- TODO collison 
--      local wall=world:newRectangleCollider(obj.x+xoff,obj.y+yoff,obj.width,obj.height)
--      table.insert(walls,wall)
    end
  end
  if map.layers["triggers"].objects then
    for i,obj in pairs(map.layers["triggers"].objects) do
      print("trigger at ",obj.id,obj.x,obj.y,obj.width,obj.height,obj.name)
      
--      local wall=world:newRectangleCollider(obj.x+xoff,obj.y+yoff,obj.width,obj.height)
--      wall:setType("kinematic")
--      table.insert(walls,wall)
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
  local crosshairOption="Show Crosshairs: "
  local cameraOption="Show Camera: "
  if options.showCrosshairs then 
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
    if options.showCrosshairs then 
      options.showCrosshairs=false
    else
      options.showCrosshairs=true
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
    if inbrowser==false then
      sfx.footsteps.sfx:play()
      if music.ingame.music:isPlaying() then
        local musicPos=music.ingame.music:tell("seconds")
        music.ingame.music:stop()
        music.combat.music:seek(musicPos)
        music.combat.music:play()
      end
    end
  else 
    char.animType="idle"
    if inbrowser==false then
      sfx.footsteps.sfx:stop()
      if music.combat.music:isPlaying() then
        local musicPos=music.combat.music:tell("seconds")
        music.combat.music:stop()
        music.ingame.music:seek(musicPos,"seconds")
        music.ingame.music:play()
      end
    end
  end
  char.current=char.anims[char.animType][char.direction]
  char.current:update(dt)
  monster.current=monster.anims[monster.animType][monster.direction]
  monster.current:update(dt)
  
  local vx=0
  local vy=0
  if char.keypressed == true then
    if char.direction=="up" then 
      char.y=char.y-char.speed*dt
    elseif char.direction=="down" then
      char.y=char.y+char.speed*dt
    elseif char.direction=="right" then
      char.x=char.x+char.speed*dt
    elseif char.direction=="left" then
      char.x=char.x-char.speed*dt
    elseif char.direction=="upleft" then 
      char.x=char.x-char.speed*dt
      char.y=char.y-char.speed*dt
    elseif char.direction=="upright" then
      char.x=char.x+char.speed*dt
      char.y=char.y-char.speed*dt
    elseif char.direction=="downright" then
      char.x=char.x+char.speed*dt
      char.y=char.y+char.speed*dt
    elseif char.direction=="downleft" then
      char.x=char.x-char.speed*dt
      char.y=char.y+char.speed*dt
    end
  end
  
  
  --restrict player position, look at player, and keep entire map visible
  local mw=map.width * map.tilewidth
  local mh=map.height * map.tileheight
  
  if char.x-char.w/2 < 0 then char.x=char.w/2 end
  if char.y-char.h/2 < 0 then char.y=char.h/2 end
  if char.x+char.w/2 > mw then char.x=mw-char.w/2 end
  if char.y+char.h/2 > mh then char.y=mh-char.h/2 end
  
  cam:lookAt(char.x,char.y)
  --keep entire map visible to camera
--  if cam.x < screenWidth/2 then cam.x=screenWidth/2 end
--  if cam.y < screenHeight/2 then cam.y=screenHeight/2 end
--  if cam.x > mw-screenWidth/2 then cam.x=mw-screenWidth/2 end
--  if cam.y > mh-screenHeight/2 then cam.y=mh-screenHeight/2 end
  if cam.x<sidePanelWidth then cam.x=sidePanelWidth end
  if cam.y < screenHeight/2 then cam.y=screenHeight/2 end
  if cam.x > mw-screenWidth/2 then cam.x=mw-screenWidth/2 end
  if cam.y > mh-screenHeight/2 then cam.y=mh-screenHeight/2 end
  
  checkTriggers()
  
  char.score=char.score+1   -- TODO remove when real score is ready
end


function checkTriggers()
  char.color=gui.createColor(1,1,1)
  for i,obj in pairs(map.layers["triggers"].objects) do
    if checkRect(char.x-char.w/2,char.y-char.h/2,char.w,char.h,obj.x,obj.y,obj.width,obj.height) then
      if string.find(obj.name,"door") then
        char.color=gui.createColor(0,1,0)
        local doorNum = parseDoorNumber(obj.name)
        local tx,ty=map:convertPixelToTile(obj.x,obj.y)
        local tx,ty=map:convertPixelToTile(obj.x,obj.y)
        print("found tile at ",tx,ty,obj.id)
        map:setLayerTile("ground",tx,ty,13)
--        openWalls(doorNum)
      else
        char.color=gui.createColor(1,0,0)
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

function processInput(dt)
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
  if options.showCrosshairs then
    gui.crosshair(screenWidth/2,screenHeight/2,1,0,0,1,true)
    gui.crosshair(sidePanelWidth+(screenWidth-sidePanelWidth)/2,screenHeight/2,1,1,1,1,true)
  end
end

-- draw the game, like the player, monsters, map, etc
function drawGame()
  cam:attach()
    love.graphics.setColor(1, 1, 1)
    map:drawLayer(map.layers["ground"])
    map:drawLayer(map.layers["coloring"])
    map:drawLayer(map.layers["decorations"])
    love.graphics.setColor(1,1,1,1) -- no coloring of sprites
    char.current:draw(char.sheet,char.x,char.y,nil,char.scale,char.scale,char.w/2,char.h/2)
    monster.current:draw(monster.sheet,monster.x,monster.y,nil,monster.scale,monster.scale)
    if options.showCrosshairs then
      gui.crosshair(char.x,char.y,char.color:components())
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
  love.graphics.rectangle("line",char.x-char.w/2,char.y-char.h/2,char.w,char.h)
  
end

function drawCamera()
  love.graphics.setFont(fontSheets.small.font)
  love.graphics.setColor(1,1,1,1)
  love.graphics.print(string.format("camera %dx%d",cam.x,cam.y),10,screenHeight-love.graphics.getFont():getHeight())
  
          local tx,ty=map:convertPixelToTile(char.x,char.y)
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