io.stdout:setvbuf("no")
package.path=package.path..";../?.lua;../?/init.lua;../lib/?.lua;../lib/?/init.lua"

local math=math
local love=love
local HC=require "lib.HC"
local Camera=require "lib.camera"
local anim8=require "lib.anim8"
local flux=require "lib.flux"
local gui=require "lib.gui"
local axjoy=require "lib.axjoystick"
local axmath=require "lib.axmath"

require "world"
require "player"
require "bullet"
require "monster"
require "powerup"
require "door"
require "conf"
require "playerpanel"
require "generator"
require "playerselect"

math.randomseed(os.time())
math.random() math.random() math.random()

version={x=0,y=-100,text="a.b"}
if buildVersion~=nil then version.text=buildVersion end

gameTitle="Bad Wizard"
startMap="circuit-01"

local instructions={
  keyboard={start="Press Escape to start",playAgain="Press Escape to try again",filename="assets/instructionsKeyboard.png",image=nil},
  joystick={start="Plress A to start",playAgain="Press A to try again",filename="assets/instructionsJoystick.png",image=nil}
}
local startWithKeyboard="Press Escape to start"
local startWithJoystick="Press A on your controller to start\n"..
                        "or press Start to bring up the menu."

aspect=0.5625
-- aspect=0.79365079365079365079365079365079  --aspect for itch.io screen shots
love.window.setTitle(gameTitle)
flags={}
flags.fullscreen=fullscreen
flags.borderless=false
if fullscreen then flags.borderless=true end
if fullscreen then flags.borderless=true end
flags.fullscreentype="desktop"
if not release then flags.display=2 end

love.window.setMode(resolution,resolution*aspect,flags) 
love.graphics.scale(2,2)
--love.window.setPosition(2400,462,1)

screenWidth=love.graphics.getWidth()
screenHeight=love.graphics.getHeight()

fontSheets={
  large={filename="assets/wolf-font-sheet-large.png",font=nil},
  medium={filename="assets/wolf-font-sheet.png",font=nil},
  small={filename="assets/wolf-font-sheet-small.png",font=nil}
}
playerSheets={
  {filename="assets/Player 1 Wizardsprites-sheet.png",width=96,height=96},
  {filename="assets/Player 2 Wizardsprites-sheet.png",width=96,height=96},
  {filename="assets/Player 3 Wizardsprites-sheet.png",width=96,height=96},
  {filename="assets/Player 4 Wizardsprites-sheet.png",width=96,height=96},
}
fontCharacters= "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~ "
fontNormalColor=gui.createColor(1,0,0)
fontSelectedColor=gui.createColor(1,1,0)
logoImage=love.graphics.newImage("assets/coder8bit.png")
logo={x=screenWidth-logoImage:getWidth(),y=screenHeight,image=logoImage}
local degreeTable=axmath.degreeTable(5)

gameModes={title=1,playing=2,dead=3,betweenLevels=4,winner=5,help=6,playerSelect=7}

-- music and sound
musicLevels={
  "assets/Room 1 (Alt Idle).mp3",
  "assets/Room 3 (Alt Idle).mp3",
  "assets/Room 5 (Alt Idle).mp3",
  "assets/Room 7 (Alt Idle).mp3",
  "assets/Room 9 (Alt Idle).mp3"
}

music={
  title={filename="assets/Intro.mp3",music=nil,loop=false},
  ingame={filename="assets/Room 1 (Alt Idle).mp3",music=nil,loop=true},
  -- combat={filename="assets/Room 1 (Alt Idle).mp3",music=nil},
}
sfx={
  shoot={filename="assets/Weapon Swing.ogg",sfx=nil},
  hitWall={filename="assets/HitWall.ogg",sfx=nil},
  hitMonster={filename="assets/EnemyDamaged.ogg",sfx=nil},
  monsterHitPlayer={filename="assets/EnemyDamaged.ogg",sfx=nil},
  killPlayer={filename="assets/Player Death.ogg",sfx=nil},
  killMonster={filename="assets/EnemyKilled.ogg",sfx=nil},
  doorOpen={filename="assets/Door Open.ogg",sfx=nil},
  footsteps={filename="assets/Footsteps.ogg",sfx=nil},
  pickupPowerup={filename="assets/Power-up Equip.ogg",sfx=nil},
  usePowerupAsHealth={filename="assets/Item Equip.ogg",sfx=nil},
  usePowerupAsPower={filename="assets/playerexplode.wav",sfx=nil},
  exitFloor={filename="assets/ExitFloor.ogg",sfx=nil},
  monsterMeleePlayer={filename="assets/Melee.ogg",sfx=nil},
  endGame={filename="assets/Victory.ogg",sfx=nil},

  menuHighlightChange=   {filename="assets/MenuHighlightChange.ogg",sfx=nil},
  menuSelectConfirm=     {filename="assets/MenuSelectConfirm.ogg",sfx=nil},
  menuBack=              {filename="assets/MenuBack.ogg",sfx=nil},
  menuOpen=              {filename="assets/MenuOpen.ogg",sfx=nil}
}


