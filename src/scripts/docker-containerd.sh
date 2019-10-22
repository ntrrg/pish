# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

#########
# RULES #
#########
# SUPER_USER=true
# ENV=!container
# EXEC_MODE=system
# BIN_DEPS=
#########

#########
# ENV_* #
#########
# CONTAINER: if 'true', the environment is a container.
# SERVER: if 'true', the environment is a server.
#########

check() {
  case "$OS" in
    debian* )
      which_print systemctl
      ;;
  esac
}

main() {
  case "$OS" in
    debian* )
      run_su dpkg -i "$PACKAGE"
      ;;
  esac

  if [ "$ENV_SERVER" != "true" ]; then
    case "$OS" in
      debian* )
        run_su systemctl stop containerd.service
        run_su systemctl disable containerd.service
        ;;
    esac
  fi
}

is_installed() {
  which containerd
}

MIRROR="https://download.docker.com/linux"
ORIGIN_PKG="containerd.io_$RELEASE"
PACKAGE="docker-containerd-v$RELEASE-$OS-$ARCH"

case "$OS" in
  debian* )
    MIRROR="$MIRROR/debian/dists"

    case "$OS" in
      *-10 )
        MIRROR="$MIRROR/buster"
        ;;

      * )
        echo "Unsupported Debian version '$OS'"
        false
        ;;
    esac

    MIRROR="$MIRROR/pool/stable"

    case "$ARCH" in
      x86_64 )
        MIRROR="$MIRROR/amd64"
        ORIGIN_PKG="${ORIGIN_PKG}_amd64"
        ;;

      * )
        echo "Unsupported OS architecture '$ARCH'"
        false
        ;;
    esac

    ORIGIN_PKG="$ORIGIN_PKG.deb"
    PACKAGE="$PACKAGE.deb"
    ;;

  * )
    echo "Unsupported OS '$OS'"
    false
    ;;
esac

