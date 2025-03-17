local shape=require "shape"

function createBullet(x,y,angle,color,rocket)
  if rocket==nil then rocket=false end
  if color == nil then color = createColor(1,1,1) end
  s=shape.createShape(x,y,1,1,angle,color)
  s.z=11
  s.type="bullet"
  s.growMin=3
  s.growMax=10
  s.growSpeed=60
  s.radius=s.growMin
  s.maxspeed=200
  s.thrust=500
  s.scale=1
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