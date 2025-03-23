io.stdout:setvbuf("no")
for a in pairs(arg) do print("a="..a) end

local HC=require "lib.HC"
local Camera=require "lib.camera"
local anim8=require "lib.anim8"
local windfield=require "lib.windfield"
local flux=require "lib.flux"
local gui=require "lib.gui"

require "world"
require "player"
require "bullet"
require "monster"
require "powerup"
require "door"
require "conf"
require "playerpanel"

version={x=0,y=-100,text="a.b"}
if buildVersion~=nil then version.text=buildVersion end

gameTitle="Bad Wizard"
startMap="map-01"
  
aspect=0.5625
love.window.setTitle(gameTitle)
flags={}
flags.fullscreen=fullscreen
flags.borderless=false
if fullscreen then flags.borderless=true end
if fullscreen then flags.borderless=true end
flags.fullscreentype="desktop"
flags.display=1

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
fontCharacters= "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~ "
fontNormalColor=gui.createColor(1,0,0)
fontSelectedColor=gui.createColor(1,1,0)
logoImage=love.graphics.newImage("assets/coder8bit.png")
logo={x=screenWidth-logoImage:getWidth(),y=screenHeight,image=logoImage}

gameModes={title=1,playing=2,dead=3,betweenLevels=4,winner=5}

-- music and sound
music={
  title={filename="assets/Intro.mp3",music=nil},
  ingame={filename="assets/Room 1 Idle.mp3",music=nil},
  combat={filename="assets/Room 1 Combat.mp3",music=nil},
}
sfx={
  shoot={filename="assets/Weapon Swing.ogg",sfx=nil},
  hitWall={filename="assets/HitWall.ogg",sfx=nil},
  hitMonster={filename="assets/Player Death.ogg",sfx=nil},
  monsterHitPlayer={filename="assets/EnemyDamaged.ogg",sfx=nil},
  killPlayer={filename="assets/Player Death.ogg",sfx=nil},
  killMonster={filename="assets/EnemyDamaged.ogg",sfx=nil},
  doorOpen={filename="assets/Door Open.ogg",sfx=nil},
  footsteps={filename="assets/Footsteps.ogg",sfx=nil},
  pickupPowerup={filename="assets/Power-up Equip.ogg",sfx=nil},
  usePowerupAsHealth={filename="assets/Item Equip.ogg",sfx=nil},
  usePowerupAsPower={filename="assets/playerexplode.wav",sfx=nil},
  exitFloor={filename="assets/ExitFloor.ogg",sfx=nil},

  menuHighlightChange=   {filename="assets/MenuHighlightChange.ogg",sfx=nil},
  menuSelectConfirm=     {filename="assets/MenuSelectConfirm.ogg",sfx=nil},
  menuBack=              {filename="assets/MenuBack.ogg",sfx=nil},
  menuOpen=              {filename="assets/MenuOpen.ogg",sfx=nil}
}


menuOptions=nil
activeMenu=nil
mainMenu={}

local world 
local cam=Camera()
local sidePanelWidth=400
local playerPanelHeight=155
local currentGameMode=gameModes.title
local transitionTimer=0
local mapToLoad=nil
local nextLevelNumber=1
local waitForKeyUp=false
local numPlayers=1
if soundOkay==nil then soundOkay=true end
if musicOkay==nil then musicOkay=true end
local options={debug=true,showExtras=false,collideWalls=true,sound=soundOkay,music=musicOkay}
local currentPlayer=1
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
    if love.mouse.isDown(1) then
      local distance=96/2-5 -- a little away from the edge of the player
      local x=player.x
      local y=player.y
      local mx, my = cam:worldCoords(love.mouse.getPosition())
      local angle = math.atan2(my - player.y, mx - player.x)+1.57080
      local dx=math.sin(angle)*distance
      local dy=-math.cos(angle)*distance
      world:addShape(createBullet(world,player,x+dx,y+dy,angle,player.color))
    else
      local distance=96/2-5 -- a little away from the edge of the player
      local x=player.x
      local y=player.y
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
      print("loading sound "..sfxInfo.filename)
      sfxInfo.sfx=love.audio.newSource(sfxInfo.filename,"static")
    end
    for key,musicInfo in pairs(music) do
      print("loading music "..musicInfo.filename)
      musicInfo.music=love.audio.newSource(musicInfo.filename,"static")
      musicInfo.music:setLooping(true)
    end
    playMusic(music.title)
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
    handleMainMenu,nil,
    fontSheets.medium.font)
  menuOptions=gui.createMenu(
    nil,
    {"Back"},
    x,y,w,h,menuWindowed,
    fontNormalColor,fontSelectedColor,
    handleOptionsMenu,handleOptionsMenuBack,
    fontSheets.medium.font)

	-- Print version and other info
  print("Window Width : " .. love.graphics.getWidth())
  print("Window Height: " .. love.graphics.getHeight())

  world=createWorld(screenWidth,screenHeight)
  world:loadMap(startMap)
  local px,py=findPlayerSpawnPoint(world.map)
  if px==nil then
    px=screenWidth/2
    py=screenHeight/2
  end

  world:addPlayer (createPlayer (world,1,px,py,96,96,"assets/Player 1 Wizardsprites-sheet.png"))
  world:addMonster(createMonster(world,1,px+000,py+100,64,64,"assets/helmet.png","monster1","basic"))
  createObjects(world.map)
