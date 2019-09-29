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
    echo "Containerd v$RELEASE is already installed."
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
        run_su systemctl stop containerd.service
        ;;
    esac
  fi

  return 0
}

checksum() {
  FILE="$1"

  case "$FILE" in
    containerd.io_1.2.5-1_amd64.deb )
      CHECKSUM="e9f3b3d02ff32740805d24202b1687238a38d954103bb5e90160ae871e39e88ad8002b0238a5ceb00e623308ea51b876cf872de9595f6574ffe8c171a10b3cc2"
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
  wget -qO - 'https://api.github.com/repos/containerd/containerd/tags' |
    grep -v "alpha\|beta" |
    grep -m 1 "name" |
    cut -d '"' -f 4 |
    sed "s/^v//"

  return 0
}

is_installed() {
  which dockerd

  if containerd --version | grep -q "containerd $(echo "$RELEASE" | cut -d "-" -f 1) "; then
    return 0
  fi

  return 1
}

if [ -z "$RELEASE" ] || [ "$RELEASE" = "latest" ]; then
  RELEASE="$(get_latest_release)"
fi

MIRROR="https://download.docker.com/linux"
PACKAGE="containerd.io_$RELEASE"

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

