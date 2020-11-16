REM Do a minimalistic build of LuaJIT using the MinGW compiler

set PATH=C:\MinGW\bin;%PATH%

echo Downloading %PRETTY_VERSION% ...
curl -fLsS -o %DL_ZIP%.zip %DL_URL%

echo Unzipping %DL_ZIP%
unzip -q %DL_ZIP%

REM tweak Makefile for a static LuaJIT build (Windows defaults to "dynamic" otherwise)
sed -i "s/BUILDMODE=.*mixed/BUILDMODE=static/" %DL_ZIP%\src\Makefile

mingw32-make TARGET_SYS=Windows -C %DL_ZIP%\src

echo Installing %PRETTY_VERSION% ...
REM copy luajit.exe to project dir
mkdir %APPVEYOR_BUILD_FOLDER%\%LUA_BIN_DIR%
copy %DL_ZIP%\src\luajit.exe %APPVEYOR_BUILD_FOLDER%\%LUA_BIN_DIR%\

REM clean up (remove source folders and archive)
rm -rf %DL_ZIP%/*
rm -f %DL_ZIP%.zip


