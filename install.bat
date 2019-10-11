@echo off

set installdir=%LOCALAPPDATA%\wsltty
set appsbindir=%USERPROFILE%\bin


:deploy

mkdir "%installdir%"

rem clean up previous installation artefacts
del /Q "%installdir%\*.bat"
del /Q "%installdir%\*.lnk"

copy LICENSE.mintty "%installdir%"
copy LICENSE.wslbridge2 "%installdir%"

copy "add to context menu.lnk" "%installdir%"
copy "add default to context menu.lnk" "%installdir%"
copy "remove from context menu.lnk" "%installdir%"
copy "configure WSL shortcuts.lnk" "%installdir%"
copy config-distros.sh "%installdir%"

copy mkshortcut.vbs "%installdir%"

rem allow persistent customization of default icon:
if not exist "%installdir%\wsl.ico" copy tux.ico "%installdir%\wsl.ico"

copy uninstall.bat "%installdir%"

if not exist "%installdir%\bin" goto instbin
rem move previous programs possibly in use out of the way
del /Q "%installdir%\bin\*.old"
ren "%installdir%\bin\cygwin1.dll" cygwin1.dll.old
ren "%installdir%\bin\cygwin-console-helper.exe" cygwin-console-helper.exe.old
ren "%installdir%\bin\mintty.exe" mintty.exe.old
ren "%installdir%\bin\wslbridge2.exe" wslbridge2.exe.old
ren "%installdir%\bin\wslbridge2-backend" wslbridge2-backend.old
ren "%installdir%\bin\hvpty.exe" hvpty.exe.old
ren "%installdir%\bin\hvpty-backend" hvpty-backend.old
del /Q "%installdir%\bin\*.old"

:instbin
mkdir "%installdir%\bin"
copy cygwin1.dll "%installdir%\bin"
copy cygwin-console-helper.exe "%installdir%\bin"
copy mintty.exe "%installdir%\bin"
copy wslbridge2.exe "%installdir%\bin"
copy wslbridge2-backend "%installdir%\bin"
copy hvpty.exe "%installdir%\bin"
copy hvpty-backend "%installdir%\bin"

copy dash.exe "%installdir%\bin"
copy regtool.exe "%installdir%\bin"
copy zoo.exe "%installdir%\bin"

rem create system config directory and copy config archive
mkdir "%installdir%\usr\share\mintty\lang"
copy lang.zoo "%installdir%\usr\share\mintty\lang"
mkdir "%installdir%\usr\share\mintty\themes"
copy themes.zoo "%installdir%\usr\share\mintty\themes"
mkdir "%installdir%\usr\share\mintty\sounds"
copy sounds.zoo "%installdir%\usr\share\mintty\sounds"
mkdir "%installdir%\usr\share\mintty\info"
copy charnames.txt "%installdir%\usr\share\mintty\info"
mkdir "%installdir%\usr\share\mintty\icon"
copy tux.ico "%installdir%\usr\share\mintty\icon"
copy mintty.ico "%installdir%\usr\share\mintty\icon"

rem copy apps to user bin
mkdir "%appsbindir%"
copy wsl.exe "%appsbindir%"
copy wsl.exe "%appsbindir%\vim.exe"
copy wsl.exe "%appsbindir%\ranger.exe"
copy wsl.exe "%appsbindir%\zsh.exe"
copy wsl.exe "%appsbindir%\sh.exe"


rem create Start Menu Folder
set smf=%APPDATA%\Microsoft\Windows\Start Menu\Programs\WSLtty
mkdir "%smf%"

rem clean up previous installation
del /Q "%smf%\*.lnk"

copy "wsltty home & help.url" "%smf%"
copy "add to context menu.lnk" "%smf%"
copy "add default to context menu.lnk" "%smf%"
copy "remove from context menu.lnk" "%smf%"
copy "configure WSL shortcuts.lnk" "%smf%"
rem copy "WSL Terminal.lnk" "%smf%"
rem copy "WSL Terminal %%.lnk" "%smf%"
rem clean up previous installation
rmdir /S /Q "%smf%\context menu shortcuts"

rem unpack config files in system config directory
cd /D "%installdir%\usr\share\mintty\lang"
"%installdir%\bin\zoo" xO lang
cd /D "%installdir%\usr\share\mintty\themes"
"%installdir%\bin\zoo" xO themes
cd /D "%installdir%\usr\share\mintty\sounds"
"%installdir%\bin\zoo" xO sounds


:userconfig

rem distro-specific stuff: shortcuts and launch scripts
cd "%installdir%"
bin\dash.exe "%installdir%\config-distros.sh"
rem bin\dash.exe "%installdir%\config-distros.sh" -contextmenu


:end
