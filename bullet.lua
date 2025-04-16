local shape=require "shape"
local gui=require "lib.gui"

function createBullet(world,shooter,x,y,angle,color)
  local growMins={[1]=3,[2]=6,[3]=10,monster=3}
  local growMaxs={[1]=10,[2]=16,[3]=25,monster=10}
  local speeds={[1]=500,[2]=600,[3]=800,monster=500}
  local damages={[1]=1000,[2]=1500,[3]=2000,monster=100} -- the higher the level, the more damage it does
  local times={[1]=10,[2]=7,[3]=4,monster=10} -- the higher the level the less time you get to use it
  local colors={
    [1]=gui.createColor(1.0,1.0,1.0,1),
    [2]=gui.createColor(1.0,1.0,0.0,1),
    [3]=gui.createColor(1.0,0.5,0.5,1),
    monster=gui.createColor(1.0,1.0,1.0,1),
  }

  local power = shooter.firePower
  if type(power)=='number' then
    power = math.min(power, 3)
  end
  
  local s=shape.createShape(x,y,1,1,angle,color)
  s.shooter=shooter
  s.world=world
  s.color=colors[power]
  s.z=11
  s.type="bullet"
  s.growMin=growMins[power]
  s.growMax=growMaxs[power]
  s.growSpeed=60
  s.radius=s.growMin
  s.maxspeed=500
  s.thrust=speeds[power]
  s.damage=damages[power]
  s.update=updateBullet
  s.draw=drawBullet
  s.createHitbox=createBulletHitbox
  s.time=times[power]

  local ax,ay=0,0
  ax = math.sin(s.angle)*s.thrust
  ay = -math.cos(s.angle)*s.thrust
  s.vx = s.vx + ax*s.thrust
  s.vy = s.vy + ay*s.thrust
  return s
end

function createBulletHitbox(self)
  self.hitbox=self.world:createHitbox(self.x-s.growMax/2,self.y-self.growMax/2,self.growMax,self.growMax,"bullet","bullet","bullet",self)
end

function updateBullet(self,dt)
  self.time=self.time-dt
  if self.time<=0 then 
    self.time=0 
    self.world:removeHitbox(self.hitbox)
    return false 
  end
  
  self.radius=self.radius+self.growSpeed*dt
  if self.radius>self.growMax then self.radius=self.growMin end

  -- bullet travels at a constant speed
  self.x = self.x + math.sin(self.angle)*self.maxspeed*dt
  self.y = self.y + -math.cos(self.angle)*self.maxspeed*dt
  self.hitbox.collider:moveTo(self.x,self.y)
  return true
end

function drawBullet(self)
  love.graphics.setColor(self.color:components())
  love.graphics.circle('fill', self.x, self.y,self.radius)
end
