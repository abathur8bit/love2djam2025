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