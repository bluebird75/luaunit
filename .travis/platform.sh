# Set the variable PLATFORM to one of the following:
# - linux
# - macosx

if [ -z "${PLATFORM:-}" ]; then
  PLATFORM=$TRAVIS_OS_NAME;
fi

if [ "$PLATFORM" == "osx" ]; then
  PLATFORM="macosx";
fi

if [ -z "$PLATFORM" ]; then
  if [ "$(uname)" == "Linux" ]; then
    PLATFORM="linux";
  else
    PLATFORM="macosx";
  fi;
fi
