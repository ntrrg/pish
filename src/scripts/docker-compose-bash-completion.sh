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

get_latest_release() {
  get_latest_github_release "docker/compose"
}

is_installed() {
  test -f "$BASEPATH/etc/bash_completion.d/docker-compose"
}

MIRROR="https://raw.githubusercontent.com/docker/compose/$RELEASE/contrib/completion/bash"
ORIGIN_PKG="docker-compose"
PACKAGE="docker-compose-bash-completion-v$RELEASE"

