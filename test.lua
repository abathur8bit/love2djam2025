shape=require "shape"

player = shape.createPlayer(1,10,10,64,64,scale)

print("foo")
for key,value in pairs(player) do
  print(key,value)
end

player:update(0)
player:draw()