optionsMenu=nil
activeMenu=nil
mainMenu={}

world={}
local cam=Camera()
sidePanelWidth=400
playerPanelHeight=155
local currentGameMode=gameModes.title
local transitionTimer=0
local mapToLoad=nil
local nextLevelNumber=1
local waitForKeyUp=false
numPlayers=1
numReady=0
confirmedPlayers={false,false,false,false}
joystate={}
if musicOkay==nil then musicOkay=true end  -- optionally defined in conf
local options={
  music={name="Music",visible=true,active=musicOkay},
  sound={name="Sound",visible=true,active=true},
  showExtras={name="Show Extras",visible=true,active=false},
  collideWalls={name="Wall Collision",visible=true,active=true},
  -- collision={name="Collision Detection",visible=true,active=false},
}

local currentPlayer=1
local players={
  createPlayer(nil,1,0,0,playerSheets[1].width,playerSheets[1].height,playerSheets[1].filename),
  createPlayer(nil,2,0,0,playerSheets[2].width,playerSheets[2].height,playerSheets[2].filename),
  createPlayer(nil,3,0,0,playerSheets[3].width,playerSheets[3].height,playerSheets[3].filename),
  createPlayer(nil,4,0,0,playerSheets[4].width,playerSheets[4].height,playerSheets[4].filename)
}

-- where players spawn
local entery={x=-1,y=-1}
-- rectangle that if touched, will exit the level
local exit={x=-1,y=-1,w=0,h=0}
-- when player steps on door, all walls of the same number are removed from the world
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
    stopSfx(sfx.shoot)
    playSfx(sfx.shoot)
    
    player.fireRateTimer=0
    local distance=96/2-5 -- a little away from the edge of the player
    local x=player.x
    local y=player.y
    if player.joystate then
      local dx=player.joystate.vxright*distance
      local dy=player.joystate.vyright*distance
      world:addShape(createBullet(world,player,x+dx,y+dy,player.joystate.rightAngle,player.color))
    elseif love.mouse.isDown(1) then
      local mx, my = cam:worldCoords(love.mouse.getPosition())
      local angle = math.atan2(my - player.y, mx - player.x)+1.57080
      local dx=math.sin(angle)*distance
      local dy=-math.cos(angle)*distance
      world:addShape(createBullet(world,player,x+dx,y+dy,angle,player.color))
    else
      local angle=player.angle
      local dx=math.sin(angle)*distance
      local dy=-math.cos(angle)*distance
      world:addShape(createBullet(world,player,x+dx,y+dy,angle,player.color))
    end
  end
end

function love.load(args)
  keystate={up=false,down=false,left=false,right=false,fire=false,thrust=false,buttonA=false,buttonB=false,buttonMenu=false,buttonView=false}
  
  -- only load sound and music if we are not in a browser
  if inbrowser==false then
    for key,sfxInfo in pairs(sfx) do
      -- print("loading sound "..sfxInfo.filename)
      sfxInfo.sfx=love.audio.newSource(sfxInfo.filename,"static")
    end
    for key,musicInfo in pairs(music) do
      -- print("loading music filename,loop"..musicInfo.filename,musicInfo.loop)
      musicInfo.music=love.audio.newSource(musicInfo.filename,"static")
      musicInfo.music:setLooping(musicInfo.loop)
    end
    playMusic(music.title)
  end
  
  -- load fonts listed in fontsheets
  for key,fontInfo in pairs(fontSheets) do
    fontInfo.font=love.graphics.newImageFont(fontInfo.filename,fontCharacters)
  end
  
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
  startText={x=-1000,y=y1,text=startWithKeyboard,font=fontSheets.small.font}
  instructionText={x=-1400,y=y2,text="",font=fontSheets.small.font}

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
    "MAIN",
    {"Play","Help","Options","Quit"},
    x,y,w,h,menuWindowed,
    fontNormalColor,fontSelectedColor,
    handleMainMenu,handleMainMenuBack,
    fontSheets.medium.font,fontSheets.large.font)
  optionsMenu=gui.createMenu(
    "OPTIONS",
    buildOptionsMenu,
    x,y,w,h,false,
    fontNormalColor,fontSelectedColor,
    handleOptionsMenu,handleOptionsMenuBack,
    fontSheets.medium.font,fontSheets.large.font)
