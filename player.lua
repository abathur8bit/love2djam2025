local anim8=require 'lib.anim8'
local shape = require "shape"
local gui=require "lib.gui"

function createPlayer(id,x,y,w,h,filename) 
  s=shape.createShape(x,y,w,h,0,gui.createColor(1,1,1,1))
  s.id=id
  s.score=0
  s.health=INITIAL_PLAYER_HEALTH
  s.fireRate=0.2
  s.fireRateTimer=s.fireRate
  s.keyPressed=false
  s.speed=300
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
  s.speed=300
  s.fireRate=0.2
  s.fireRateTimer=s.fireRate
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
  self.current=self.anims[self.animType][self.direction]
  self.current:update(dt)
end

function drawPlayer(self)
  self.current:draw(self.sheet,self.x,self.y,nil,self.scale,self.scale,self.w/2,self.h/2)
end

return player