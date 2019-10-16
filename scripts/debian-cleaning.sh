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

download_file() {
  URL="$1"
  FILE="${2:-$(basename "$URL")}"

  wget -"$(debug not printf "q")"O "$FILE" "$URL" || (
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
# SUPER_USER=true
# ENV=
# EXEC_MODE=system
# BIN_DEPS=
#########

main() {
  run_su apt-get autoremove -y

  run_su rm -rf /var/cache/apt
  run_su mkdir /var/cache/apt

  run_su rm -rf /var/lib/apt/lists
  run_su mkdir /var/lib/apt/lists

  run_su rm -rf /var/log
  run_su mkdir /var/log
}
# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

if [ $# -eq 0 ] || [ "$1" = "all" ]; then
  check
  download
  main
else
  $1
fi

