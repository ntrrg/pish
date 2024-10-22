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
  debian* )
    ORIGIN_PKG="$ORIGIN_PKG.linux"
    PACKAGE="$PACKAGE-linux"
    ;;

  * )
    echo "Unsupported OS '$OS'"
    false
    ;;
esac

if [ "$ARCH" != "x86_64" ]; then
  echo "Unsupported OS architecture '$ARCH'"
  false
fi

ORIGIN_PKG="$ORIGIN_PKG.$ARCH.tar.xz"
PACKAGE="$PACKAGE-$ARCH.tar.xz"

