# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

#########
# RULES #
#########
# SUPER_USER=false
# ENV=
# EXEC_MODE=local
# BIN_DEPS=b2sum;docker;wget
#########

download() {
  cd "$CACHE_DIR"

  if [ -n "$PKGS_MIRROR" ]; then
    download_file "$PKGS_MIRROR/$PACKAGE"
    download_file "$PKGS_MIRROR/$PACKAGE-completion-bash"
    download_file "$PKGS_MIRROR/$PACKAGE-completion-zsh"
  else
    download_file "$MIRROR/docker-compose-Linux-$ARCH" "$PACKAGE"
    download_file "$COMP_MIRROR/bash/docker-compose" "$PACKAGE-completion-bash"
    download_file "$COMP_MIRROR/zsh/_docker-compose" "$PACKAGE-completion-zsh"
  fi
}

main() {
  cd "$TMP_DIR"
  mkdir -p "docker-cli"

  if [ "$FORCE" = "false" ] && is_installed; then
    echo "Docker Compose v$RELEASE is already installed."
    return 0
  fi

  cp -f "$PACKAGE" "$BASEPATH/bin/docker-compose"
  chmod +x "$BASEPATH/bin/docker-compose"

  mkdir -p "$BASEPATH/etc/bash_completion.d"
  cp -f "$PACKAGE-completion-bash" \
    "$BASEPATH/etc/bash_completion.d/docker-compose"

  mkdir -p "$BASEPATH/share/zsh/vendor-completions"
  cp -f "$PACKAGE-completion-zsh" \
    "$BASEPATH/share/zsh/vendor-completions/_docker-compose"
}

checksum() {
  FILE="$1"

  case "$FILE" in
    # v1.24.1

    docker-compose-v1.24.1-Linux-x86_64 )
      CHECKSUM="432b26dc59fcf9b9997e36de7aa278b02293f39411159e73ab73b3157f27e59a273c491de57312f411322048fb0f669f41b82d390fc5524d2633d429c459df22"
      ;;

    docker-compose-v1.24.1-Linux-x86_64-completion-bash )
      CHECKSUM="b26b74760599612a8760ca3593761098925ba3923bb8d553b5c469bd31ac8fb7b0f57bea6d67611fc2d6332821faa0a402e95833406911ce357b72d98f3fbace"
      ;;

    docker-compose-v1.24.1-Linux-x86_64-completion-zsh )
      CHECKSUM="a31f999ea10f4c53bdbf431450b082c363ef22c1e7ad4301be49e254e60b044c079f42c693f1fb3bc9eb7d29b15197dcf21e307b9bae6bcac6e2d84de4e5f60c"
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
}

get_latest_release() {
  wget -qO - 'https://api.github.com/repos/docker/compose/releases/latest' |
    grep -m 1 "tag_name" |
    cut -d '"' -f 4 |
    sed "s/^v//"
}

is_installed() {
  which docker-compose

  if docker-compose version | grep -q "^docker-compose version $RELEASE,"; then
    return 0
  fi

  return 1
}

if [ -z "$RELEASE" ] || [ "$RELEASE" = "latest" ]; then
  RELEASE="$(get_latest_release)"
fi

MIRROR="https://github.com/docker/compose/releases/download/$RELEASE"
COMP_MIRROR="https://raw.githubusercontent.com/docker/compose/$RELEASE/contrib/completion"
PACKAGE="docker-compose-v$RELEASE-Linux-$ARCH"

