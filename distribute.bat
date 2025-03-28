@echo off
@if "%1" == "" goto usage

set VERSION="%1"
set GAME_BASE="badwizard"
set LOVE="C:\util\love2d\love-11.5-win64"
set GAME="%GAME_BASE%-%1"
set DIST="dist"

rm -f  %GAME%-web.love
rm -f  %GAME%.love
set INBROWSER=true
set RESOLUTION=1000
set FULLSCREEN=false
set LOVE_GAME=%GAME%-web.love
call :build_love
zip -9 -r %LOVE_GAME% *.lua assets\*.png README.txt lib\* maps\*.png maps\*.lua 

set INBROWSER=false
set RESOLUTION=1600
set FULLSCREEN=true
set LOVE_GAME=%GAME%.love
call :build_love
zip -9 -r %LOVE_GAME% *.lua assets\* README.txt lib\* maps\*.png maps\*.lua 

:build_zip
mkdir %DIST%
del /q %DIST%\*.zip
del /q %DIST%\*.love
move *.love %DIST%

cd %DIST%

mkdir %GAME%
cd %GAME%
copy /b %LOVE%\love.exe+..\%GAME%.love %GAME_BASE%.exe
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
exit /b

:build_love
echo buildVersion=%VERSION%>conf.lua
echo inbrowser=%INBROWSER%>>conf.lua
echo resolution=%RESOLUTION%>>conf.lua
echo fullscreen=%FULLSCREEN%>>conf.lua
echo release=true>>conf.lua
echo function love.conf(t)>>conf.lua
echo  t.console=true>>conf.lua
echo end>>conf.lua
exit /b



