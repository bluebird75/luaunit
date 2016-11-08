import subprocess, sys, os, shutil, os.path, optparse

VERSION='3.2'
RELEASE_NAME='luaunit-%s' % VERSION
RELEASE_DIR='release/' + RELEASE_NAME + '/'
RELEASE_TAG='LUAUNIT_V3_2_1'
RELEASE_DIR='release/' + RELEASE_NAME + '/'
TARGET_ZIP=RELEASE_NAME + '.zip'
TARGET_TGZ=RELEASE_NAME + '.tgz'
REPO_PATH='d:/work/luaunit/luaunit-git/luaunit2/'

# LUA50='d:/program/dev/lua/lua50/lua50.exe'
LUA51='d:/program/dev/lua/lua51/lua51.exe'
LUA52='d:/program/dev/lua/lua52/lua52.exe'
LUA53='d:/program/dev/lua/lua53/lua53.exe'

ALL_LUA = ( 
    (LUA53, 'lua 5.3'), 
    (LUA52, 'lua 5.2'), 
    (LUA51, 'lua 5.1'), 
#    (LUA50, 'lua 5.0'),
)

os.environ["nodosfilewarning"] = "1"

def report( s ):
    print( '[[[[[[[[[[[[[ %s ]]]]]]]]]]]]]' % s )

def run_tests():
    '''Run tests with all versions of lua'''
    for lua, luaversion in ALL_LUA:
        report( 'Running unit-tests tests with %s' % luaversion )
        retcode = subprocess.call( [lua, 'run_unit_tests.lua'] )
        if retcode != 0:
            report( 'Invalid retcode when running tests: %d' % retcode )
            sys.exit( retcode )
        report( 'Running functional tests tests with %s' % luaversion )
        retcode = subprocess.call( [lua, 'run_functional_tests.lua'] )
        if retcode != 0:
            report( 'Invalid retcode when running tests: %d' % retcode )
            sys.exit( retcode )
    report( 'All tests succeed!' )

def run_example():
    for lua, luaversion in ALL_LUA:
        report( 'Running examples with %s' % luaversion )
        retcode = subprocess.call( [lua, 'example_with_luaunit.lua'] )
        if retcode != 12:
            report( 'Invalid retcode when running examples: %d' % retcode )
            sys.exit( retcode )
    report( 'All examples ran!' )


def packageit():
    shutil.rmtree('release', True)
    try:
        os.mkdir('release')
    except OSError:
        pass
    subprocess.check_call(['d:/program/utils/Git/bin/git.exe', 'clone', '--no-hardlinks', '--branch', RELEASE_TAG, REPO_PATH, RELEASE_DIR])
    os.chdir( RELEASE_DIR )

    # Release dir cleanup 
    shutil.rmtree('.git')
    os.unlink('.gitignore')
    run_tests()
    run_example()
    makedoc()
    shutil.rmtree('doc/_build')

    # Packaging
    os.chdir('..')
    report('Start packaging')
    shutil.make_archive(RELEASE_NAME, 'zip', root_dir='.', base_dir=RELEASE_NAME )
    shutil.make_archive(RELEASE_NAME, 'gztar', root_dir='.', base_dir=RELEASE_NAME )
    report('Zip and tgz ready!')

def help():
    print( 'Available actions:')
    for opt in OptToFunc:
        print( '\t%s' % opt )

def makedoc():
    os.chdir('doc')
    if os.path.exists('html'):
        shutil.rmtree('html')
    subprocess.check_call(['make.bat', 'html'])
    shutil.copytree('_build/html', 'html')
    os.chdir('..')

def install():
    installpath = '/usr/local/share/lua/'
    for lua, luaversion in ALL_LUA:
        lua,ver = luaversion.split( )
        if os.path.exists(installpath+ver):
            shutil.copy('luaunit.lua',installpath+ver)
            


OptToFunc = {
    'runtests'      : run_tests,
    'runexample'    : run_example,
    'packageit'     : packageit,
    'makedoc'       : makedoc,
    'install'       : install,
    'help'          : help,
}

if __name__ == '__main__':
    doingNothing = True
    for arg in sys.argv[1:]:
        if arg in OptToFunc:
            doingNothing = False
            OptToFunc[arg]()
        else:
            print( 'No such action :', arg )
            sys.exit(-1)

    if doingNothing:
        help()



