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
  ERR_CODE="$?"
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

get_latest_release() {
  echo "latest"
}

is_installed() {
  return 1
}

