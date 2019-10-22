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

get_checksum() {
  case "$1" in
    docker-compose-v1.24.1-linux-x86_64 )
      echo "432b26dc59fcf9b9997e36de7aa278b02293f39411159e73ab73b3157f27e59a273c491de57312f411322048fb0f669f41b82d390fc5524d2633d429c459df22"
      ;;
  esac
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
  * )
    ORIGIN_PKG="$ORIGIN_PKG-Linux"
    PACKAGE="$PACKAGE-linux"
    ;;
esac

ORIGIN_PKG="$ORIGIN_PKG-$ARCH"
PACKAGE="$PACKAGE-$ARCH"

