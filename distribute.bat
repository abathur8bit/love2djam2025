@echo off
@if "%1" == "" goto usage

set GAME_BASE="badwizard"
set LOVE="C:\util\love2d\love-11.5-win64"
set GAME="%GAME_BASE%-%1"
set DIST="dist"

rm -f  %GAME%-web.love
rm -f  %GAME%.love
echo buildVersion=^"%1^">conf.lua
echo inbrowser=true>>conf.lua
echo resolution=1000>>conf.lua
echo fullscreen=false>>conf.lua
zip -9 -r %GAME%-web.love *.lua assets\*.png README.txt lib\* maps\*.png maps\*.lua

echo buildVersion=^"%1^">conf.lua
echo inbrowser=false>>conf.lua
echo resolution=1600>>conf.lua
echo fullscreen=true>>conf.lua
zip -9 -r %GAME%.love *.lua assets\* README.txt lib\* maps\*.png maps\*.lua

mkdir %DIST%
del /q %DIST%\*.zip
del /q %DIST%\*.love
move *.love %DIST%

cd %DIST%

mkdir %GAME%
cd %GAME%
copy /b %LOVE%\love.exe+..\..\%GAME%.love %GAME_BASE%.exe
copy %LOVE%\*.dll .
copy %LOVE%\license.txt .
copy ..\..\README.txt .
cd ..
zip -9 -r %GAME%.zip %GAME%\*
cd ..


@goto end

:usage
echo Creates a love distribution file for web and desktop, and an EXE.
echo Usage: distribute.bat postfix
echo postfix = date or version number to uniquely identify this version, appears at end of filename. 
echo Example: distribute 1.0

:end


