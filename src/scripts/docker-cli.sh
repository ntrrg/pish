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
  case "$OS" in
    debian* )
      if [ "$EXEC_MODE" = "system" ]; then
        run_su dpkg -i "$PACKAGE"
      else
        DEST="$TMP_DIR/docker-cli"
        mkdir -p "$DEST"
        dpkg -x "$PACKAGE" "$DEST"
        cd "$DEST"
        # shellcheck disable=SC2046
        cp -af $(ls -A) "$BASEPATH"
      fi
      ;;
  esac
}

clean() {
  case "$STAGE" in
    main )
      rm -rf "$TMP_DIR/docker-cli"
      ;;
  esac
}

get_latest_release() {
  get_latest_github_tag "docker/cli"
}

is_installed() {
  which docker
}

MIRROR="https://download.docker.com/linux"
ORIGIN_PKG="docker-ce-cli_$RELEASE"
PACKAGE="docker-cli-v$RELEASE-$OS-$ARCH"

case "$OS" in
  debian* )
    MIRROR="$MIRROR/debian/dists"
    ORIGIN_PKG="$ORIGIN_PKG~3-0~debian"

    case "$OS" in
      *-10 )
        MIRROR="$MIRROR/buster"
        ORIGIN_PKG="$ORIGIN_PKG-buster"
        ;;

      * )
        echo "Unsupported Debian version '$OS'"
        false
        ;;
    esac

    MIRROR="$MIRROR/pool/stable"

    case "$ARCH" in
      x86_64 )
        MIRROR="$MIRROR/amd64"
        ORIGIN_PKG="${ORIGIN_PKG}_amd64"
        ;;

      * )
        echo "Unsupported OS architecture '$ARCH'"
        false
        ;;
    esac

    ORIGIN_PKG="$ORIGIN_PKG.deb"
    PACKAGE="$PACKAGE.deb"
    ;;

  * )
    echo "Unsupported OS '$OS'"
    false
    ;;
esac

