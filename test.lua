local a=true
local s=(a and "yes" or "no")
print(a,s)local a=true

a=false
s=(a==true and "yes" or "no")
print(a,s)


print("OPTIONS")
local options={debug=true,showExtras=true,showCamera=true,collideWalls=true}
for key,value in pairs(options) do print(key,value) end
for i in pairs(options) do print(i) end

print("debug=",options["debug"])