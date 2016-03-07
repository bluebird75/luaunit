REM This is a batch file to help with setting up the desired Lua environment.
REM It is intended to be run as "install" step from within AppVeyor.

REM version numbers and file names for binaries from http://sf.net/p/luabinaries/
set VER_51=5.1.5
set VER_52=5.2.4
set VER_53=5.3.2
set ZIP_51=lua-%VER_51%_Win32_bin.zip
set ZIP_52=lua-%VER_52%_Win32_bin.zip
set ZIP_53=lua-%VER_53%_Win32_bin.zip

:cinst
if NOT "%LUAENV%"=="cinst" goto lua51
echo Chocolatey install of Lua ...
@echo on
cinst lua
set LUA="C:\Program Files (x86)\Lua\5.1\lua.exe"
@echo off
goto :EOF

:lua51
if NOT "%LUAENV%"=="lua51" goto lua52
echo Setting up Lua 5.1 ...
@echo on
curl -fLsS -o %ZIP_51% http://sourceforge.net/projects/luabinaries/files/%VER_51%/Tools%%20Executables/%ZIP_51%/download
unzip %ZIP_51%
set LUA=lua5.1.exe
@echo off
goto :EOF

:lua52
if NOT "%LUAENV%"=="lua52" goto lua53
echo Setting up Lua 5.2 ...
@echo on
curl -fLsS -o %ZIP_52% http://sourceforge.net/projects/luabinaries/files/%VER_52%/Tools%%20Executables/%ZIP_52%/download
unzip %ZIP_52%
set LUA=lua52.exe
@echo off
goto :EOF

:lua53
if NOT "%LUAENV%"=="lua53" goto luajit
echo Setting up Lua 5.3 ...
@echo on
curl -fLsS -o %ZIP_53% http://sourceforge.net/projects/luabinaries/files/%VER_53%/Tools%%20Executables/%ZIP_53%/download
unzip %ZIP_53%
set LUA=lua53.exe
@echo off
goto :EOF

:luajit
if NOT "%LUAENV%"=="luajit20" goto luajit21
echo Setting up LuaJIT 2.0 ...
call %~dp0install-luajit.cmd LuaJIT-2.0.4
set LUA=luajit.exe
goto :EOF

:luajit21
echo Setting up LuaJIT 2.1 ...
call %~dp0install-luajit.cmd LuaJIT-2.1.0-beta2
set LUA=luajit.exe
