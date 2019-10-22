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

get_checksum() {
  case "$1" in
    docker-ce-v19.03.2-debian-10-x86_64.deb )
      echo "9b6c0baa5ef3d273a19942005776fc76505f78a314904225fc507af0dbb3f66c57437c0247c77bfc461ed449e89e2df6d6bd218872005cea868f4d64b932c22b"
      ;;

    docker-ce-v18.09.5-debian-10-x86_64.deb )
      echo "49a548df57fd844044991957aae4711a27b28cd2fc38c813987c227f10d0fe92f3ceb47ba09dcf803ddf0a8f80dd39fa568a9016ca9769619fa9f6c45616b886"
      ;;
  esac
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