end

function createObjects(map)
  createWalls(map)
  createTriggers(map)
  createPowerups(map)
  createExits(map)
  createGenerators(map)
  world:addVisibility()
  world:addPathfinder()
end

function createGenerators(map)
  if map.layers["generators"] then
    local count=0
    for _,generator in pairs(map.layers["generators"].objects) do
      if generator.name=="generator" then
        count=count+1
        local spawnRate=generator.properties.spawnrate or 3
        print(" generatorat x,y,w,h,spawnRate",generator.id,generator.x,generator.y,generator.width,generator.height,spawnRate)
        world:addShape(createGenerator(world,generator.x,generator.y,generator.width,generator.height,spawnRate))
      end
    end
    print(string.format("created %d generators",count))
  end
end

function createPowerups(map)
  if map.layers["powerups"] then
    local count=0
    for _,powerup in pairs(map.layers["powerups"].objects) do
      count=count+1
      print("trigger at x,y,w,h,name",powerup.id,powerup.x,powerup.y,powerup.width,powerup.height,powerup.name)
      if powerup.name=="bean" then
        world:addShape(createPowerup(world,"earth",powerup.x,powerup.y,powerup.width,powerup.height))
      end
    end
    print(string.format("created %d powerups",count))
  end
end

function createWalls(map)
  if map.layers["walls"].objects then
    for i,obj in pairs(map.layers["walls"].objects) do
      print("wall at x,y,w,h",obj.id,obj.x,obj.y,obj.width,obj.height)
      world:createHitbox(obj.x,obj.y,obj.width,obj.height,"wall",obj.id,obj.id,obj)
    end
  end
end

function createTriggers(map)
  if map.layers["triggers"] then
    for _,obj in pairs(map.layers["triggers"].objects) do
      local type="trigger"
      local name,number=parseNameNumber(obj.name)
      if name~=nil and name=="door" then
        local door=createDoor(obj.x,obj.y,obj.width,obj.height,"assets/door.png")
        world:addShape(door)
        world:createHitbox(obj.x,obj.y,obj.width,obj.height,"door",obj.id,obj.name,door)
      else
        print("trigger at id,x,y,w,h,name",obj.id,obj.x,obj.y,obj.width,obj.height,obj.name)
        world:createHitbox(obj.x,obj.y,obj.width,obj.height,type,obj.id,obj.name,obj)
      end
    end
  end
end

-- while there is usually one exit, there is the posibility of multiple exits;
-- For example an exit to level 2 and an exit to level 5.
function createExits(map)
  if map.layers["enter_exit"] then 
    for _,obj in pairs(map.layers["enter_exit"].objects) do
      local type="exit"
      local name,number=parseNameNumber(obj.name)
      if name~=nil and name=="exit" then
        print("exit at id,x,y,w,h,name",obj.id,obj.x,obj.y,obj.width,obj.height,obj.name)
        world:createHitbox(obj.x,obj.y,obj.width,obj.height,type,obj.id,obj.name,obj)
      end
    end
  end
end

-- return x,y that indicates the point players should spawn from
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

function findBossSpawnPoint(map)
  if map.layers["generators"] then
    print("enter exit layer found")
    for _,obj in pairs(map.layers["generators"].objects) do
      if obj.name=="boss_spawn" then
        print("found boss point at ",obj.x,obj.y)
        -- return the center of the spawn point
        return obj.x+obj.width/2,obj.y+obj.height/2
      end
    end
  end
  return nil
end

function handleMainMenu(menu) 
  local index=menu.selectedIndex
  local text=menu.options[index]
--  print("handle menu called with menu",index,text)
  if text=="Quit" then
    love.event.quit() -- user selected quit
  elseif index==3 then
    activeMenu=optionsMenu
  elseif index==2 then
    currentGameMode=gameModes.help
    activeMenu=nil
  elseif index==1 then
    activeMenu=nil  --close menu
    currentGameMode=gameModes.playing
    stopMusic(music.title)
    playMusic(music.ingame)
  end
end

function handleMainMenuBack(menu)
  activeMenu:deactivate(function() activeMenu=nil end)  --close menu
  -- activeMenu=nil
end

function handleOptionsMenu(menu)
  local index=menu.selectedIndex
  local text=menu:getOptions(index)
  print("options menu text",text)
  for key,value in pairs(options) do
    if string.find(text,value.name) then
      if value.active then 
        value.active=false
      else 
        value.active=true
      end
    end
  end
  if options.music.active==false then stopAllMusic() end
