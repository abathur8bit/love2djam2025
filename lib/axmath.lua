local axmath={}

function axmath.radiansTable(step)
  local radians={}
  local index=0
  for degrees=0,359,step do
    local angle=degrees*math.pi/180
    radians[index]=angle
    print("degree,radian",degrees,angle)
    index=index+1
  end
  return radians
end

--[[
Create a table so you can lookup a radian based on
a degree. Table starts at 0, ends at 359.
local degree=5
local radTable=axmath.degree2radianTable(step)
local rad=radTable[degree]
--rad=0.087266462599716
]]--
function axmath.degree2radianTable(step)
  local radians={}
  for degrees=0,359,step do
    local angle=degrees*math.pi/180
    radians[degrees]=angle
  end
  return radians
end

--[[
Creates a table of values from 0 thru 359, optionally stepping every step values. 
I use this to create a smaller set of degree values that a joystick can use, and
use this table when I call snapDegree. Remember you can use math.rad(degree) to 
convert from degrees to radians.
]]--
function axmath.degreeTable(step)
  local degrees={}
  local deg=0
  local index=0
  local counter=0
  for d=0,359 do
    degrees[index]=deg
    index=index+1
    counter=counter+1
    if counter>=step then
      counter=0
      deg=deg+step
    end
  end
  return degrees
end

-- degreeTable should have values for 0-359
function axmath.snapDegree(degree,degreeTable)
  local d=math.floor(degree)%360 --make sure we are 0-359
  assert(d>=0 and d<=359,"degree must be 0-359")
  return degreeTable[d]
end

return axmath
