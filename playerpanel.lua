local gui=require "lib.gui"

function drawPlayerInfo(players)
  local padding=20
  local height=screenHeight/4
  local cellHeight=167
  local x=screenWidth-padding
  local y=screenHeight-padding
  local y={padding+cellHeight+height*0,padding+cellHeight+height*1,padding+cellHeight+height*2,padding+cellHeight+height*3}
  for i=1,4 do
    if players[i].controller~=nil then
      drawPlayerScoreHealth(players[1],x,y[i],i)

      -- drawPlayerPowerups(players[1])
    end
  end
end

function drawPlayerScoreHealth(player,x,y,playerNumber)
  love.graphics.setColor(1,1,1,0.6)
  love.graphics.setFont(fontSheets.small.font)

  local playerName=string.format("Player %d",playerNumber)
  local scoreText   ="score"
  local healthText  ="health"
  local powerText   ="power"
  local weaponText  ="weapon"
  local padding=20
  local offset=15
  local barWidth=100
  local barHeight=29

---@diagnostic disable-next-line: undefined-field
  local textWidth=fontSheets.small.font:getWidth(weaponText)

  love.graphics.setFont(fontSheets.medium.font)
  gui.rightText(playerName,x,y-love.graphics.getFont():getHeight())

  love.graphics.setFont(fontSheets.small.font)
  y=y-love.graphics.getFont():getHeight()-offset
  x=screenWidth-padding-textWidth
  love.graphics.print(powerText,x,y-love.graphics.getFont():getHeight())
  x=x-offset
  love.graphics.setFont(fontSheets.medium.font)
  gui.rightText(math.floor(player.score),x,y-love.graphics.getFont():getHeight())

  love.graphics.setFont(fontSheets.small.font)
  y=y-love.graphics.getFont():getHeight()-offset
  x=screenWidth-padding-textWidth
  love.graphics.print(powerText,x,y-love.graphics.getFont():getHeight())
  x=x-offset
  love.graphics.setFont(fontSheets.medium.font)
  gui.rightText(string.format("%d%%",math.floor(player.powerups/player.maxPowerups*100)),x,y-love.graphics.getFont():getHeight())
  drawPercentBar(x-barWidth,y-barHeight,barWidth,barHeight,player.powerups/player.maxPowerups)

  love.graphics.setFont(fontSheets.small.font)
  y=y-love.graphics.getFont():getHeight()-offset
  x=screenWidth-padding-textWidth
  love.graphics.print(weaponText,x,y-love.graphics.getFont():getHeight())
  x=x-offset
  love.graphics.setFont(fontSheets.medium.font)
  gui.rightText(string.format("%d%%",math.floor((player.firePower-1)/(player.firePowerMax-1)*100)),x,y-love.graphics.getFont():getHeight())
  drawPercentBar(x-barWidth,y-barHeight,barWidth,barHeight,(player.firePower-1)/(player.firePowerMax-1))

  love.graphics.setFont(fontSheets.small.font)
  y=y-love.graphics.getFont():getHeight()-offset
  x=screenWidth-padding-textWidth
  love.graphics.print(healthText,x,y-love.graphics.getFont():getHeight())
  x=x-offset
  if player.health<300 then
    love.graphics.setFont(fontSheets.large.font)
  else 
    love.graphics.setFont(fontSheets.medium.font)
  end
  gui.rightText(math.floor(player.health),x,y-love.graphics.getFont():getHeight())
end

function drawPlayerPowerups(player)
  local padding=16
  local offset=10
  local x=padding
  local y=screenHeight-padding-64

  if player.powerups>0 then love.graphics.setColor(1,1,1,1) end
  player.powerupAnim:draw(player.powerupSheet,x,y)

  love.graphics.setFont(fontSheets.small.font)
  love.graphics.setColor(1,1,1,0.6)
  x=x+64+offset
  y=screenHeight-padding
  love.graphics.print("powerup",x,y-love.graphics.getFont():getHeight())
end

-- value is a percent from 0-1
function drawPercentBar(x,y,w,h,value)
  if h>=3 then
    love.graphics.rectangle("line",x,y,w,h)
  end
  love.graphics.rectangle("fill",x,y,w*value,h)
end
