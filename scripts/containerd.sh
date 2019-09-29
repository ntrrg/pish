#!/bin/sh
# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

set -e
trap _clean EXIT

export STAGE="$1"

check() {
  return 0
}

download() {
  return 0
}

main() {
  return 0
}

clean() {
  return 0
}

_clean() {
  ERR_CODE="$?"
  set +e
  trap - EXIT
  clean || true
  return "$ERR_CODE"
}

# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

debug() {
  VALUE="true"

  if [ "$1" = "not" ]; then
    VALUE="false"
    shift
  fi

  if [ "$DEBUG" = "$VALUE" ]; then
    "$@"
  fi

  return 0
}

download_file() {
  URL="$1"
  FILE="${2:-$(basename "$URL")}"

  wget -"$(debug not echo "q")"O "$FILE" "$URL" || (
    ERR="$?"
    echo "[FAIL]"
    rm -f "$FILE"
    return "$ERR"
  )

  return 0
}

get_os() {
  case "$(uname -s)" in
    Darwin* )
      echo "macos"
      ;;

    * )
      if which lsb_release; then
        echo "$(lsb_release -si | tr "[:upper:]" "[:lower:]")-$(lsb_release -sr)"
      elif which getprop; then
        echo "android-$(getprop ro.build.version.release)"
      else
        echo "all"
      fi
      ;;
  esac

  return 0
}

run_su() {
  CMD="su -c '%s' -"
  ARGS=""

  if [ "$SUDO" = "true" ]; then
    CMD="sudo '%s'"
  fi

  while [ $# -ne 0 ]; do
    ARGS="$ARGS $(echo "$1" | sed "s/ /\\\\ /g")"
    shift
  done

  # shellcheck disable=2059
  echo "$SU_PASSWD" | eval "$(printf "$CMD" "cd $PWD && $ARGS")"
  return 0
}

which() {
  command -v "$1" > /dev/null
  return 0
}

which_print() {
  which "$1" || (echo "'$1' not found"; return 1)
  return 0
}

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

# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

if [ $# -eq 0 ] || [ "$1" = "all" ]; then
  download
  main
else
  $1
fi