end

function handleOptionsMenuBack(menu) 
  activeMenu=mainMenu
end

function love.keypressed(key)
  local player=players[1]
  if activeMenu then
    activeMenu:keypressed(key)
  else
    if currentGameMode==gameModes.title then
      currentGameMode=gameModes.playerSelect
    elseif currentGameMode==gameModes.help then
      activeMenu=mainMenu:activate()
    elseif currentGameMode==gameModes.dead or currentGameMode==gameModes.winner then
      if key == "escape" then
        nextLevelNumber=1
        player:reset()
        currentGameMode=gameModes.playing
        loadLevel(startMap)
      end
    elseif currentGameMode==gameModes.playerSelect then
      playerSelectKeyPressed(players,key)
    else
      if key == "escape" then 
        if activeMenu==nil then
          playSfx(sfx.menuOpen)
          activeMenu=mainMenu:activate()
        else
          activeMenu=nil  --close menu
          playSfx(sfx.menuBack)
        end
      end
      if (key=="1" or key=="2") and currentGameMode==gameModes.playing then
        player:usePowerup(key)
      end
      -- TODO lee remove after testing
      if key=="m" then
        world:addMonster(createMonster(world,1,player.x+000,player.y+100,64,64,"assets/helmet.png","monster1","basic_ranger"))
      end
      if key=="k" then
        player.health=5
      end
    end
  end
end

function love.joystickadded(joystick)
  print("joystick added >",joystick:getName(),"< >",joystick:getID(),"<")
  joystate[joystick]=axjoy.createJoystickState(joystick,joystick:getID())
  startText.text=startWithJoystick
end

function findPlayerJoystickId(id)
  for i=1,4  do
    if players[i].controller==id then return players[i] end
  end
  return nil
end

function love.joystickremoved(joystick)
  print("joystick removed >",joystick:getName(),"< >",joystick:getID(),"<")
  startText.text=startWithKeyboard
end

function love.gamepadpressed(joystick,button)
  print("press button joystick,button",joystick:getName(),button)
  joystate[joystick][button]=true
  if activeMenu then 
    activeMenu:gamepadpressed(joystick,button)
  else
    local player=findPlayerJoystickId(joystick:getID())
    if currentGameMode==gameModes.title then
      currentGameMode=gameModes.playerSelect
    elseif currentGameMode==gameModes.playerSelect then
      playerSelectGamepadPressed(players,joystick,button)
    elseif currentGameMode==gameModes.help then
      currentGameMode=gameModes.playing
      activeMenu=mainMenu
    elseif currentGameMode==gameModes.title then
      if button=="start" then 
        activeMenu=mainMenu 
      elseif button=="a" then
        currentGameMode=gameModes.playing
        stopMusic(music.title)
        playMusic(music.ingame)
      end
    elseif currentGameMode==gameModes.playing then
      if button=="start" then 
        activeMenu=mainMenu 
      elseif button=="leftshoulder" then
        player:usePowerup("1")
      elseif button=="rightshoulder" then
        player:usePowerup("2")
      end
    elseif currentGameMode==gameModes.winner or currentGameMode==gameModes.dead and button=="a" then
      nextLevelNumber=1
      player:reset()
      currentGameMode=gameModes.playing
      loadLevel(startMap)
    end
  end
end

function love.gamepadreleased(joystick,button)
  joystate[joystick][button]=false
  print("release button joystick,button",joystick:getName(),button)
end

function love.gamepadaxis(joystick, axis, value)
  -- print("gamepadaxis axis,value",axis,value)
  joystate[joystick][axis]=value
  if axis=="leftx" or axis=="lefty" then
    joystate[joystick].leftAngle=getJoystickAngle(joystick:getGamepadAxis("leftx"),joystick:getGamepadAxis("lefty"))
    joystate[joystick].vxleft=joystick:getGamepadAxis("leftx")
    joystate[joystick].vyleft=joystick:getGamepadAxis("lefty")
    end
  if axis=="rightx" or axis=="righty" then
    joystate[joystick].rightAngle=getJoystickAngle(joystick:getGamepadAxis("rightx"),joystick:getGamepadAxis("righty"))
    joystate[joystick].vxright=joystick:getGamepadAxis("rightx")
    joystate[joystick].vyright=joystick:getGamepadAxis("righty")
  end

  -- adjust the direction the 8-direction player sprite faces
  local player=findPlayerJoystickId(joystick:getID())
  if player~=nil then
    local deg=math.deg(joystate[joystick].leftAngle)
    if deg>=0 and deg<=20 or deg>=340 then
      player.direction="up"
    elseif deg>=25 and deg<=65 then
      player.direction="upright"
    elseif deg>=70 and deg<=110 then
      player.direction="right"
    elseif deg>=115 and deg<=155 then
      player.direction="downright"
    elseif deg>=160 and deg<=200 then
      player.direction="down"
    elseif deg>=205 and deg<=245 then
      player.direction="downleft"
    elseif deg>=250 and deg<=290 then
      player.direction="left"
    elseif deg>=295 and deg<=335 then
      player.direction="upleft"
    end
  end
