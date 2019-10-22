# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

#########
# RULES #
#########
# SUPER_USER=false
# ENV=
# EXEC_MODE=local
# BIN_DEPS=docker-compose
#########

main() {
  mkdir -p "$BASEPATH/etc/bash_completion.d"
  cp -f "$PACKAGE" "$BASEPATH/etc/bash_completion.d/docker-compose"
}

checksum() {
  case "$1" in
    docker-compose-bash-completion-v1.24.1 )
      echo "b26b74760599612a8760ca3593761098925ba3923bb8d553b5c469bd31ac8fb7b0f57bea6d67611fc2d6332821faa0a402e95833406911ce357b72d98f3fbace"
      ;;
  esac
}

get_latest_release() {
  get_latest_github_release "docker/compose"
}

is_installed() {
  test -f "$BASEPATH/etc/bash_completion.d/docker-compose"
}

MIRROR="https://raw.githubusercontent.com/docker/compose/$RELEASE/contrib/completion/bash"
ORIGIN_PKG="docker-compose"
PACKAGE="docker-compose-bash-completion-v$RELEASE"

