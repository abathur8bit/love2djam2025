local gui=require "lib.gui"

function updatePlayerSelect(players,dt)
  numPlayers=0
  numReady=0

  for i=1,4 do
    if players[i].controller~=nil then numPlayers=numPlayers+1 end
  end
  for i=1,4 do
    if players[i].controller~=nil and confirmedPlayers[i]==true then numReady=numReady+1 end
  end

  if numPlayers>=1 and numPlayers==numReady then
    setGameMode(gameModes.playing)
  end
end

function drawPlayerSelect(players)
  local padding=75
  local w=screenWidth/2
  local h=screenHeight/2
  local x,y=0,0

  love.graphics.setColor(0,0,0,1)
  love.graphics.clear()
  love.graphics.setColor(1,0,0,1)
  love.graphics.setLineWidth(3)

  love.graphics.setFont(fontSheets.large.font)
  gui.centerText(string.format("Player Select"),screenWidth/2,0,false)
  love.graphics.setFont(fontSheets.small.font)

  --player 1
  drawPlayerSelectForPlayer(players[1],x+padding,y+padding,w-padding*2,h-padding*2)
  drawPlayerSelectForPlayer(players[2],x+w+padding,y+padding,w-padding*2,h-padding*2)
  drawPlayerSelectForPlayer(players[3],x+padding,y+h+padding,w-padding*2,h-padding*2)
  drawPlayerSelectForPlayer(players[4],x+w+padding,y+h+padding,w-padding*2,h-padding*2)
end

function drawPlayerSelectForPlayer(player,x,y,w,h)
  local padding=10
  love.graphics.rectangle("line",x,y,w,h)
  assert(player.controller==nil or (player.controller>=0 and player.controller<=4),"Invalid player controller setting")
  if player.controller==nil then
    love.graphics.print("Press A on controller or ENTER",x+padding,y+padding)
  elseif player.controller==0 then
    if confirmedPlayers[player.id]==false then
      love.graphics.print("Keyboard\nWait for other players\nPress ENTER again to confirm",x+padding,y+padding) 
    else
      love.graphics.print("Keyboard CONFIRMED",x+padding,y+padding)
    end
  else
    if confirmedPlayers[player.id]==false then
      love.graphics.print(string.format("Controller ID %d\nWait for other players\nPress A again to confirm",player.controller),x+padding,y+padding)
    else
      love.graphics.print(string.format("Controller ID %d CONFIRMED",player.controller),x+padding,y+padding)
    end
  end
end

function findPlayerWithControllerId(players,id)
  for i=1,4 do
    if players[i].controller==id then
      return players[i]
    end
  end
  return nil
end

function playerSelectKeyPressed(players,key)
  if key~="return" then return end

  player=findPlayerWithControllerId(players,0)
  if player==nil then
    player=findFirstUnassignedPlayer(players)
    assert(player~=nil,"No unassigned players")
    player.controller=0 --player now assigned the keyboard
  else
    -- print("confirming player ",player.id)
    confirmedPlayers[player.id]=true
  end
  
  -- for i=1,4 do
  --   if players[i] then print("i,controller,confirmed",i,players[i].controller,confirmedPlayers[i]) end
  -- end
end

function playerSelectGamepadPressed(players,joystick,button)
  -- print("player gamepad pressed")
  if button~="a" then return end

  player=findPlayerWithControllerId(players,joystick:getID())
  if player==nil then
    player=findFirstUnassignedPlayer(players)
    assert(player~=nil,"No unassigned joystick players")
    player.controller=joystick:getID() --player now assigned the keyboard
    player.joystate=joystate[joystick]
  else
    -- print("confirming player ",player.id)
    confirmedPlayers[player.id]=true
  end
  
  -- for i=1,4 do
  --   if players[i] then print("i,controller,confirmed",i,players[i].controller,confirmedPlayers[i]) end
  -- end
end

function findFirstUnassignedPlayer(players)
  for i=1,4 do
    if players[i].controller==nil then return players[i] end
  end
  return nil
end