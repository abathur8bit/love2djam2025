local gui=require "lib.gui"

function drawPlayerInfo(player)
  drawPlayerScoreHealth(player)
  drawPlayerPowerups(player)
end

function drawPlayerScoreHealth(player)
  love.graphics.setColor(1,1,1,0.6)
  love.graphics.setFont(fontSheets.small.font)

  local scoreText="score"
  local healthText="health"
  local padding=16
  local x=screenWidth-padding
  local y=screenHeight-padding
  local offset=10

---@diagnostic disable-next-line: undefined-field
  local textWidth=fontSheets.small.font:getWidth(healthText)

  x=screenWidth-padding-textWidth
  love.graphics.print(scoreText,x,y-love.graphics.getFont():getHeight())
  x=x-offset
  love.graphics.setFont(fontSheets.medium.font)
  gui.rightText(math.floor(player.score),x,y-love.graphics.getFont():getHeight())

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
  love.graphics.rectangle("line",x,y,w,h)
  love.graphics.rectangle("fill",x,y,w*value,h)
end
