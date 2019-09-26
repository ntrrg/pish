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

  download_file "$MIRROR/$PACKAGE"
  checksum "$PACKAGE"
  return 0
}

main() {
  cd "$TMP_DIR"
  mkdir -p "docker-cli"

  # shellcheck disable=2230
  if [ "$FORCE" = "false" ] && which docker; then
    if docker version -f "{{ .Client.Version }}" | grep -q "$(echo "$RELEASE" | sed "s/^\(.\+\)~.\+$/\1/")"; then
      echo "Docker CLI v$RELEASE is already installed."
      return 0
    fi
  fi

  case "$OS" in
    debian* )
      if [ "$EXEC_MODE" = "system" ]; then
        run_su dpkg -i "$PACKAGE" || run_su apt-get install -fy
      else
        dpkg -x "$PACKAGE" "docker-cli"
        cd "docker-cli/usr"
        # shellcheck disable=SC2046
        cp -af $(ls -A) "$BASEPATH"
      fi
      ;;
  esac

  return 0
}

clean() {
  case "$STAGE" in
    main )
      rm -rf "$TMP_DIR/docker-cli"
      ;;
  esac

  return 0
}

checksum() {
  FILE="$1"

  case "$FILE" in
    docker-ce-cli_18.09.5~3-0~debian-buster_amd64.deb )
      CHECKSUM="5c3c7688f91a617d64a633d081a6a7ffb23c43292fef37819ad583c785c92c774eb5c0154adadfdce86545bf05898324c08d67c8ee92dc485b809f0215f46fd7"
      ;;

    docker-ce-cli_19.03.2~3-0~debian-buster_amd64.deb )
      CHECKSUM="1893bdb9096c1084f3eb5613ee632207b26b11034751fa49cde6c61467dacd807614441e4f7c74b826c582a3c5e4eabc094c48e2ce5f68e25f07d3fdd94959ab"
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
  wget -qO - 'https://api.github.com/repos/docker/cli/tags' |
    grep -v "beta" |
    grep -m 1 "name" |
    cut -d '"' -f 4 |
    sed "s/^v//"

  return 0
}

if [ -z "$RELEASE" ] || [ "$RELEASE" = "latest" ]; then
  RELEASE="$(get_latest_release)"
fi

MIRROR="https://download.docker.com/linux"
PACKAGE="docker-ce-cli_$RELEASE"

case "$OS" in
  debian* )
    MIRROR="$MIRROR/debian/dists"
    PACKAGE="$PACKAGE~3-0~debian"

    case "$OS" in
      *-10 )
        MIRROR="$MIRROR/buster"
        PACKAGE="$PACKAGE-buster"
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
        PACKAGE="${PACKAGE}_amd64"
        ;;

      * )
        echo "Unsupported OS architecture '$ARCH'"
        false
        ;;
    esac

    PACKAGE="$PACKAGE.deb"
    ;;

  * )
    echo "Unsupported os '$OS'"
    false
    ;;
esac