end

function getJoystickAngle(jx,jy)
  local angle=(math.atan2(jy,jx)+1.57080) % (2 * math.pi) --adjust by 90 deg and ensure in range of 0 thru 2PI
  local deg=math.deg(angle) --rad2deg
  return math.rad(axmath.snapDegree(deg,degreeTable))
end

function love.update(dt)
  flux.update(dt)
  if currentGameMode==gameModes.playerSelect then
    updatePlayerSelect(players,dt)
  elseif currentGameMode==gameModes.betweenLevels then
    transitionTimer=transitionTimer-dt
    if transitionTimer<=0 then
      loadLevel(mapToLoad)
      currentGameMode=gameModes.playing
      if mapToLoad=="boss" then
        local x,y=findBossSpawnPoint(world.map)
        world:addMonster(createMonster(world,1,x,y,192,192,"assets/kingsprites.png","monster1","boss"))
      end
    end
  elseif currentGameMode==gameModes.dead then
    -- do nothing
  elseif currentGameMode==gameModes.winner then
    -- do nothing
  else
    processInput()
    if currentGameMode==gameModes.playing and activeMenu==nil then
      checkCollisions(world.map)
      world:update(dt)
      handlePlayerCameraMovement(world.map, dt)
      for i=1,4 do
        local player=players[i]
        if isPlayerFiring(player) then
          fireBullet(player,dt)
        end

        player.health=player.health-0.01
        if player.health<=0 then playerDeath() end
      end
    end
  end
end

function isPlayerFiring(player)
  if player.joystate then 
    local vx=player.joystate.vxright
    local vy=player.joystate.vyright
    if math.abs(vx)<0.5 then vx=0 end
    if math.abs(vy)<0.5 then vy=0 end
    if vx~=0 or vy~=0 then
      return true
    end
  elseif player.firing then
    return true 
  end
  return false
end

function handlePlayerCameraMovement(map, dt)
  --restrict player position, look at player, and keep entire map visible
  local mw=map.width * map.tilewidth
  local mh=map.height * map.tileheight
  if players[1].x-players[1].w/2 < 0  then players[1].x=   world.players[1].w/2 end
  if players[1].y-players[1].h/2 < 0  then players[1].y=   world.players[1].h/2 end
  if players[1].x+players[1].w/2 > mw then players[1].x=mw-world.players[1].w/2 end
  if players[1].y+players[1].h/2 > mh then players[1].y=mh-world.players[1].h/2 end
  
  cam:lookAt(players[1].x,players[1].y)
  --keep entire map visible to camera
  if cam.x < screenWidth/2 then cam.x=screenWidth/2 end
  if cam.y < screenHeight/2 then cam.y=screenHeight/2 end
  if cam.x > mw-screenWidth/2 then cam.x=mw-screenWidth/2 end
  if cam.y > mh-screenHeight/2 then cam.y=mh-screenHeight/2 end
  if cam.x<sidePanelWidth then cam.x=sidePanelWidth end
  if cam.y < screenHeight/2 then cam.y=screenHeight/2 end
  if cam.x > mw-screenWidth/2 then cam.x=mw-screenWidth/2 end
  if cam.y > mh-screenHeight/2 then cam.y=mh-screenHeight/2 end
end

function checkCollisions(map)
  checkAllPlayerCollisions(map)
  checkBulletCollisions(map)
end

function checkAllPlayerCollisions(map)
  for i,player in pairs(players) do 
    if player.controller then
      checkCollisionsForPlayer(player) 
    end
  end
end

