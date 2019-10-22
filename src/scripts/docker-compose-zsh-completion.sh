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
  mkdir -p "$BASEPATH/share/zsh/vendor-completions"
  cp -f "$PACKAGE" "$BASEPATH/share/zsh/vendor-completions/_docker-compose"
}

get_latest_release() {
  get_latest_github_release "docker/compose"
}

is_installed() {
  test -f "$BASEPATH/share/zsh/vendor-completions/_docker-compose"
}

MIRROR="https://raw.githubusercontent.com/docker/compose/$RELEASE/contrib/completion/zsh"
ORIGIN_PKG="_docker-compose"
PACKAGE="docker-compose-zsh-completion-v$RELEASE"

