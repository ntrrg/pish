# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

#########
# RULES #
#########
# SUPER_USER=false
# ENV=
# EXEC_MODE=local
# BIN_DEPS=
#########

main() {
  tar --strip-components 1 --exclude "*.txt" -C "$BASEPATH/bin" -xpf "$PACKAGE"
}

get_checksum() {
  case "$1" in
    shellcheck-v0.7.0-linux-x86_64.tar.xz )
      echo "30f4cfacdf9024a4f4c8233842f40a6027069e81cf5529f2441b22856773abcd716ee92d2303ad3cda5eaeecac3161e5980c0eedeb4ffa077d5c15c7f356512e"
      ;;

    shellcheck-v0.6.0-linux-x86_64.tar.xz )
      echo "c48d8f510fc57eaf394435143ee29801c83bcdd1daa46222c43f16c2caad38de58277ef2b4cf34205ea0ddd4e6238eee77b08be3502954d0587f040445e473a6"
      ;;
  esac
}

get_latest_release() {
  get_latest_github_tag "koalaman/shellcheck"
}

is_installed() {
  which shellcheck
}

MIRROR="https://storage.googleapis.com/shellcheck"
ORIGIN_PKG="shellcheck-v$RELEASE"
PACKAGE="shellcheck-v$RELEASE"

case "$OS" in
  * )
    ORIGIN_PKG="$ORIGIN_PKG.linux"
    PACKAGE="$PACKAGE-linux"
    ;;
esac

ORIGIN_PKG="$ORIGIN_PKG.$ARCH.tar.xz"
PACKAGE="$PACKAGE-$ARCH.tar.xz"