function checkCollisionsForPlayer(player)
  player.color=gui.createColor(1,1,1)
  for shape, delta in pairs(world.collider:collisions(player.hitbox.collider)) do
    local hitbox=world.hitboxes[shape]
    -- print("collision with hitbox id,name,active,type",hitbox.id,hitbox.name,hitbox.active,hitbox.type)
    if hitbox~=nil and hitbox.active==true then
      local hitboxName,hitboxNumber=parseNameNumber(hitbox.name)
      local number=hitboxNumber --using hitboxNumber in for loop seems to go out of scope, or assigning to local var
      if hitbox.type=="wall" or hitbox.type=="door" then
        -- print("collision with wall or door hitbox id,name,active,type,name,number",hitbox.id,hitbox.name,hitbox.active,hitbox.type,hitboxName,number)
        if options.collideWalls.active then
          -- bump player back as they hit a wall
          player.x=player.x+delta.x
          player.y=player.y+delta.y
        end
      elseif hitbox.type=="exit" then
        local exit=hitbox.object
        print("exit id,name,exit_to",exit.id,exit.name,exit.properties.exit_to)
        dumpTable(exit.properties,"exit properties")
        setTransition(exit.properties.exit_to)
      elseif hitbox.type=="powerup" then
        handlePowerup(hitbox)
      elseif hitbox.type=="trigger" then
        -- print("collision with trigger",hitbox.name)
        if hitboxName~=nil and hitboxName=="key" then
          -- print("collision with key ",hitboxNumber)
          hitbox.active=false
          dumpTable(hitbox,"hitbox")
          for _,door in pairs(world.hitboxes) do
            local doorName,doorNumber=parseNameNumber(door.name)
            -- print("inspecting hitbox id,name,active,doorname,doornumber",door.id,door.name,door.active,doorName,doorNumber)
            if doorName~=nil and doorName=="door" and doorNumber==number then
              print("opening door id,name",door.id,door.name)
              playSfx(sfx.doorOpen)
              door.active=false
              -- world:removeHitbox(door)
              world:removeShape(door.object)

              -- Redo the visibility and pathfinding maps because door is open
              world:addPathfinder()
              world:addVisibility()
            end
          end
        end
      end
    end
  end
end

-- set transition mode and what level to load once the transition timer runs out
function setTransition(map)
  nextLevelNumber=nextLevelNumber+1
  playSfx(sfx.exitFloor)
  currentGameMode=gameModes.betweenLevels
  mapToLoad=map
  transitionTimer=3
end

-- See if bullets are colliding with anything
function checkBulletCollisions(map)
  for i,shape in ipairs(world.shapes) do
    if shape.type=="bullet" then
      for collider, delta in pairs(world.collider:collisions(shape.hitbox.collider)) do
        local hitbox=world.hitboxes[collider]
        local shooter = shape.hitbox.object.shooter
        if hitbox.type=="monster" and shooter.type=='player' then handleBulletHitMonster(shape,hitbox) 
        elseif hitbox.type=='player' and shooter.type=='monster' then handleBulletHitPlayer(shape, hitbox)
        elseif hitbox.type=="wall" or hitbox.type=="door" and hitbox.active then handleBulletHitWall(shape,hitbox)
        end
      end
    end
  end
end

function handleBulletHitPlayer(bullet,targetHitbox)
  local player=targetHitbox.object
  print("bullet hit a player damage health", bullet.damage,player.health)
  player.health=player.health-bullet.damage
  world:removeHitbox(bullet.hitbox)
  world:removeShape(bullet)

  --check if player has died
  if player.health<=0 then
    playerDeath()
  else
    playSfx(sfx.monsterHitPlayer)
  end
end

function playerWin()
  stopMusic(music.ingame)
  playSfx(sfx.endGame)
  currentGameMode=gameModes.winner
end

function playerDeath()
  playSfx(sfx.killPlayer)
  --show game over, score, then wait for a key, load level 1 with player at normal health
  currentGameMode=gameModes.dead
end

function handleBulletHitMonster(bullet,targetHitbox)
  local monster=targetHitbox.object
  print("bullet hit a monster damage health",bullet.damage,monster.health)
  monster.health=monster.health-bullet.damage
  if monster.health<=0 then
    monster:destroy()
    world.players[currentPlayer].score=world.players[currentPlayer].score+10

    -- Boss
    if monster.behaviour == 'boss' then
      world.players[currentPlayer].score=world.players[currentPlayer].score+500
      playerWin()
    end
  end
  world:removeHitbox(bullet.hitbox)
  world:removeShape(bullet)
  playSfx(sfx.hitMonster)
end

function handleBulletHitWall(sourceShape,targetHitbox)
  world:removeHitbox(sourceShape.hitbox)
  world:removeShape(sourceShape)
  playSfx(sfx.hitWall)
end


function handlePowerup(hitbox)
  local player=world.players[currentPlayer]
  if player.powerups<player.maxPowerups then
    world:removeShape(hitbox.object)
    world:removeHitbox(hitbox)
    playSfx(sfx.pickupPowerup)
    player:incPowerups()
  end

  -- TODO player gets the powerup
end

