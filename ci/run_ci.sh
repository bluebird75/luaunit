echo ===== CI emulation mode =====
rm -rf $HOME/.lua

# export LUA=luajit2.1
export LUA=lua5.4

export CI_WORKDIR=`pwd`
export PLATFORM=linux
export LUANUMBER=double

# erase previous builds
rm -rf $CI_WORKDIR/install

bash setup_lua.sh
