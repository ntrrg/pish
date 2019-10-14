#!/bin/sh
# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

set -e
trap _clean EXIT

export STAGE="$1"

check() {
  true
}

download() {
  true
}

main() {
  true
}

clean() {
  true
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
}

deb_deps() {
  apt-cache depends \
    --recurse --no-recommends --no-suggests --no-conflicts \
    --no-breaks --no-replaces --no-enhances -qq "$@" |
  tr -d " " |
  sed "s/\(Pre\)\?Depends://" |
  grep "^\w" |
  sort -u
}

download_file() {
  URL="$1"
  FILE="${2:-$(basename "$URL")}"

  wget "$(debug not echo "-q")" -O "$FILE" "$URL" || (
    ERR="$?"
    echo "[FAIL]"
    ([ "$FILE" != "-" ] && rm -f "$FILE") || true
    return "$ERR"
  )
}

download_file_quiet() {
  DEBUG="false" download_file "$@"
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
}

which() {
  command -v "$1" > /dev/null
}

which_print() {
  if ! which "$1"; then
    echo "'$1' not found"
    return 1
  fi
}

# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

#########
# RULES #
#########
# SUPER_USER=false
# ENV=
# EXEC_MODE=local
# BIN_DEPS=b2sum;wget
#########

download() {
  cd "$CACHE_DIR"

  if [ -f "$PACKAGE" ] && checksum "$PACKAGE"; then
    return 0
  fi

  download_file "https://storage.googleapis.com/shellcheck/$PACKAGE"
  checksum "$PACKAGE"
}

main() {
  cd "$TMP_DIR"

  if [ "$FORCE" = "false" ] && is_installed; then
    echo "Shellcheck v$RELEASE is already installed."
    return 0
  fi

  tar --strip-components 1 --exclude "*.txt" \
    -C "$BASEPATH/bin" -xpf "$CACHE_DIR/$PACKAGE"
}

# Helpers

checksum() {
  FILE="$1"

  case "$FILE" in
    shellcheck-v0.6.0.linux.x86_64.tar.xz )
      CHECKSUM="c48d8f510fc57eaf394435143ee29801c83bcdd1daa46222c43f16c2caad38de58277ef2b4cf34205ea0ddd4e6238eee77b08be3502954d0587f040445e473a6"
      ;;

    shellcheck-v0.7.0.linux.x86_64.tar.xz )
      CHECKSUM="30f4cfacdf9024a4f4c8233842f40a6027069e81cf5529f2441b22856773abcd716ee92d2303ad3cda5eaeecac3161e5980c0eedeb4ffa077d5c15c7f356512e"
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
}

get_latest_release() {
  wget -qO - 'https://api.github.com/repos/koalaman/shellcheck/tags' |
    grep -m 1 "name" |
    cut -d '"' -f 4 |
    sed "s/^v//"
}

is_installed() {
  which shellcheck

  if shellcheck --version | grep -q "version: $RELEASE$"; then
    return 0
  fi

  return 1
}

if [ -z "$RELEASE" ] || [ "$RELEASE" = "latest" ]; then
  RELEASE="$(get_latest_release)"
fi

PACKAGE="shellcheck-v$RELEASE.linux.$ARCH.tar.xz"

# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

if [ $# -eq 0 ] || [ "$1" = "all" ]; then
  check
  download
  main
else
  $1
fi

