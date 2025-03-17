local a=true
local s=(a and "yes" or "no")
print(a,s)local a=true

a=false
s=(a==true and "yes" or "no")
print(a,s)


print(string.format("a is %s",(a==true "yes" or "no")))