function loadLevel(mapName)
  -- print(string.format("loading level=%s",mapName))
  world=nil
  world=createWorld(screenWidth,screenHeight)
  world:loadMap(mapName)
  local px,py=findPlayerSpawnPoint(world.map)
  for i=1,4 do
    if players[i].controller then
      -- print(string.format("adding player i=%d id=%d",i,players[i].id))
      if px==nil then
        -- if no spawn point in the map, just put in the top left corner of the map
        px=100
        py=100
      end
      players[i].world=world
      players[i].x=px
      players[i].y=py
      world:addPlayer(players[i])
      px=px+players[i].w+5
    end
  end
  createObjects(world.map)
  if inbrowser==false and options.music.active==true then
    stopMusic(music.ingame)
    local filename=musicLevels[nextLevelNumber]
    music.ingame.music=love.audio.newSource(filename,"static")
    music.ingame.music:setLooping(true)
    playMusic(music.ingame)
  end
end

-- parse the name and number from fullName in the form "door-01"
-- name is "door" and number is "01"
-- if there is no number, the fullName is returned.
function parseNameNumber(fullName)
  local i=string.find(fullName,"-")
  if i~=nil then
    name=string.sub(fullName,1,i-1)
    number=string.sub(fullName,i+1)
    return name,number
  end
  return fullName
end

function parseDoorNumber(door)
  local i=string.find(door,"-")
  assert(i,"door name should be like door-01")
  i=i+1
  local n=string.sub(door,i)
  return n
end


function openWalls(doorNum)
  --map:convertPixelToTile (x, y)
  --map:setLayerTile (layer, x, y, gid)
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
  
  -- TODO lee this needs to go, as we process the joystick differently now
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
end

function processInput()
  readInput()
  local player=findPlayerJoystickId(0) 
  if player==nil then return end

  player.keypressed=false
  player.firing=false

  if keystate.up and keystate.left then
    player.keypressed=true
    player.direction="upleft"
  elseif keystate.up and keystate.right then
    player.keypressed=true
    player.direction="upright"
  elseif keystate.down and keystate.left then
    player.keypressed=true
    player.direction="downleft"
  elseif keystate.down and keystate.right then
    player.keypressed=true
    player.direction="downright"
  elseif keystate.up then
    player.keypressed=true
    player.direction="up"
  elseif keystate.down then
    player.keypressed=true
    player.direction="down"
  elseif keystate.left then
    player.keypressed=true
    player.direction="left"
  elseif keystate.right then
    player.keypressed=true
    player.direction="right"
  end
  if keystate.buttonA then
    player.firing=true
  end


  if currentGameMode==gameModes.playing and love.mouse.isDown(1) then player.firing=true end
end

function love.draw()
  if currentGameMode==gameModes.help then
    drawHelp()
  elseif currentGameMode==gameModes.playerSelect then
    drawPlayerSelect(players)
  elseif currentGameMode==gameModes.title then
    drawTitle()
  elseif currentGameMode==gameModes.betweenLevels then
    drawTransition()
  elseif currentGameMode==gameModes.dead then
    drawGameOver()
  elseif currentGameMode==gameModes.winner then
    drawWinner()
  elseif currentGameMode==gameModes.playing then
    drawGame()
  end
  if activeMenu ~= nil then
    activeMenu:draw()
  end
  if options.showExtras.active then
    gui.crosshair(screenWidth/2,screenHeight/2,1,0,0,1,true)
  end
end

function drawHelp()
  love.graphics.setColor(1,0,0,1)
  local player=world.players[currentPlayer]
  local img=nil
  local inst=instructions.keyboard
  if player.joystate then inst=instructions.joystick end
  if inst.image==nil then inst.image=love.graphics.newImage(inst.filename) end
  love.graphics.draw(inst.image,screenWidth/2-inst.image:getWidth()/2,screenHeight/2-inst.image:getHeight()/2)
end

function drawGameOver()
  local red,green,blue=22/255,103/255,194/255 -- a dark cyan
  love.graphics.clear(red,green,blue,1)
  love.graphics.setColor(fontSelectedColor:components())
  love.graphics.setFont(fontSheets.large.font)
  local player=world.players[currentPlayer]
  local height=love.graphics.getFont():getHeight()
  local x=screenWidth/2
  local y=screenHeight/2-height
  gui.centerText("GAME OVER",x,y-height)
  gui.centerText("SCORE: "..player.score,x,y)
  love.graphics.setFont(fontSheets.small.font)
  local text=instructions.keyboard.playAgain
  gui.centerText(text,x,y+height)
end

