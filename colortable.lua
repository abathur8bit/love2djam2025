-- Create an HTML table with boxes showing the color and color value in hex and decimal
local maxCols=7
local colors={
  "000000","5F5F5F","7F7F7F","9F9F9F","BFBFBF","DFDFDF","FFFFFF",
  "3F0000","5F0000","7F0000","9F0000","BF0000","DF0000","FF0000",
  "003F00","005F00","007F00","009F00","00BF00","00DF00","00FF00",
  "00003F","00005F","00007F","00009F","0000BF","0000DF","0000FF",
  "3F3F00","5F5F00","7F7F00","9F9F00","BFBF00","DFDF00","FFFF00",
  "3F003F","5F005F","7F007F","9F009F","BF00BF","DF00DF","FF00FF",
  "003F3F","005F5F","007F7F","009F9F","00BFBF","00DFDF","00FFFF",
}

-- Convert a hex color like "FFFFFF" to 255,255,255. Also treats "FFF" or "111" as "FFFFFF" or "111111".
function hex2decColor(hex)
  assert(string.len(hex)==3 or string.len(hex)==6,"Hex value must be 3 or 6 characters long")  -- must be in format "FFF" or "FFFFFF"
  if string.len(hex)==6 then
    r=tonumber(string.sub(hex,1,2),16)
    g=tonumber(string.sub(hex,3,4),16)
    b=tonumber(string.sub(hex,5,6),16)
  elseif string.len(hex)==3 then
    r=tonumber(string.sub(hex,1,1)..string.sub(hex,1,1),16)
    g=tonumber(string.sub(hex,2,2)..string.sub(hex,2,2),16)
    b=tonumber(string.sub(hex,3,3)..string.sub(hex,3,3),16)
  end
  return r,g,b
end

local htmlHead=[[
<html>
<head>
<style>
p {
  background-color: rgba(200,200,200,0.3); 
  color: #000000;
  border: 0px solid black;
  text-transform: uppercase;
  padding: 2px;
}
table {
  border: 2px solid black;
}
td {
  vertical-align: bottom; 
  border: 0px solid black;
  width: 100px;
  height: 100px;
}
</style>
</head>
<body>
]]
local htmlFoot="</body></html>"
print(htmlHead)
print("<h1>Game Palette</h1>")
print(string.format("<table>"))
i=1
while i<#colors do
  print(" <tr>")
  for td=1,maxCols do
    if i<=#colors then
      local r,g,b=hex2decColor(colors[i])
      print(string.format("  <td bgcolor='#%s'><p>%s<br/>%d,%d,%d</p></td>",colors[i],colors[i],r,g,b))
      i=i+1
    end
  end
  print(" </tr>")
end
print("</table>")
print(htmlFoot)