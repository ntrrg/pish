#!/bin/sh
# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

set -e
trap _clean EXIT

export STAGE="$1"

check() {
  true
}

_download() {
  cd "$CACHEDIR"
  download
}

download() {
  if [ -n "$MIRROR" ] && [ -n "$PACKAGE" ]; then
    download_package "$MIRROR" "$PACKAGE" "$ORIGIN_PKG"
  fi
}

_main() {
  cd "$CACHEDIR"

  if [ "$FORCE" = "false" ] && is_installed; then
    echo "It is already installed."
    return 0
  fi

  main
}

main() {
  true
}

_clean() {
  local ERR_CODE="$?"
  set +e
  trap - EXIT
  [ "$STAGE" = "get_latest_release" ] && return "$ERR_CODE"
  clean || true
  return "$ERR_CODE"
}

clean() {
  true
}

# Helpers

get_latest_github_release() {
  local REPO="$1"

  wget -qO - "https://api.github.com/repos/$REPO/releases/latest" |
    grep -m 1 "tag_name" |
    cut -d '"' -f 4 |
    sed "s/^v//"
}

get_latest_github_tag() {
  local REPO="$1"

  wget -qO - "https://api.github.com/repos/$REPO/tags" |
    grep -v "\-\(alpha\|beta\|rc\)[0-9]*\",$" |
    grep -m 1 "name" |
    cut -d '"' -f 4 |
    sed "s/^v//"
}

get_latest_github_tag_all() {
  local REPO="$1"

  wget -qO - "https://api.github.com/repos/$REPO/tags" |
    grep -m 1 "name" |
    cut -d '"' -f 4 |
    sed "s/^v//"
}

get_latest_release() {
  echo "latest"
}

is_installed() {
  return 1
}

run_su() {
  local CMD="su -c '%s' -"
  local ARGS=""

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

