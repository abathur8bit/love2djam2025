require "shape"

function createBullet(x,y,angle,vx,vy,color,rocket)
  if rocket==nil then rocket=false end
  if color == nil then color = createColor(1,1,1) end
  s=createShape(x,y,1,1,0,color)
  s.z=2
  s.type="bullet"
  s.vx=vx
  s.vy=vy
  s.angle=angle
  s.radius=3
  s.sprite=love.graphics.newImage("assets/bullet.png")
  s.anglespeed=0
  s.maxspeed=200
  s.thrust=500
  s.friction=0
  s.scale=2
  s.update=updateBullet
  s.draw=drawBullet
  s.time=3.5
  s.rocket=rocket
  return s
end

function updateBullet(self,dt)
  self.time=self.time-dt
  if self.time<=0 then 
    self.time=0 
    return false 
  end
  
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
  love.graphics.setColor(self.color.red,self.color.green,self.color.blue,self.color.alpha)
  love.graphics.circle('fill', self.x, self.y,self.radius)
end