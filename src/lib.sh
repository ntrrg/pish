# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

checksum() {
  # shellcheck disable=SC2153
  [ "$NOCHECKSUM" = "true" ] && return 0
  local FILE="$1"
  local CHECKSUM_FILE="${2:-$CHECKSUMSDIR/$(basename "$FILE").sha256}"

  if ! sha256sum -c --quiet "$CHECKSUM_FILE" < "$FILE" 2> /dev/null; then
    echo "Invalid checksum for '$FILE'"
    echo "  Want: $(cat "$CHECKSUM_FILE")"
    echo "  Got: $(sha256sum < "$FILE")"
    return 1
  fi
}

debug() {
  local VALUE="true"

  if [ "$1" = "not" ]; then
    VALUE="false"
    shift
  fi

  if [ "$DEBUG" = "$VALUE" ]; then
    "$@"
  fi
}

download_and_check_file() {
  local URL="$1"
  local FILE="${2:-$(basename "$URL")}"

  if [ "$NOCHECKSUM" = "true" ]; then
    download_file "$URL" "$FILE"
    return 0
  fi

  local CHECKSUM_FILE="$CHECKSUMSDIR/$(basename "$FILE").sha256"

  if [ ! -f "$CHECKSUM_FILE" ]; then
    download_file "$CHECKSUMS_MIRROR/$(basename "$CHECKSUM_FILE")" \
      "$CHECKSUM_FILE" ||
    (rm -f "$CHECKSUM_FILE"; return 1)
  fi

  if [ -f "$FILE" ] && checksum "$FILE" "$CHECKSUM_FILE" > /dev/null; then
    return 0
  fi

  download_file "$URL" "$FILE"
  checksum "$FILE" "$CHECKSUM_FILE"
}

download_file() {
  local URL="$1"
  local FILE="${2:-$(basename "$URL")}"

  if [ "$FILE" = "-" ]; then
    wget -qO - "$URL"
    return 0
  fi

  wget -"$(debug not printf "q")"O "$FILE" "$URL"
}

download_package() {
  local MIRROR="$1"
  local PACKAGE="$2"
  local ORIGIN_PKG="$3"

  if [ -n "$PKG_MIRROR" ]; then
    download_and_check_file "$PKG_MIRROR/$PACKAGE"
  else
    download_and_check_file "$MIRROR/${ORIGIN_PKG:-$PACKAGE}" "$PACKAGE"
  fi
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