end

function createObjects(map)
  createWalls(map)
  createTriggers(map)
  createPowerups(map)
  createExits(map)
  world:addVisibility()
  world:addPathfinder()
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

function handleMainMenu(menu) 
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
    currentGameMode=gameModes.playing
      stopMusic(music.title)
      playMusic(music.ingame)
  end
end

function updateOptionMenuItems()
  menuOptions.options={}
  for key,value in pairs(options) do
    local menuText=key..": "..(value==true and "yes" or "no")
    table.insert(menuOptions.options,menuText)
  end
  table.insert(menuOptions.options,"Back")
end

function handleOptionsMenu(menu)
  local index=menu.selectedIndex
  local text=menu.options[index]
  if text=="Back" then
    activeMenu=mainMenu
    return
  end

  -- map the keys to an index so we can utilize the selected index
  local keys={}
  local i=1
  for key in pairs(options) do
    keys[i]=key
    i=i+1
  end
  local selectedKey=keys[index]
  if options[selectedKey]==true then
    options[selectedKey]=false
  else 
    options[selectedKey]=true
  end

  if options.music==false then
    for key,musicInfo in pairs(music) do
      love.audio.stop(musicInfo.music)
    end
  end
  updateOptionMenuItems()

end

function handleOptionsMenuBack(menu) 
  local index=menu.selectedIndex
  local text=menu.options[index]
  activeMenu=mainMenu
end

function love.keypressed(key)
  if key == "escape" then 
    if activeMenu==nil then
      playSfx(sfx.menuOpen)
      activeMenu=mainMenu 
    else
      activeMenu=nil  --close menu
      playSfx(sfx.menuBack)
    end
  end
  if (key=="1" or key=="2") and currentGameMode==gameModes.playing then
    world.players[currentPlayer]:usePowerup(key)
  end
  -- TODO lee remove after testing
  if key=="m" then
    world:addMonster(createMonster(world,1,world.players[currentPlayer].x+000,world.players[currentPlayer].y+100,64,64,"assets/helmet.png","monster1","basic_ranger"))
  end

end

function love.update(dt)
  flux.update(dt)
  if currentGameMode==gameModes.betweenLevels then
    transitionTimer=transitionTimer-dt
    if transitionTimer<=0 then
      loadLevel(mapToLoad)
      currentGameMode=gameModes.playing
    end
  else
    processInput()
    if currentGameMode==gameModes.playing and activeMenu==nil then
      checkCollisions(world.map)
      world:update(dt)
      handlePlayerCameraMovement(world.map, dt)
      if world.players[currentPlayer].firing then
        fireBullet(world.players[currentPlayer],dt)
      end

      -- TODO remove when real score is ready
      world.players[currentPlayer].health=world.players[currentPlayer].health-0.01
      if world.players[currentPlayer].health<1 then world.players[currentPlayer].health=INITIAL_PLAYER_HEALTH end
      -- TODO remove when real score is ready
    end
  end
end

