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

get_checksum() {
  case "$1" in
    docker-compose-zsh-completion-v1.24.1 )
      echo "a31f999ea10f4c53bdbf431450b082c363ef22c1e7ad4301be49e254e60b044c079f42c693f1fb3bc9eb7d29b15197dcf21e307b9bae6bcac6e2d84de4e5f60c"
      ;;
  esac
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

