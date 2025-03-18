local HC=require "lib.HC"
local anim8=require "lib.anim8"
local shape = require "shape"
local gui=require "lib.gui"

function createPlayer(id,x,y,w,h,filename) 
  local color=gui.createColor(153,229,80,1)
  if id==2 then color=gui.createColor(102,225,243,1) end
  if id==3 then color=gui.createColor(221,229,235,1) end
  if id==4 then color=gui.createColor(243,214,18,1) end

  local s=shape.createShape(x,y,w,h,0,color)
  s.type="player"
  s.id=id
  s.score=0
  s.health=INITIAL_PLAYER_HEALTH
  s.animType="idle"
  s.direction="downright"
  s.update=updatePlayer
  s.draw=drawPlayer
  s.idleTimer=0.0
  s.idleTimerDelay=5
  s.sheet=love.graphics.newImage(filename)
  s.grid=anim8.newGrid(s.w,s.h,s.sheet:getWidth(),s.sheet:getHeight())
  s.animType="walk"
  s.direction="downright"
  s.keyPressed=false
  s.firing=false
  s.speed=300
  s.fireRate=0.2
  s.fireRateTimer=s.fireRate
  s.collider=HC.rectangle(s:adjustRect(50,8))
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
  return s
end

function updatePlayer(self,dt)
  self.fireRateTimer=self.fireRateTimer+dt
  if self.keypressed then 
    self.animType="walk" 
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
    self.animType="idle"
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

  local vx=0
  local vy=0
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

  self.collider:moveTo(self.x,self.y) -- keep collision in sync
  self.current=self.anims[self.animType][self.direction]  -- set the correct animation
  self.current:update(dt) -- update anim8
end

function drawPlayer(self)
  self.current:draw(self.sheet,self.x,self.y,nil,self.scale,self.scale,self.w/2,self.h/2)
end
