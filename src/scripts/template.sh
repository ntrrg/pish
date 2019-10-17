# Copyright (c) YYYY John Doe
# Released under the MIT License

# Every script must have rules, this rules are constraints for running the
# script. They have the syntax 'KEY=VALUE'. The special rules are:
#
#   * 'SUPER_USER': determines whether the script requires super-user
#     privileges to run. Valid values are 'true' or 'false'.
#   * 'EXEC_MODE': determines whether the script may be executed in local or
#     system mode. Valid values are 'local' or 'system'.
#   * 'BIN_DEPS': is a semi-colon separated list of binaries dependencies.
#   * 'ENV': is a semi-colon separated list of environment requirements by the
#     script to be executed. An exclamation mark ('!') prefix may be used for
#     negation. For example, if 'gui' is in the list, there must be an
#     'ENV_GUI=true' environment variable, which in this case means the script
#     requires GUI support; or if '!container' is in the list, there must be an
#     'ENV_CONTAINER=false' environment variable, which in this case means the
#     script can't be executed inside a container.

#########
# RULES #
#########
# SUPER_USER=false
# EXEC_MODE=local
# BIN_DEPS=b2sum;wget
# ENV=template
#########

#########
# ENV_* #
#########
# KEY: this section is intended for explaning the used ENV_* variables.
# GUI: if 'true', the environment supports GUI.
# CONTAINER: if 'true', the environment is a container.
# HARDWARE: if 'true, the environment has access to the hardware.
#########

# Environment variables:
#   * 'STAGE': is the current stage.
#   * 'SU_PASSWD': contains the root password.
#   * 'FORCE': if 'true', all the instructions must be executed.
#   * 'CACHE_DIR': is the directory where the script should download its files.
#   * 'TMP_DIR': is the temporal filesystem directory.
#   * 'OS': is the current OS.
#   * 'ARCH': is the current OS architecture.
#   * 'RELEASE': is the package release to setup.
#   * 'EXEC_MODE': is the current execution mode.
#   * 'BASEPATH': is the installation path for packages.
#   * 'PKGS_MIRROR': if defined, the script should download its files from it.

# Any returned value different than 0 means failure.

check() {
  # This stage checks if the script may be executed in the current environment.
  echo "Checking v$RELEASE..."
}

download() {
  # This stage downloads all the needed files by the script. Any should be done
  # in CACHE_DIR.
  cd "$CACHE_DIR"
  echo "Downloading v$RELEASE..."
  echo "  From: ${PKGS_MIRROR:-$MIRROR}/$PACKAGE"
  # download_file "${PKGS_MIRROR:-$MIRROR}/$PACKAGE"
}

main() {
  # This stage executes the main code of the script.
  cd "$TMP_DIR"
  echo "Running v$RELEASE..."

  if [ "$FORCE" = "false" ] && is_installed; then
    echo "Template v$RELEASE is already installed."
    return 0
  fi
}

clean() {
  case "$STAGE" in
    check )
      echo "Cleaning after check..."
      ;;

    download | main )
      echo "Cleaning after download/main..."
      ;;

    * )
      echo "Cleaning after '$STAGE'..."
      ;;
  esac
}

# Optional helpers

checksum() {
  FILE="$1"

  case "$FILE" in
    my-package.tar.gz )
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
}

get_latest_release() {
  echo "0.2.0"
  return 0

  # Example for Go
  wget -qO - 'https://golang.org/dl/?mode=json' |
    grep -m 1 "version" |
    cut -d '"' -f 4 |
    sed "s/go//"

  # Example for Node.js
  wget -qO - 'https://nodejs.org/en/download/current/' |
    grep -m 1 "Latest Current Version: " |
    cut -d '>' -f 3 |
    sed "s/<\/strong//"

  # Example for GitHub latest release
  wget -qO - 'https://api.github.com/repos/ntrrg/ntdocutils/releases/latest' |
    grep -m 1 "tag_name" |
    cut -d '"' -f 4 |
    sed "s/^v//"

  # Example for GitHub latest tag
  wget -qO - 'https://api.github.com/repos/koalaman/shellcheck/tags' |
    grep -m 1 "name" |
    cut -d '"' -f 4 |
    sed "s/^v//"
}

is_installed() {
  return 1
}

if [ -z "$RELEASE" ] || [ "$RELEASE" = "latest" ]; then
  RELEASE="$(get_latest_release)"
fi

MIRROR="https://s6.nt.web.ve/software/linux"
PACKAGE="test-v$RELEASE.linux.$ARCH.tar.xz"

