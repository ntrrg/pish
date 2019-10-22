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

get_checksum() {
  case "$1" in
    docker-containerd-v1.2.6-3-debian-10-x86_64.deb )
      echo "477363cabb45521e77563f5d1ffca102965cda6f20150b36329d372d53fc65d257a5efde6ce1304afd9dfb82a2982ae14cf0a5300fc41926b0055ba785756016"
      ;;

    docker-containerd-v1.2.5-1-debian-10-x86_64.deb )
      echo "e9f3b3d02ff32740805d24202b1687238a38d954103bb5e90160ae871e39e88ad8002b0238a5ceb00e623308ea51b876cf872de9595f6574ffe8c171a10b3cc2"
      ;;
  esac
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

