echo == Travis emulation mode ==
rm -rf $HOME/.lua

export LUA=lua5.4
# export LUA=luajit2.1

export LUANUMBER=double


export TRAVIS_BUILD_DIR=`pwd`
export TRAVIS_OS_NAME=linux

# erase previous builds
rm -rf $TRAVIS_BUILD_DIR/install

bash ../.travis/setup_lua.sh
