# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

checksum() {
  # shellcheck disable=SC2153
  [ "$NOCHECKSUM" = "true" ] && return 0
  FILE="$1"
  CHECKSUM_FILE="$2"

  if ! sha256sum -c --quiet "$CHECKSUM_FILE" < "$FILE" 2> /dev/null; then
    echo "Invalid checksum for '$FILE'"
    echo "  Want: $(cat "$CHECKSUM_FILE")"
    echo "  Got: $(sha256sum < "$FILE")"
    return 1
  fi
}

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

  if [ "$FILE" = "-" ]; then
    wget -qO - "$URL"
    return 0
  fi

  CHECKSUM_FILE="$CHECKSUMS_DIR/$FILE.sha256"

  if [ "$NOCHECKSUM" != "true" ] && [ ! -f "$CHECKSUM_FILE" ]; then
    wget -"$(debug not printf "q")"O "$CHECKSUM_FILE" \
      "$CHECKSUMS_MIRROR/$(basename "$CHECKSUM_FILE")" ||
    (rm -f "$CHECKSUM_FILE"; return 1)
  fi

  if [ -f "$FILE" ] && checksum "$FILE" "$CHECKSUM_FILE" > /dev/null; then
    return 0
  fi

  wget -"$(debug not printf "q")"cO "$FILE" "$URL"
  checksum "$FILE" "$CHECKSUM_FILE"
}

download_package() {
  MIRROR="$1"
  PACKAGE="$2"
  ORIGIN_PKG="$3"

  if [ -n "$PKG_MIRROR" ]; then
    download_file "$PKG_MIRROR/$PACKAGE"
  else
    download_file "$MIRROR/${ORIGIN_PKG:-$PACKAGE}" "$PACKAGE"
  fi
}

get_latest_github_release() {
  wget -qO - "https://api.github.com/repos/$1/releases/latest" |
    grep -m 1 "tag_name" |
    cut -d '"' -f 4 |
    sed "s/^v//"
}

get_latest_github_tag() {
  wget -qO - "https://api.github.com/repos/$1/tags" |
    grep -v "\-\(alpha\|beta\|rc\)[0-9]*\",$" |
    grep -m 1 "name" |
    cut -d '"' -f 4 |
    sed "s/^v//"
}

get_latest_github_tag_all() {
  wget -qO - "https://api.github.com/repos/$1/tags" |
    grep -m 1 "name" |
    cut -d '"' -f 4 |
    sed "s/^v//"
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

