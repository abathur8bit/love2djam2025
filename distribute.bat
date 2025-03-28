@echo off
@if "%1" == "" goto usage

set VERSION=%1
set GAME_BASE=badwizard
set LOVE="C:\util\love2d\love-11.5-win64"
set GAME=%GAME_BASE%-%VERSION%
set DIST=dist
set BUILD=%DIST%\build

rm -f  %DIST%\%GAME%-web.love
rm -f  %DIST%\%GAME%.love
rm -f  %DIST%\%GAME%.zip
mkdir %BUILD%\assets
mkdir %BUILD%\lib
mkdir %BUILD%\maps
del /q %BUILD%\assets\*
del /q %BUILD%\lib\*
del /q %BUILD%\maps\*
del /q %BUILD%\*

echo Build web package
set INBROWSER=true
set RESOLUTION=1000
set FULLSCREEN=false
set LOVE_GAME=%GAME%-web.love
call :build_conf
xcopy /y *.lua %BUILD%
xcopy /y README.txt %BUILD%
xcopy /y /s lib %BUILD%\lib
xcopy /y ..\lib %BUILD%\lib
xcopy /y assets\*.png %BUILD%\assets
xcopy /y maps\*.png %BUILD%\maps
xcopy /y maps\*.lua %BUILD%\maps
cd %BUILD%
zip -9 -r %LOVE_GAME% *.lua assets\*.png README.txt lib\* maps\*.png maps\*.lua 
move *.love ..
cd ..\..

echo Build love package
set INBROWSER=false
set RESOLUTION=1920
set FULLSCREEN=true
set LOVE_GAME=%GAME%.love
call :build_conf
xcopy /y *.lua %BUILD%
xcopy /y README.txt %BUILD%
xcopy /y /s lib %BUILD%\lib
xcopy /y /s ..\lib %BUILD%\lib
xcopy /y assets %BUILD%\assets
xcopy /y maps\*.png %BUILD%\maps
xcopy /y maps\*.lua %BUILD%\maps
cd %BUILD%
zip -9 -r %LOVE_GAME% *.lua assets\* README.txt lib\* maps\*.png maps\*.lua 
move *.love ..
cd ..\..

echo Build Windows EXE
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

:build_conf
echo buildVersion=%VERSION%>  conf.lua
echo inbrowser=%INBROWSER%>>  conf.lua
echo resolution=%RESOLUTION%>>conf.lua
echo fullscreen=%FULLSCREEN%>>conf.lua
echo release=true>>           conf.lua
echo function love.conf(t)>>  conf.lua
echo   t.console=true>>       conf.lua
echo end>>                    conf.lua
exit /b