function handlePlayerCameraMovement(map, dt)
  --restrict player position, look at player, and keep entire map visible
  local mw=map.width * map.tilewidth
  local mh=map.height * map.tileheight
  
  if world.players[currentPlayer].x-world.players[currentPlayer].w/2 < 0  then world.players[currentPlayer].x=   world.players[currentPlayer].w/2 end
  if world.players[currentPlayer].y-world.players[currentPlayer].h/2 < 0  then world.players[currentPlayer].y=   world.players[currentPlayer].h/2 end
  if world.players[currentPlayer].x+world.players[currentPlayer].w/2 > mw then world.players[currentPlayer].x=mw-world.players[currentPlayer].w/2 end
  if world.players[currentPlayer].y+world.players[currentPlayer].h/2 > mh then world.players[currentPlayer].y=mh-world.players[currentPlayer].h/2 end
  
  cam:lookAt(world.players[currentPlayer].x,world.players[currentPlayer].y)
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
  checkPlayerCollisions(map)
  checkBulletCollisions(map)
end

function checkPlayerCollisions(map)
  local player=world.players[currentPlayer]
  player.color=gui.createColor(1,1,1)
  for shape, delta in pairs(world.collider:collisions(player.hitbox.collider)) do
    local hitbox=world.hitboxes[shape]
    -- print("collision with hitbox id,name,active,type",hitbox.id,hitbox.name,hitbox.active,hitbox.type)
    if hitbox~=nil and hitbox.active==true then
      local hitboxName,hitboxNumber=parseNameNumber(hitbox.name)
      local number=hitboxNumber --using hitboxNumber in for loop seems to go out of scope, or assigning to local var
      if hitbox.type=="wall" or hitbox.type=="door" then
        -- print("collision with wall or door hitbox id,name,active,type,name,number",hitbox.id,hitbox.name,hitbox.active,hitbox.type,hitboxName,number)
        if options.collideWalls then
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
  playSfx(sfx.monsterHitPlayer)
end

function handleBulletHitMonster(bullet,targetHitbox)
  local monster=targetHitbox.object
  print("bullet hit a monster damage health",bullet.damage,monster.health)
  monster.health=monster.health-bullet.damage
  if monster.health<=0 then
    world:removeHitbox(targetHitbox)
    world:removeShapeWithHitbox(targetHitbox)
    world.players[currentPlayer].score=world.players[currentPlayer].score+10
  end
  world:removeHitbox(bullet.hitbox)
  world:removeShape(bullet)
  playSfx(sfx.hitMonster)
end

function handleBulletHitWall(sourceShape,targetHitbox)
  world:removeHitbox(sourceShape.hitbox)
  world:removeShape(sourceShape)
  print("bullet hit a wall sourceHitbox destHitbox",sourceShape.hitbox.type,targetHitbox.type)
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
  local player=world.players[currentPlayer]
  world:loadMap(mapName)
  local px,py=findPlayerSpawnPoint(world.map)
  if px==nil then
    px=screenWidth/2
    py=screenHeight/2
  end
  player.x=px
  player.y=py
  world:addPlayer (player)
  world:addMonster(createMonster(world,1,px+000,py+100,64,64,"assets/helmet.png","monster1","basic"))
  createObjects(world.map)
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
  local player=world.players[currentPlayer]
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
  if activeMenu ~= nil then
    local red,green,blue=22/255,103/255,194/255 -- a dark cyan
    love.graphics.clear(red,green,blue,1)
    activeMenu:draw()
  elseif currentGameMode==gameModes.title then
    drawTitle()
  elseif currentGameMode==gameModes.betweenLevels then
    drawTransition()
  else
    drawGame()
  end
  if options.showExtras then
    gui.crosshair(screenWidth/2,screenHeight/2,1,0,0,1,true)
  end
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
  local player=world.players[currentPlayer]
  love.graphics.setColor(1, 1, 1)
  cam:attach()
    world:draw()
    if options.showExtras then
      gui.crosshair(player.x,player.y,player.color:components())
      drawTriggers(world.map)
    end
    drawTarget(player,cam:worldCoords(love.mouse.getPosition()))
  cam:detach()
  drawPlayerInfo(player)
end

-- draw the mouse target
function drawTarget(player,x,y)
  local r=15
  love.graphics.setColor(1,1,1,0.5)
  if options.showExtras then 
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
  if inbrowser==false and options.sound==true then
    media.sfx:stop()
  end
end

function playSfx(media)
  if inbrowser==false and options.sound==true then
    media.sfx:stop()  -- if it's already playing stop it
    media.sfx:play()  -- play the sfx
  end
end

function stopMusic(media)
  if inbrowser==false and options.music==true then
    media.music:stop()
  end
end

function playMusic(media)
  if inbrowser==false and options.music==true then
    media.music:stop()
    media.music:play()
    media.music:setVolume(0.5)
  end
end

