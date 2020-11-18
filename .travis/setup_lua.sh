#! /bin/bash

# A script for setting up environment for travis-ci testing.
# Sets up Lua and Luarocks.
# LUA must be "lua5.1", "lua5.2" or "luajit".
# luajit2.0 - master v2.0
# luajit2.1 - master v2.1

### 
# This script will create the following symbolic links, to refer to the installed lua:
# $HOME/.lua/lua
# $HOME/.lua/luajit
# $HOME/.lua/luac
# $HOME/.lua/luarocks
#
# Building of the targeted lua version is done in:
# $HOME/install/<lua-version>
#
# Lua rocks in installed in 
# $HOME/install/luacoks

set -eufox pipefail

LUAROCKS_VERSION=3.4.0
LUAROCKS_URL=http://luarocks.org/releases/luarocks-3.4.0.tar.gz

# Note: TRAVIS_BUILD_DIR=/home/travis/build/bluebird75/luaunit/
LUA_HOME_DIR=$TRAVIS_BUILD_DIR/install/$LUA
LUAROCK_HOME_DIR=$TRAVIS_BUILD_DIR/install/luarocks

# setup a wide path
export PATH=$HOME/.lua:${LUAROCK_HOME_DIR}/bin:${PATH}

case $LUA in
"lua5.1")
    LUA_SOURCE_URL=http://www.lua.org/ftp/lua-5.1.5.tar.gz
    LUA_BUILD_DIR=lua-5.1.5
    LUAJIT="no"
    LUAROCKS_CONFIGURE_ARGS=--with-lua="$LUA_HOME_DIR"
    LUAROCKS_CONFIGURE_ARGS2=
    ;;
"lua5.2")
    LUA_SOURCE_URL=http://www.lua.org/ftp/lua-5.2.4.tar.gz
    LUA_BUILD_DIR=lua-5.2.4
    LUAJIT="no"
    LUAROCKS_CONFIGURE_ARGS=--with-lua="$LUA_HOME_DIR"
    LUAROCKS_CONFIGURE_ARGS2=
    ;;
"lua5.3")
    LUA_SOURCE_URL=http://www.lua.org/ftp/lua-5.3.3.tar.gz
    LUA_BUILD_DIR=lua-5.3.3
    LUAJIT="no"
    LUAROCKS_CONFIGURE_ARGS=--with-lua="$LUA_HOME_DIR"
    LUAROCKS_CONFIGURE_ARGS2=
    ;;
"lua5.4")
    LUA_SOURCE_URL=http://www.lua.org/ftp/lua-5.4.0.tar.gz
    LUA_BUILD_DIR=lua-5.4.0
    LUAJIT="no"
    LUAROCKS_CONFIGURE_ARGS=--with-lua="$LUA_HOME_DIR"
    LUAROCKS_CONFIGURE_ARGS2=
    ;;
"luajit2.0")
    LUA_SOURCE_URL=https://luajit.org/download/LuaJIT-2.0.5.tar.gz
    LUA_BUILD_DIR=LuaJIT-2.0.5
    LUAJIT="yes"
    LUAROCKS_CONFIGURE_ARGS=--lua-suffix=jit
    LUAROCKS_CONFIGURE_ARGS2=--with-lua-include="$LUA_HOME_DIR/include/luajit-2.0"
    ;;
"luajit2.1")
    LUA_SOURCE_URL=https://luajit.org/download/LuaJIT-2.1.0-beta3.tar.gz
    LUA_BUILD_DIR=LuaJIT-2.1.0-beta3
    LUAJIT="yes"
    LUAROCKS_CONFIGURE_ARGS=--lua-suffix=jit
    LUAROCKS_CONFIGURE_ARGS2=--with-lua-include="$LUA_HOME_DIR/include/luajit-2.1"
    ;;
esac


# Set the variable PLATFORM to one of the following:
# - linux
# - macosx

if [ -z "${PLATFORM:-}" ]; then
  PLATFORM=$TRAVIS_OS_NAME;
fi

if [ "$PLATFORM" == "osx" ]; then
  PLATFORM="macosx";
fi

# Allow running not on travis
if [ -z "$PLATFORM" ]; then
  if [ "$(uname)" == "Linux" ]; then
    PLATFORM="linux";
  else
    PLATFORM="macosx";
  fi;
fi


mkdir $HOME/.lua

if [ -e $LUA_HOME_DIR ]
then
    echo ">> Using cached version of $LUA_HOME_DIR and luarocks"
    echo "Content:"
    find $LUA_HOME_DIR -print
    find $LUAROCK_HOME_DIR -print

    # remove links to other version of lua and luarocks
    rm -f $HOME/.lua/lua
    rm -f $HOME/.lua/luajit
    rm -f $HOME/.lua/luac
    rm -f $HOME/.lua/luarocks

    # recreating the links 
    if [ "$LUAJIT" == "yes" ]; then
        ln -s $LUA_HOME_DIR/bin/luajit $HOME/.lua/luajit
        ln -s $LUA_HOME_DIR/bin/luajit $HOME/.lua/lua
    else
        ln -s $LUA_HOME_DIR/bin/lua $HOME/.lua/lua
        ln -s $LUA_HOME_DIR/bin/luac $HOME/.lua/luac
    fi
    ln -s $LUAROCK_HOME_DIR/bin/luarocks $HOME/.lua/luarocks

    # installation is ok ?
    lua -v
    luarocks --version
    
