@echo off
@if "%1" == "" goto usage

set GAME_BASE="badwizard"
set LOVE="C:\util\love2d\love-11.5-win64"
set GAME="%GAME_BASE%-%1"

rm -f  %GAME%-web.love
rm -f  %GAME%.love
echo inbrowser=true>resolution.lua
echo resolution=1000>>resolution.lua
echo fullscreen=false>>resolution.lua
zip -9 -r %GAME%-web.love *.lua assets\*.png README.txt lib\* maps\*

echo inbrowser=false>resolution.lua
echo resolution=1800>>resolution.lua
echo fullscreen=true>>resolution.lua
zip -9 -r %GAME%.love *.lua assets\* README.txt lib\* maps\*

mkdir %GAME%
cd %GAME%
copy /b %LOVE%\love.exe+..\%GAME%.love %GAME_BASE%.exe
copy %LOVE%\*.dll .
copy %LOVE%\license.txt .
copy ..\README.txt .
cd ..
zip -9 -r %GAME%.zip %GAME%\*

@goto end

:usage
echo Creates a love distribution file for web and desktop, and an EXE.
echo Usage: distribute.bat postfix
echo postfix = date or version number to uniquely identify this version, appears at end of filename. 
echo Example: distribute 1.0

:end