function drawWinner()
  local red,green,blue=22/255,103/255,194/255 -- a dark cyan
  love.graphics.clear(red,green,blue,1)
  love.graphics.setColor(fontSelectedColor:components())
  love.graphics.setFont(fontSheets.large.font)
  local player=world.players[currentPlayer]
  local height=love.graphics.getFont():getHeight()
  local x=screenWidth/2
  local y=screenHeight/2-height
  gui.centerText("YOU WIN",x,y-height)
  gui.centerText("SCORE: "..player.score,x,y)
  love.graphics.setFont(fontSheets.small.font)
  local text=instructions.keyboard.playAgain
  gui.centerText(text,x,y+height)
end

function drawTransition()
  local red,green,blue=22/255,103/255,194/255 -- a dark cyan
  love.graphics.clear(red,green,blue,1)
  love.graphics.setColor(fontSelectedColor:components())
  love.graphics.setFont(fontSheets.large.font)
  gui.centerText("LEVEL "..nextLevelNumber,screenWidth/2,screenHeight/2)
end

-- draw the game, like the player, monsters, map, etc
function drawGame()
    love.graphics.setColor(1, 1, 1)
    cam:attach()
      world:draw()
      if options.showExtras.active then
        -- gui.crosshair(player.x,player.y,player.color:components())
        drawTriggers(world.map)
      end
      -- if not player.joystate then
        -- drawMouseTarget(player,cam:worldCoords(love.mouse.getPosition()))
      -- end
    cam:detach()
    -- drawPlayerInfo(player)
end

-- draw the mouse target
function drawMouseTarget(player,x,y)
  local r=15
  love.graphics.setColor(1,1,1,0.5)
  if options.showExtras.active then 
    love.graphics.line(player.x,player.y,cam:worldCoords(love.mouse.getPosition()))
  end
  love.graphics.setLineWidth(3)
  love.graphics.circle("line",x,y,r)
  love.graphics.line(x-r,y,x+r,y)
  love.graphics.line(x,y-r,x,y+r)
end

function drawTriggers(map)
  for _,hitbox in pairs(world.hitboxes) do
    if hitbox.active then
      local x1,y1, x2,y2 = hitbox.collider:bbox()
      love.graphics.rectangle('line', x1,y1, x2-x1,y2-y1)
    end
  end
  -- collision box around player
  local p=world.players[currentPlayer]
  local x1,y1, x2,y2 = p.hitbox.collider:bbox()
  love.graphics.rectangle('line', x1,y1, x2-x1,y2-y1)
end

function drawCamera(map)
  love.graphics.setFont(fontSheets.small.font)
  love.graphics.setColor(1,1,1,1)
  local firing="no"
  if world.players[currentPlayer].firing then firing="yes" end
  love.graphics.print(string.format("camera %dx%d player firing %s",cam.x,cam.y,firing),10,screenHeight-love.graphics.getFont():getHeight())
  local tx,ty=map:convertPixelToTile(world.players[currentPlayer].x,world.players[currentPlayer].y)
  local props=map:getTileProperties("ground",1,1)
  for key,value in pairs(props) do print("key value",key,value) end
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
  love.graphics.setFont(fontSheets.medium.font)
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
  local font=fontSheets.medium.font
  
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

function dumpTable(t,name)
  print("dumping table "..name)
  for key,value in pairs(t) do print("key value",key,value) end
end

function stopSfx(media)
  if inbrowser==false and options.sound.active==true then
    media.sfx:stop()
  end
end

function stopAllSound()

end

function playSfx(media)
  if inbrowser==false and options.sound.active==true then
    media.sfx:stop()  -- if it's already playing stop it
    media.sfx:play()  -- play the sfx
  end
end

function stopMusic(media)
  if inbrowser==false and options.music.active==true then
    media.music:stop()
  end
end

function playMusic(media)
  if inbrowser==false and options.music.active==true then
    media.music:stop()
    media.music:play()
    media.music:setVolume(0.5)
  end
end

function stopAllMusic()
  for k,v in pairs(music) do
    v.music:stop()
  end
end


function buildOptionsMenu()
  local items={}
  for key,value in pairs(options) do
    if value.visible then
      local menuText=value.name..": "..(value.active and "yes" or "no")
      table.insert(items,menuText)
    end
  end
  table.sort(items,function(a,b) return a<b end)
  -- for _,name in pairs(items) do print("options menu name",name) end -- show the options
  return items
end

function setGameMode(mode)
  print(string.format("setting game mode to %s, currentGameMode=%s",mode,currentGameMode))
  if mode==gameModes.playing then
    stopAllMusic()
    loadLevel(startMap)
  end
  currentGameMode=mode
end







