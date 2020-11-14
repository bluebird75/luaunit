import os, subprocess

PATH_LUA_51='d:\\program\\dev\\lua\\lua51'
PATH_LUA_52='d:\\program\\dev\\lua\\lua52'
PATH_LUA_53='d:\\program\\dev\\lua\\lua53'
PATH_LUA_54='d:\\program\\dev\\lua\\lua54'
PATH_LUAJIT_20='d:\\program\\dev\\lua\\luajit'
PATH_LUAJIT_21='d:\\program\\dev\\lua\\luajit21'

PATH_LUACHECK='d:\\program\\dev\\lua\\luarocks\\systree\\bin\\luacheck.bat'

ALL_PATH = [
	('Lua 5.1', PATH_LUA_51),
	('Lua 5.2', PATH_LUA_52),
	('Lua 5.3', PATH_LUA_53),
	('Lua 5.4', PATH_LUA_54), 
	('LuaJIT 2.0', PATH_LUAJIT_20), 
	('LuaJIT 2.1', PATH_LUAJIT_21),
]

def runall(target):
	for luaname, path in ALL_PATH:
		luaexe = os.path.join(path, 'lua.exe')
		print('>>>> ', luaname)
		subprocess.check_call([luaexe, target])

def run_luacheck():
	print('>>>> LuaCheck')
	subprocess.check_call([PATH_LUACHECK, 'example_with_luaunit.lua', 'luaunit.lua', 'run_unit_tests.lua', 'run_functional_tests.lua', 'test/'],
					shell=True)

def main():
	run_luacheck()
	runall('run_unit_tests.lua')
	runall('run_functional_tests.lua')

if __name__ == '__main__':
	main()


