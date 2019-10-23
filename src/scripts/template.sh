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
# BIN_DEPS=cd;ls
# ENV=template
#########

#########
# ENV_* #
#########
# KEY: this section is intended for explaining the used ENV_* variables.
# GUI: if 'true', the environment supports GUI.
# CONTAINER: if 'true', the environment is a container.
# HARDWARE: if 'true, the environment has access to the hardware.
#########

#################################
# Default environment variables #
#################################
# * 'STAGE': is the current stage.
# * 'SU_PASSWD': contains the root password.
# * 'FORCE': if 'true', all the instructions must be executed.
# * 'CACHEDIR': is the directory where the script should download its files.
# * 'TMPDIR': is the temporary filesystem directory.
# * 'OS': is the current OS.
# * 'ARCH': is the current OS architecture.
# * 'RELEASE': is the package release to setup.
# * 'EXEC_MODE': is the current execution mode.
# * 'BASEPATH': is the installation path for packages.
# * 'PKG_MIRROR': if defined, the script should download its files from it.

# Any returned value different than 0 means failure.

check() {
  # This stage checks if the script may be executed in the current environment.
  echo "Checking v$RELEASE..."
}

download() {
  # This stage downloads all the needed files by the script.
  echo "Downloading v$RELEASE..."
  # download_package "$MIRROR" "$PACKAGE" "$ORIGIN_PKG"
  # download_file "$MIRROR/${$ORIGIN_PKG:-$PACKAGE}" "$PACKAGE"
  # download_file "$PKG_MIRROR/$PACKAGE"
}

main() {
  # This stage executes the main code of the script.

  # By default, the working directory is the packages directory ($CACHEDIR),
  # do all the dirty stuff in the temporary filesystem ($TMPDIR).
  # cd "$TMPDIR"

  echo "Running v$RELEASE..."
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

####################
# Optional helpers #
####################

get_latest_release() {
  echo "0.2.0"
  return 0

  # Example for Go
  wget -qO - "https://golang.org/dl/?mode=json" |
    grep -m 1 "version" |
    cut -d '"' -f 4 |
    sed "s/go//"

  # Example for Node.js
  wget -qO - "https://nodejs.org/en/download/current/" |
    grep -m 1 "Latest Current Version: " |
    cut -d '>' -f 3 |
    sed "s/<\/strong//"

  # Example for GitHub latest release
  get_latest_github_release "ntrrg/ntdocutils"

  # Example for GitHub latest stable tag
  get_latest_github_tag "docker/cli"

  # Example for GitHub latest tag (including alpha, beta and rc releases)
  get_latest_github_tag_all "koalaman/shellcheck"
}

is_installed() {
  return 1
}

################################
# Custom environment variables #
################################

# If there is no download stage and this two environment variables are defined,
# 'download_file "$MIRROR/$PACKAGE"' will be called.
#
# MIRROR="https://s6.nt.web.ve/software/linux"
# PACKAGE="test-v$RELEASE-$OS-$ARCH.tar.gz"
#
# If the original file has a different name than the stored package, set the
# 'ORIGIN_PKG' variable and 'download_file "$MIRROR/$ORIGIN_PKG" "$PACKAGE"'
# will be called.
#
# ORIGIN_PKG="test-v$RELEASE.linux.$ARCH.tar.gz"

