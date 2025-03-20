local shape=require "shape"
local gui=require "lib.gui"

function createBullet(player,x,y,angle,color,rocket)
  local growMins={3,6,10}
  local growMaxs={10,16,25}
  local speeds={500,600,800}
  local colors={
    gui.createColor(1.0,1.0,1.0,1),
    gui.createColor(1.0,1.0,0.0,1),
    gui.createColor(1.0,0.5,0.5,1)
  }

  if rocket==nil then rocket=false end
  local power=player.firePower+1
  if power>3 then power=3 end

  local s=shape.createShape(x,y,1,1,angle,color)
  s.color=colors[power]
  s.z=11
  s.type="bullet"
  s.growMin=growMins[power]
  s.growMax=growMaxs[power]
  s.growSpeed=60
  s.radius=s.growMin
  s.maxspeed=500
  s.thrust=speeds[power]
  s.update=updateBullet
  s.draw=drawBullet
  s.time=3.5
  s.rocket=rocket

  local ax,ay=0,0
  ax = math.sin(s.angle)*s.thrust
  ay = -math.cos(s.angle)*s.thrust  
  s.vx = s.vx + ax*s.thrust
  s.vy = s.vy + ay*s.thrust
  return s
end

function updateBullet(self,dt)
  self.time=self.time-dt
  if self.time<=0 then 
    self.time=0 
    return false 
  end
  
  self.radius=self.radius+self.growSpeed*dt
  if self.radius>self.growMax then self.radius=self.growMin end

  if self.rocket then
    --bullet will speed up over time
    local ax,ay=0,0
    ax = math.sin(self.angle)*self.thrust
    ay = -math.cos(self.angle)*self.thrust

    self.vx = self.vx + ax*dt
    self.vy = self.vy + ay*dt
    self.x = self.x + self.vx*dt
    self.y = self.y + self.vy*dt
  else
    -- bullet travels at a constant speed
    self.x = self.x + math.sin(self.angle)*self.maxspeed*dt
    self.y = self.y + -math.cos(self.angle)*self.maxspeed*dt
  end
  return true
end

function drawBullet(self)
  love.graphics.setColor(self.color:components())
  love.graphics.circle('fill', self.x, self.y,self.radius)
end