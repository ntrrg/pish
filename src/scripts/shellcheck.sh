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
  return 0
}

main() {
  cd "$TMP_DIR"

  if [ "$FORCE" = "false" ] && which shellcheck; then
    if shellcheck --version | grep -q "version: $RELEASE$"; then
      echo "Shellcheck v$RELEASE is already installed."
      return 0
    fi
  fi

  tar --strip-components 1 --exclude "*.txt" \
    -C "$BASEPATH/bin" -xpf "$CACHE_DIR/$PACKAGE"
  return 0
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

  return 0
}

get_latest_release() {
  wget -qO - 'https://api.github.com/repos/koalaman/shellcheck/tags' |
    grep -m 1 "name" |
    cut -d '"' -f 4 |
    sed "s/^v//"

  return 0
}

if [ -z "$RELEASE" ] || [ "$RELEASE" = "latest" ]; then
  RELEASE="$(get_latest_release)"
fi

PACKAGE="shellcheck-v$RELEASE.linux.$ARCH.tar.xz"

