# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

#########
# RULES #
#########
# SUPER_USER=true
# ENV=!container
# EXEC_MODE=system
# BIN_DEPS=containerd;docker
#########

#########
# ENV_* #
#########
# CONTAINER: if 'true', the environment is a container.
# SERVER: if 'true', the environment is a server.
#########

check() {
  case "$OS" in
    debian-* )
      run_su command -v update-rc.d > /dev/null
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
      debian-* )
        run_su update-rc.d docker remove
        run_su systemctl stop docker.service
        run_su systemctl disable docker.service
        ;;
    esac
  fi
}

get_latest_release() {
  get_latest_github_tag "docker/docker-ce"
}

is_installed() {
  which dockerd
}

MIRROR="https://download.docker.com/linux"
ORIGIN_PKG="docker-ce_$RELEASE"
PACKAGE="docker-ce-v$RELEASE-$OS-$ARCH"

case "$OS" in
  debian* )
    MIRROR="$MIRROR/debian/dists"
    ORIGIN_PKG="$ORIGIN_PKG~3-0~debian"

    case "$OS" in
      *-10 )
        MIRROR="$MIRROR/buster"
        ORIGIN_PKG="$ORIGIN_PKG-buster"
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

