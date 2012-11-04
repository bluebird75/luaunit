import subprocess, sys, os, shutil, os.path

VERSION='1.5'
RELEASE_NAME='luaunit-%s' % VERSION
RELEASE_DIR='release/' + RELEASE_NAME
TARGET_ZIP=RELEASE_NAME + '.zip'
TARGET_TGZ=RELEASE_NAME + '.tgz'
REPO_PATH='d:/work/luaunit/luaunit-git/luaunit/'

LUA50='d:/program/lua/lua50/lua50.exe'
LUA51='d:/program/lua/lua51/lua51.exe'
LUA52='d:/program/lua/lua52/lua52.exe'

ALL_LUA = ( 
    (LUA52, 'lua 5.2'), 
    (LUA51, 'lua 5.1'), 
#    (LUA50, 'lua 5.0'),
)

os.environ["nodosfilewarning"] = "1"

def report( s ):
    print '[[[[[[[[[[[[[ %s ]]]]]]]]]]]]]' % s

def run_tests():
    '''Run tests with all versions of lua'''
    for lua, luaversion in ALL_LUA:
        report( 'Running tests with %s' % luaversion )
        retcode = subprocess.call( [lua, 'test_luaunit.lua'] )
        if retcode != 0:
            report( 'Invalid retcode when running tests: %d' % retcode )
            sys.exit( retcode )
    report( 'All tests succeed!' )

def run_example():
    for lua, luaversion in ALL_LUA:
        report( 'Running examples with %s' % luaversion )
        retcode = subprocess.call( [lua, 'example_with_luaunit.lua'] )
        if retcode != 6:
            report( 'Invalid retcode when running examples: %d' % retcode )
            sys.exit( retcode )
    report( 'All examples ran!' )

def packageit():
    shutil.rmtree('release', True)
    try:
        os.mkdir('release')
    except OSError:
        pass
    subprocess.check_call(['c:/Program Files/Git/bin/git.exe', 'clone', REPO_PATH, RELEASE_DIR])
    os.chdir( RELEASE_DIR )
    shutil.rmtree('.git')
    os.unlink('.gitignore')
    run_tests()
    run_example()
    os.chdir('..')
    report('Start packaging')
    shutil.make_archive(RELEASE_NAME, 'zip', root_dir='.', base_dir=RELEASE_NAME )
    shutil.make_archive(RELEASE_NAME, 'gztar', root_dir='.', base_dir=RELEASE_NAME )
    report('Zip and tgz ready!')

if __name__ == '__main__':
    # run_tests()
    # run_example()
    packageit()



# git checkout
# store version number
# generate zip and tgz
# run example with several versions of lua, check return value
