local HC=require "lib.HC"
local anim8=require "lib.anim8"
local shape = require "shape"
local gui=require "lib.gui"

function createPlayer(world,id,x,y,w,h,filename)
  local color=gui.createColor(153,229,80,1)
  if id==2 then color=gui.createColor(102,225,243,1) end
  if id==3 then color=gui.createColor(221,229,235,1) end
  if id==4 then color=gui.createColor(243,214,18,1) end

  local s=shape.createShape(x,y,w,h,0,color)
  s.type="player"
  s.id=id
  s.world=world
  -- s.hitbox=world:createHitbox(xa,ya,wa,ha,s.type,id,s.type,s)
  s.score=0
  s.health=INITIAL_PLAYER_HEALTH
  s.animType="idle"
  s.direction="downright"
  s.update=updatePlayer
  s.draw=drawPlayer
  s.usePowerup=usePowerup
  s.createHitbox=createPlayerHitbox
  s.reset=resetPlayer
  s.idleTimer=0.0
  s.idleTimerDelay=5
  s.sheet=love.graphics.newImage(filename)
  s.grid=anim8.newGrid(s.w,s.h,s.sheet:getWidth(),s.sheet:getHeight())
  s.powerupSheet=love.graphics.newImage("assets/powerups.png")
  s.powerupGrid=anim8.newGrid(64,64,s.powerupSheet:getWidth(),s.powerupSheet:getHeight())
  s.powerupAnim=anim8.newAnimation(s.powerupGrid("1-4",1),0.1)
  s.powerupAnim:pause()
  s.animType="walk"
  s.direction="downright"
  s.keyPressed=false
  s.joystate=nil
  s.firing=false
  s.speed=300
  s.fireRate=0.2
  s.fireRateTimer=s.fireRate
  s.powerups=0
  s.maxPowerups=3
  s.firePower=1
  s.firePowerMax=3
  s.firePowerTimer=0
  s.firePowerDelay={5,10,20}
  s.anims={}
  s.anims.idle={}
  s.anims.idle.up        = anim8.newAnimation(s.grid(21,1),0.15)
  s.anims.idle.down      = anim8.newAnimation(s.grid(17,1),0.15)
  s.anims.idle.right     = anim8.newAnimation(s.grid(29,1),0.15)
  s.anims.idle.left      = anim8.newAnimation(s.grid(25,1),0.15)
  s.anims.idle.upleft    = anim8.newAnimation(s.grid(13,1),0.15)
  s.anims.idle.upright   = anim8.newAnimation(s.grid(9,1),0.15)
  s.anims.idle.downright = anim8.newAnimation(s.grid(1,1),0.15)
  s.anims.idle.downleft  = anim8.newAnimation(s.grid(5,1),0.15)
  s.anims.walk={}
  s.anims.walk.up        = anim8.newAnimation(s.grid('21-24',1),0.15)
  s.anims.walk.down      = anim8.newAnimation(s.grid('17-20',1),0.15)
  s.anims.walk.right     = anim8.newAnimation(s.grid('29-32',1),0.15)
  s.anims.walk.left      = anim8.newAnimation(s.grid('25-28',1),0.15)
  s.anims.walk.upleft    = anim8.newAnimation(s.grid('13-16',1),0.15)
  s.anims.walk.upright   = anim8.newAnimation(s.grid('9-12',1),0.15)
  s.anims.walk.downright = anim8.newAnimation(s.grid('1-4',1),0.15)
  s.anims.walk.downleft  = anim8.newAnimation(s.grid('5-8',1),0.15)
  s.current=s.anims[s.animType][s.direction]

  s.incPowerups=incPowerups
  s.decPowerups=decPowerups
  return s
end

function resetPlayer(self)
  self.score=0
  self.health=INITIAL_PLAYER_HEALTH
  self.firePower=1
end

function createPlayerHitbox(self)
  local xa,ya,wa,ha=self:adjustRect(50,8)
  self.hitbox=self.world:createHitbox(xa,ya,wa,ha,self.type,self.id,self.type,self)
end

function incPowerups(self)
  if self.powerups<self.maxPowerups then
    self.powerups=self.powerups+1
  end
end

function decPowerups(self)
  if self.powerups>0 then
    self.powerups=self.powerups-1
  end
end

function updatePlayer(self,dt)
  self.powerupAnim:gotoFrame(self.powerups+1)
  self.fireRateTimer=self.fireRateTimer+dt
  if self.keypressed then 
    self.animType="walk" 
    playSfx(sfx.footsteps)
  else 
    self.animType="idle"
    stopSfx(sfx.footsteps)
  end

  if self.joystate~=nil then
    local vx=self.joystate.vxleft
    local vy=self.joystate.vyleft
    if math.abs(vx)<0.15 then vx=0 end
    if math.abs(vy)<0.15 then vy=0 end
    self.x=self.x+vx*self.speed*dt
    self.y=self.y+vy*self.speed*dt
  else
    if self.keypressed == true then
      if self.direction=="up" then 
        self.y=self.y-self.speed*dt
        self.angle=0
      elseif self.direction=="down" then
        self.y=self.y+self.speed*dt
        self.angle=180*math.pi/180
      elseif self.direction=="right" then
        self.x=self.x+self.speed*dt
        self.angle=90*math.pi/180
      elseif self.direction=="left" then
        self.x=self.x-self.speed*dt
        self.angle=270*math.pi/180
      elseif self.direction=="upleft" then 
        self.x=self.x-self.speed*dt
        self.y=self.y-self.speed*dt
        self.angle=315*math.pi/180
      elseif self.direction=="upright" then
        self.x=self.x+self.speed*dt
        self.y=self.y-self.speed*dt
        self.angle=45*math.pi/180
      elseif self.direction=="downright" then
        self.x=self.x+self.speed*dt
        self.y=self.y+self.speed*dt
        self.angle=135*math.pi/180
      elseif self.direction=="downleft" then
        self.x=self.x-self.speed*dt
        self.y=self.y+self.speed*dt
        self.angle=225*math.pi/180
      end
    end
  end

  self.hitbox.collider:moveTo(self.x,self.y) -- keep collision in sync
  self.current=self.anims[self.animType][self.direction]  -- set the correct animation
  self.current:update(dt) -- update anim8
  self.powerupAnim:update(dt)

  if self.firePowerTimer>0 then
    self.firePowerTimer=self.firePowerTimer-dt
    if self.firePowerTimer<=0 then
      print("firepower time timed out")
      self.firePowerTimer=0
      self.firePower=1
    end
  end
end

function drawPlayer(self)
  love.graphics.setColor(1,1,1,1)
  self.current:draw(self.sheet,self.x,self.y,nil,self.scale,self.scale,self.w/2,self.h/2)
end

function usePowerup(self,type)
  if self.powerups>0 then
    if type=="1" then
      print("using powerup type 1")
      self.health=self.health+100
      self:decPowerups()
      playSfx(sfx.usePowerupAsHealth)
    elseif type=="2" then
      print("using powerup type 2")
      if self.firePower<self.firePowerMax then
        self.firePower=self.firePower+1
        self.firePowerTimer=self.firePowerDelay[self.firePower]
        self:decPowerups()
        playSfx(sfx.usePowerupAsPower)
      end
    end
  end
  print("used powerup, remaining:",self.powerups)
end