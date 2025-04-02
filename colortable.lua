-- Create an HTML table with boxes showing the color and color value
local colors={
  "000000","5F5F5F","7F7F7F","9F9F9F","BFBFBF","DFDFDF","FFFFFF",
  "3F0000","5F0000","7F0000","9F0000","BF0000","DF0000","FF0000",
  "003F00","005F00","007F00","009F00","00BF00","00DF00","00FF00",
  "00003F","00005F","00007F","00009F","0000BF","0000DF","0000FF",
  "3F3F00","5F5F00","7F7F00","9F9F00","BFBF00","DFDF00","FFFF00",
  "3F003F","5F005F","7F007F","9F009F","BF00BF","DF00DF","FF00FF",
  "003F3F","005F5F","007F7F","009F9F","00BFBF","00DFDF","00FFFF",
}
local maxCols=7
local cellWidth=100
local cellHeight=100
local borderWidth=0
local tableBorderWidth=2
local pstyle="background-color: #9f9f9f; color: #000000;"

print("<h1>Game Palette</h1>")
print(string.format("<table style='border: %dpx solid black;'>",tableBorderWidth))
i=1
while i<#colors do
  print(" <tr>")
  for td=1,maxCols do
    if i<=#colors then
      print(string.format("  <td style='vertical-align: bottom; border: %dpx solid black;' width=%d height=%d bgcolor='#%s'><p style='%s'>%s</p></td>",borderWidth,cellWidth,cellHeight,colors[i],pstyle,colors[i]))
      i=i+1
    end
  end
  print(" </tr>")
end
print("</table>")