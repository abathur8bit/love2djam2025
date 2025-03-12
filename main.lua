io.stdout:setvbuf("no")
flux = require "lib.flux"
require "lib.gui"
require "conf"

gameTitle = "Love Jam 2025 Game"
aspect=0.5625
love.window.setTitle(gameTitle)
flags={}
flags.fullscreen=fullscreen
flags.borderless=false
if fullscreen then flags.borderless=true end
flags.fullscreentype="desktop"
-- flags.display=2

love.window.setMode(resolution,resolution*aspect,flags) 
love.graphics.scale(2,2)

screenWidth=love.graphics.getWidth()
screenHeight=love.graphics.getHeight()

fontSheets = {
  large={filename="assets/wolf-font-sheet-large.png",font=nil},
  normal={filename="assets/wolf-font-sheet.png",font=nil},
  small={filename="assets/wolf-font-sheet-small.png",font=nil}
}
fontCharacters =  "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~ "
fontNormalColor=createColor(1,0,0)
fontSelectedColor=createColor(1,1,0)
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


-- Bring in the logo and other title parts after title is displayed
function titleTweenComplete()
  flux.to(startText,0.5,{x=screenWidth/2,y=y1})
  flux.to(instructionText,0.5,{x=screenWidth/2,y=y2}):oncomplete(
    function() flux.to(logo,0.75,{x=logo.x,y=screenHeight-logo.image:getHeight()-10}):ease("elasticout") end)
end

function love.load(args)
  keystate={up=false,down=false,left=false,right=false,fire=false}

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
      "Erferro",
    font=fontSheets.small.font}
  startText = {x=-1000,y=y1,text="Press Fire to start",font=fontSheets.small.font}
  instructionText = {x=-1400,y=y2,text="Controls",font=fontSheets.small.font}
  
  flux.to(titleText,0.5,{x=10,y=10}):oncomplete(titleTweenComplete)
  flux.to(creditText,0.5,{x=10,y=titleText.y+titleText.font:getHeight()+offset})
end


function love.keypressed(key)
  if key == "escape" then love.event.quit() end
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
    
    if joystick:isDown(1) then keystate.fire=true end
    if joystick:isDown(2) then keystate.thrust=true end
  end
  
  if love.keyboard.isDown("a") or love.keyboard.isDown("left") then keystate.left=true end
  if love.keyboard.isDown("d") or love.keyboard.isDown("right") then keystate.right=true end
  if love.keyboard.isDown("w") or love.keyboard.isDown("up") then keystate.thrust=true end
  if love.keyboard.isDown("space") or love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then 
    keystate.fire=true 
  end
  
    if currentMode==gameModes.playing then 
      -- some play logic
  else
    keydown=false
    if waitForKeyUp then
      for key in pairs(keystate) do  
        if keystate[key]==true then keydown=true end
      end
    end
    if keydown==false then
      waitForKeyUp=false
      for key in pairs(keystate) do 
        if keystate[key]==true then 
          if currentMode==gameModes.title then
            currentMode=gameModes.playing
          end
        end 
      end
    end
  end
end

function love.draw()
  if currentMode==gameModes.title then
    drawTitle()
  else
    love.graphics.setFont(fontSheets.large.font)
    love.graphics.setColor(fontNormalColor)
    centerText(screenWidth/2,screenHeight/2,"Impressive gameplay")
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
  centerText(startText.x,startText.y,startText.text)
  centerText(instructionText.x,instructionText.y,instructionText.text)
  love.graphics.setColor(1,1,1,1)
  x=10
  love.graphics.draw(logo.image,logo.x,logo.y)
end