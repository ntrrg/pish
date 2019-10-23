# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

#########
# RULES #
#########
# SUPER_USER=false
# ENV=
# EXEC_MODE=local
# BIN_DEPS=docker
#########

main() {
  cp -f "$PACKAGE" "$BASEPATH/bin/docker-compose"
  chmod +x "$BASEPATH/bin/docker-compose"
}

get_latest_release() {
  get_latest_github_release "docker/compose"
}

is_installed() {
  which docker-compose
}

MIRROR="https://github.com/docker/compose/releases/download/$RELEASE"
ORIGIN_PKG="docker-compose"
PACKAGE="docker-compose-v$RELEASE"

case "$OS" in
  debian* )
    ORIGIN_PKG="$ORIGIN_PKG-Linux"
    PACKAGE="$PACKAGE-linux"
    ;;

  * )
    echo "Unsupported OS '$OS'"
    false
    ;;
esac

if [ "$ARCH" != "x86_64" ]; then
  echo "Unsupported OS architecture '$ARCH'"
  false
fi

ORIGIN_PKG="$ORIGIN_PKG-$ARCH"
PACKAGE="$PACKAGE-$ARCH"