else # -e $LUA_HOME_DIR

    echo ">> Compiling lua into $LUA_HOME_DIR"

    mkdir -p "$LUA_HOME_DIR"

    echo ">> Downloading $LUA from $LUA_SOURCE_URL"
    curl $LUA_SOURCE_URL | tar xz
    cd $LUA_BUILD_DIR


    if [ "$LUAJIT" == "yes" ]; then

        if [ "$LUA" == "luajit2.1" ]; then
            # force the INSTALL_TNAME to be luajit
            perl -i -pe 's/INSTALL_TNAME=.+/INSTALL_TNAME= luajit/' Makefile
        fi

        echo ">> Compiling LuaJIT"
        make && make install PREFIX="$LUA_HOME_DIR"

        ln -s $LUA_HOME_DIR/bin/luajit $HOME/.lua/luajit
        ln -s $LUA_HOME_DIR/bin/luajit $HOME/.lua/lua

    else # $LUAJIT == "yes"

        # adjust numerical precision if requested with LUANUMBER=float
        if [ "$LUANUMBER" == "float" ]; then
            if [ "$LUA" == "lua5.3" -o "$LUA" == "lua5.4" ]; then
                # for Lua 5.3 we can simply adjust the default float type
                perl -i -pe "s/#define LUA_FLOAT_TYPE\tLUA_FLOAT_DOUBLE/#define LUA_FLOAT_TYPE\tLUA_FLOAT_FLOAT/" src/luaconf.h
            else
                # modify the basic LUA_NUMBER type
                perl -i -pe 's/#define LUA_NUMBER_DOUBLE/#define LUA_NUMBER_FLOAT/' src/luaconf.h
                perl -i -pe "s/LUA_NUMBER\tdouble/LUA_NUMBER\tfloat/" src/luaconf.h
                #perl -i -pe "s/LUAI_UACNUMBER\tdouble/LUAI_UACNUMBER\tfloat/" src/luaconf.h
                # adjust LUA_NUMBER_SCAN (input format)
                perl -i -pe 's/"%lf"/"%f"/' src/luaconf.h
                # adjust LUA_NUMBER_FMT (output format)
                perl -i -pe 's/"%\.14g"/"%\.7g"/' src/luaconf.h
                # adjust lua_str2number conversion
                perl -i -pe 's/strtod\(/strtof\(/' src/luaconf.h
                # this one is specific to the l_mathop(x) macro of Lua 5.2
                perl -i -pe 's/\t\t\(x\)/\t\t\(x##f\)/' src/luaconf.h
            fi
        fi

        # Build Lua without backwards compatibility for testing
        perl -i -pe 's/-DLUA_COMPAT_(ALL|5_2)//' src/Makefile

        echo ">> Compiling $LUA"
        make $PLATFORM
        make INSTALL_TOP="$LUA_HOME_DIR" install 

        ln -s $LUA_HOME_DIR/bin/lua $HOME/.lua/lua
        ln -s $LUA_HOME_DIR/bin/luac $HOME/.lua/luac
        
    fi # $LUAJIT == "yes"

    # cleanup LUA build dir
    rm -rf $LUA_BUILD_DIR

    # lua is OK ?
    echo ">> lua -v"
    lua -v 

    echo ">> Downloading luarocks"
    curl --location $LUAROCKS_URL | tar xz 

    cd luarocks-$LUAROCKS_VERSION

    echo ">> Compiling luarocks"
    ./configure $LUAROCKS_CONFIGURE_ARGS $LUAROCKS_CONFIGURE_ARGS2 --prefix="$LUAROCK_HOME_DIR";

    make build && make install 

    # cleanup luarocks
    rm -rf luarocks-$LUAROCKS_VERSION

    ln -s $LUAROCK_HOME_DIR/bin/luarocks $HOME/.lua/luarocks
    echo ">> luarocks --version"
    luarocks --version 
    echo ">> luarocks install luacheck"
    luarocks install luacheck 
    echo ">> luarocks install luacov"
    luarocks install luacov 
    echo ">> luarocks install luacov-coversall"
    luarocks install luacov-coveralls 

fi # -e $LUA_HOME_DIR

echo "Setting lua path to luarock user tree "
eval $(luarocks path --bin)

lua -l luacov -v

cd $TRAVIS_BUILD_DIR

# To make travis happy, we must no fail on unassigned variables so reset this option to its default value
set +u 

