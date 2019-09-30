# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

#########
# RULES #
#########
# SUPER_USER=true
# ENV=!container
# EXEC_MODE=system
# BIN_DEPS=b2sum;wget
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
      which_print systemctl
      ;;
  esac

  return 0
}

download() {
  cd "$CACHE_DIR"

  if [ -f "$PACKAGE" ] && checksum "$PACKAGE"; then
    return 0
  fi

  download_file "$MIRROR/$PACKAGE"
  checksum "$PACKAGE"
  return 0
}

main() {
  cd "$TMP_DIR"

  if [ "$FORCE" = "false" ] && is_installed; then
    echo "Docker v$RELEASE is already installed."
    return 0
  fi

  case "$OS" in
    debian* )
      run_su dpkg -i "$PACKAGE" || run_su apt-get install -fy
      ;;

    * )
      echo "Unsupported os '$OS'"
      false
      ;;
  esac

  if [ "$ENV_SERVER" != "true" ]; then
    case "$OS" in
      debian-* )
        run_su systemctl stop docker.service
        ;;
    esac
  fi

  return 0
}

checksum() {
  FILE="$1"

  case "$FILE" in
    docker-ce_18.09.5~3-0~debian-buster_amd64.deb )
      CHECKSUM="49a548df57fd844044991957aae4711a27b28cd2fc38c813987c227f10d0fe92f3ceb47ba09dcf803ddf0a8f80dd39fa568a9016ca9769619fa9f6c45616b886"
      ;;

    * )
      echo "Invalid file '$FILE'"
      return 1
      ;;
  esac

  if ! b2sum "$FILE" | grep -q "$CHECKSUM"; then
    echo "Invalid checksum for '$FILE'"
    return 1
  fi

  return 0
}

get_latest_release() {
  wget -qO - 'https://api.github.com/repos/docker/docker-ce/tags' |
    grep -m 1 "tag_name" |
    cut -d '"' -f 4 |
    sed "s/^v//"

  return 0
}

is_installed() {
  which dockerd

  if dockerd --version | grep -q "version $RELEASE,"; then
    return 0
  fi

  return 1
}

if [ -z "$RELEASE" ] || [ "$RELEASE" = "latest" ]; then
  RELEASE="$(get_latest_release)"
fi

MIRROR="https://download.docker.com/linux"
PACKAGE="docker-ce_$RELEASE"

case "$OS" in
  debian* )
    MIRROR="$MIRROR/debian/dists"
    PACKAGE="$PACKAGE~3-0~debian"

    case "$OS" in
      *-10 )
        MIRROR="$MIRROR/buster"
        PACKAGE="$PACKAGE-buster"
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
        PACKAGE="${PACKAGE}_amd64"
        ;;

      * )
        echo "Unsupported OS architecture '$ARCH'"
        false
        ;;
    esac

    PACKAGE="$PACKAGE.deb"
    ;;

  * )
    echo "Unsupported os '$OS'"
    false
    ;;
esac

