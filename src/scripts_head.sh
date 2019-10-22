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
  cd "$CACHE_DIR"
  download
}

download() {
  if [ -n "$MIRROR" ] && [ -n "$PACKAGE" ]; then
    if [ -n "$PKG_MIRROR" ]; then
      download_file "$PKG_MIRROR/$PACKAGE"
    else
      download_file "$MIRROR/${ORIGIN_PKG:-$PACKAGE}" "$PACKAGE"
    fi
  fi
}

_main() {
  cd "$CACHE_DIR"

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

get_checksum() {
  true
}

get_latest_release() {
  echo "latest"
}

is_installed() {
  return 1
}

