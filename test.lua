local a=true
local s=(a and "yes" or "no")
print(a,s)local a=true

a=false
s=(a==true and "yes" or "no")
print(a,s)


print("OPTIONS")
local options={debug=true,showExtras=true,showCamera=true,collideWalls=true}
for key,value in pairs(options) do print(key,value) end
print("OPTIONS I")
for i in pairs(options) do print(i) end
print("OPTIONS _,value")
for _,value in pairs(options) do print(value) end

print("debug=",options["debug"])

notthere=options["xxx"]
if notthere==nil then print("is nil") else print("not nil") end

obj="door-01"
s=string.find(obj,"-")
name=string.sub(obj,1,s-1)
number=string.sub(obj,s+1)
print(name,number)

print("\nPLAYERS")
players={{name="earny",controller=0},{name="burt",controller=nil},{name="fred",controller=nil},{name="barny",controller=nil}}
print("#players",#players)
for k,v in pairs(players) do
print("k,v",k,v.name)
end
print("player 1",players[1].name)
print("player 4",players[4].name)

function findFirstUnassignedPlayer(players)
  print("finding first unassigned player")
  for i=1,4 do
    print("checking player i,player.name,player.controller",i,players[i].name,players[i].controller)
    if players[i].controller==nil then
      print(string.format("returning player %s has no controller",players[i].name))
      return players[i] 
    end
  end
  return nil
end

local player=findFirstUnassignedPlayer(players)
print("unassigned",player.name)

local confirmedPlayers={false,false,false,false}
for _,p in pairs(confirmedPlayers) do print("confirmed=",p) end