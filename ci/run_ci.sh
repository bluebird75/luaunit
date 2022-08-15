echo ===== CI emulation mode =====
rm -rf $HOME/.lua

# export LUA=luajit2.1
export LUA=lua5.4

export CI_WORKDIR=`pwd`
export PLATFORM=linux
export LUANUMBER=double

# erase previous builds
rm -rf $CI_WORKDIR/install

source ci/setup_lua.sh
lua -v -lluacov run_unit_tests.lua --shuffle          
lua run_functional_tests.lua --coverage
luacheck example_with_luaunit.lua luaunit.lua run_unit_tests.lua run_functional_tests.lua test/
luacov-coveralls -v --include %./luaunit.lua
