#! /bin/bash

# A script for setting up environment for travis-ci testing.
# Sets up Lua and Luarocks.
# LUA must be "lua5.1", "lua5.2" or "luajit".
# luajit2.0 - master v2.0
# luajit2.1 - master v2.1

set -eufo pipefail

LUAJIT_VERSION="2.0.4"
LUAJIT_BASE="LuaJIT-$LUAJIT_VERSION"

source .travis/platform.sh

LUA_HOME_DIR=$TRAVIS_BUILD_DIR/install/$LUA
LR_HOME_DIR=$TRAVIS_BUILD_DIR/install/luarocks

mkdir $HOME/.lua

LUAJIT="no"

if [ "$PLATFORM" == "macosx" ]; then
    if [ "$LUA" == "luajit" ]; then
        LUAJIT="yes";
    fi
    if [ "$LUA" == "luajit2.0" ]; then
        LUAJIT="yes";
    fi
    if [ "$LUA" == "luajit2.1" ]; then
        LUAJIT="yes";
    fi;
elif [ "$(expr substr $LUA 1 6)" == "luajit" ]; then
    LUAJIT="yes";
fi

if [ -e $LUA_HOME_DIR ]
then
    echo ">> Using cached version of $LUA_HOME_DIR and luarocks"
    echo "Content:"
    find $LUA_HOME_DIR -print
    find $LR_HOME_DIR -print

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
    ln -s $LR_HOME_DIR/bin/luarocks $HOME/.lua/luarocks

    # installation is ok ?
    lua -v
    luarocks --version
    luarocks list
    
else # -e $LUA_HOME_DIR

    echo ">> Compiling lua into $LUA_HOME_DIR"

    mkdir -p "$LUA_HOME_DIR"

    if [ "$LUAJIT" == "yes" ]; then

        echo ">> Downloading LuaJIT"
        if [ "$LUA" == "luajit" ]; then
            curl --location https://github.com/LuaJIT/LuaJIT/archive/v$LUAJIT_VERSION.tar.gz | tar xz;
        else
            git clone https://github.com/LuaJIT/LuaJIT.git $LUAJIT_BASE;
        fi

        cd $LUAJIT_BASE

        if [ "$LUA" == "luajit2.1" ]; then
            git checkout v2.1;
            # force the INSTALL_TNAME to be luajit
            perl -i -pe 's/INSTALL_TNAME=.+/INSTALL_TNAME= luajit/' Makefile
        fi

        echo ">> Compiling LuaJIT"
        make && make install PREFIX="$LUA_HOME_DIR"

    else # $LUAJIT == "yes"

        echo "Downloading $LUA"
        if [ "$LUA" == "lua5.1" ]; then
            curl http://www.lua.org/ftp/lua-5.1.5.tar.gz | tar xz
            cd lua-5.1.5;
        elif [ "$LUA" == "lua5.2" ]; then
            curl http://www.lua.org/ftp/lua-5.2.4.tar.gz | tar xz
            cd lua-5.2.4;
        elif [ "$LUA" == "lua5.3" ]; then
            curl http://www.lua.org/ftp/lua-5.3.3.tar.gz | tar xz
            cd lua-5.3.3;
        fi

        # adjust numerical precision if requested with LUANUMBER=float
        if [ "$LUANUMBER" == "float" ]; then
            if [ "$LUA" == "lua5.3" ]; then
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
        make INSTALL_TOP="$LUA_HOME_DIR" install;
        
    fi # $LUAJIT == "yes"

    # cleanup LUA build dir
    if [ "$LUAJIT" == "yes" ]; then
        rm -rf $LUAJIT_BASE;
    elif [ "$LUA" == "lua5.1" ]; then
        rm -rf lua-5.1.5;
    elif [ "$LUA" == "lua5.2" ]; then
        rm -rf lua-5.2.4;
    elif [ "$LUA" == "lua5.3" ]; then
        rm -rf lua-5.3.2;
    fi

    if [ "$LUAJIT" == "yes" ]; then
        ln -s $LUA_HOME_DIR/bin/luajit $HOME/.lua/luajit
        ln -s $LUA_HOME_DIR/bin/luajit $HOME/.lua/lua
    else
        ln -s $LUA_HOME_DIR/bin/lua $HOME/.lua/lua
        ln -s $LUA_HOME_DIR/bin/luac $HOME/.lua/luac
    fi

    # lua is OK ?
    lua -v

    echo ">> Downloading luarocks"
    LUAROCKS_BASE=luarocks-$LUAROCKS
    curl --location http://luarocks.org/releases/$LUAROCKS_BASE.tar.gz | tar xz

    cd $LUAROCKS_BASE

    echo ">> Compiling luarocks"
    if [ "$LUA" == "luajit" ]; then
        ./configure --lua-suffix=jit --with-lua-include="$LUA_HOME_DIR/include/luajit-2.0" --prefix="$LR_HOME_DIR";
    elif [ "$LUA" == "luajit2.0" ]; then
        ./configure --lua-suffix=jit --with-lua-include="$LUA_HOME_DIR/include/luajit-2.0" --prefix="$LR_HOME_DIR";
    elif [ "$LUA" == "luajit2.1" ]; then
        ./configure --lua-suffix=jit --with-lua-include="$LUA_HOME_DIR/include/luajit-2.1" --prefix="$LR_HOME_DIR";
    else
        ./configure --with-lua="$LUA_HOME_DIR" --prefix="$LR_HOME_DIR"
    fi

    make build && make install

    # cleanup luarocks
    rm -rf $LUAROCKS_BASE

    ln -s $LR_HOME_DIR/bin/luarocks $HOME/.lua/luarocks
    luarocks --version
    luarocks install luacheck
    luarocks install luacov-coveralls

fi # -e $LUA_HOME_DIR

cd $TRAVIS_BUILD_DIR

