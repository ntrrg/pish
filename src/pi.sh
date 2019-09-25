# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

main() {
  while [ $# -gt 0 ]; do
    case $1 in
      --arch )
        ARCH="$2"
        shift
        ;;

      --atomic )
        MODES="all"
        ;;

      --cache )
        CACHE_DIR="$2"
        shift
        ;;

      --debug )
        DEBUG="true"
        ;;

      --download )
        MODES="download"
        ;;

      -f | --force )
        FORCE="true"
        ;;

      -h | --help )
        show_help
        return
        ;;

      --mirror )
        MIRROR="$2"
        shift
        ;;

      --smirror )
        SCRIPTS_MIRROR="$2"
        shift
        ;;

      --tmirror )
        TARGETS_MIRROR="$2"
        shift
        ;;

      --os )
        OS="$2"
        shift
        ;;

      -P | --passwd )
        SU_PASSWD="$2"
        shift
        ;;

      --scripts )
        SCRIPTS_DIR="$2"
        shift
        ;;

      --sudo )
        SUDO="true"
        ;;

      --temp )
        TMP_DIR="$2"
        shift
        ;;

      * )
        break
        ;;
    esac

    shift
  done

  mkdir -p "$SCRIPTS_DIR"

  TARGET="$1"

  if [ -z "$TARGET" ] || [ "$TARGET" = "-" ]; then
    TARGET="-"
  elif [ ! -f "$TARGET" ]; then
    echo "Can't find '$TARGET'"
    printf "Downloading from '%s'... " "$TARGETS_MIRROR"
    download_file "$TARGETS_MIRROR/$TARGET"
    echo "[DONE]"
  fi

  ERRORS="false"

  # shellcheck disable=SC2002 disable=2013
  for LINE in $(cat "$TARGET" | grep -v "^#" | grep -v "^$"); do
    if echo "$LINE" | grep -q "="; then
      NAME="$(echo "$LINE" | cut -d "=" -f 1)"
      VALUE="$(echo "$LINE" | cut -d "=" -f 2)"

      if [ "$NAME" = "BASEPATH" ] && echo "$VALUE" | grep -q "^\~"; then
        VALUE="$HOME/$(echo "$VALUE" | sed "s/^\~\///")"
      fi

      export "$NAME"="$VALUE"
    else
      SCRIPTS="$SCRIPTS $LINE"
      NAME="$LINE"
      FILE="$SCRIPTS_DIR/$(echo "$LINE" | cut -d '#' -f 1).sh"

      if [ ! -f "$FILE" ]; then
        echo "Can't find '$FILE'"
        printf "Downloading from '%s'... " "$SCRIPTS_MIRROR"
        download_file "$SCRIPTS_MIRROR/$(basename "$FILE")" "$FILE"
        chmod +x "$FILE"
        echo "[DONE]"
      fi

      if [ "$MODES" = "download" ]; then
        continue
      fi

      echo "Checking '$NAME'..."
      check_su_passwd "$FILE"
      check_rules "$FILE" || ERRORS="true"
      run_script "$FILE" check
    fi
  done

  if [ "$ERRORS" = "true" ]; then
    return 1
  fi

  for MODE in $MODES; do
    echo
    echo "############################################################"
    echo
    echo "Running '$MODE' stage..."

    for SCRIPT in $SCRIPTS; do
      echo
      printf "* %s " "$SCRIPT"
      debug echo
      RE="^.\+-v\([[:digit:]]\+\(\.[[:digit:]]\+\)*\)$"

      if echo "$SCRIPT" | grep -q "#"; then
        RELEASE="$(echo "$SCRIPT" | cut -sd '#' -f 2)"
      elif echo "$SCRIPT" | grep -q "$RE"; then
        RELEASE="$(echo "$SCRIPT" | sed "s/$RE/\1/")"
      else
        RELEASE="latest"
      fi

      SCRIPT="$(echo "$SCRIPT" | cut -d '#' -f 1)"
      run_script "$SCRIPTS_DIR/$SCRIPT.sh" "$MODE"
      debug not echo "[DONE]"
    done
  done

  return 0
}

check_rules() {
  FILE="$1"
  ERRORS="false"

  # ENV

  RULES="$(grep "^# ENV=" "$FILE" | sed "s/# ENV=//" | tr ";" " ")"

  for RULE in $RULES; do
    NAME=""
    VALUE=""

    if echo "$RULE" | grep -q "^\!"; then
      VALUE="false"
    else
      VALUE="true"
    fi

    NAME="ENV_$(echo "$RULE" | tr -d "\!" | tr "[:lower:]" "[:upper:]")"

    if ! env | grep -q "^$NAME=$VALUE$"; then
      ERRORS="true"
      echo "ENV: broken rule '$RULE'"
      echo "  Want: '$NAME=$VALUE'; Got: '$(env | grep "^$NAME")'"
    fi
  done

  # EXEC_MODE

  if [ "$EXEC_MODE" = "local" ] && grep -q "^# EXEC_MODE=system" "$FILE"; then
    ERRORS="true"
    echo "EXEC_MODE: can't be executed in local mode"
  fi

  # BIN_DEPS

  BIN_DEPS="$(
    grep "^# BIN_DEPS=" "$FILE" |
    sed "s/# BIN_DEPS=//" |
    tr ";" " "
  )"

  for BIN_DEP in $BIN_DEPS; do
    if ! command -v "$BIN_DEP" > /dev/null; then
      ERRORS="true"
      echo "BIN_DEP: '$BIN_DEP' not found"
    fi
  done

  if [ "$ERRORS" = "true" ]; then
    return 1
  fi

  return 0
}

check_su_passwd() {
  if [ -n "$SU_PASSWD" ]; then
    return 0
  fi

  FILE="$1"

  if grep -q "^# SUPER_USER=false" "$FILE" &&
      grep -q "^# EXEC_MODE=local" "$FILE" &&
      [ "$EXEC_MODE" = "local" ]; then
    return 0
  fi

  trap "stty echo" EXIT
  stty -echo
  printf "%s" "Root password: "
  IFS= read -r SU_PASSWD
  stty echo
  trap - EXIT
  echo
  return 0
}

run_script() {
  FILE="$1"
  STAGE="${2:-all}"

  eval "$FILE $STAGE $(debug not printf "> /dev/null 2> /dev/null")"
  return 0
}

show_help() {
  cat <<EOF
$0 - Post installation script. It setup the environment as the given target.

Usage: $0 [OPTIONS] [TARGET]

TARGET is a file containing the list of scripts to run. If TARGET doesn't exist
it will be downloaded from the targets mirror. If no target is given, the
script list will be read from the standard input.

Options:
      --arch=ARCH       Set environment OS architecture to ARCH. Valid values
                        are 'x86_64', 'i686', etc... ($ARCH)
      --atomic          Run all stages in a single call. By default, scripts
                        are executed by stages, this means they are executed
                        three times (one per stage, excluding 'clean'), the
                        first time, the 'check' stage of every script is
                        executed, then the 'download' stage of every script and
                        finally the 'main' stage of every script.
      --cache=PATH      Set the cache directory to find/download the needed
                        files by the scripts. The user must have write
                        permissions. ($CACHE_DIR)
      --debug           Print debugging messages.
  -D, --download        Just run the download stage of every script.
  -f, --force           Run the scripts even if they can be skipped.
  -h, --help            Show this help message.
      --mirror=URL      Use URL as base mirror for targets and scripts.
                        ($MIRROR)
      --smirror=URL     Use URL as scripts mirror when some script can't be
                        found locally. ($SCRIPTS_MIRROR)
      --tmirror=URL     Use URL as targets mirror when some target can't be
                        found locally. ($TARGETS_MIRROR)
      --os=OS           Set environment OS to OS. Valid values are 'debian-10',
                        'android-9', etc... ($OS)
  -P, --passwd=PASSWD   Use PASSWD as super-user password.
      --scripts=PATH    Use PATH as scripts directory. ($SCRIPTS_DIR)
      --sudo            Use 'sudo' for running super-user commands.
      --temp=PATH       Use PATH as temporal filesystem. The user must have
                        write permissions. ($TMP_DIR)

Script list file syntax:
  A line-separated list of scripts to run. Each line must have one of the
  following syntax:

    KEY=VALUE       # Environment variable
    NAME[#RELEASE]  # Script

  See $TARGETS_MIRROR/template.slist

Scripts syntax:
  * The script must be POSIX compliant.
  * The script should have at least the 'check', 'main' and 'clean' stages.
  * The script may have custom functions and variables.
  * The script must pass shellcheck.

  See $MIRROR/src/scripts/template.sh

Environment variables:
  * 'ARCH': behaves as the '--arch' flag.
  * 'CACHE_DIR': behaves as the '--cache' flag.
  * 'DEBUG': behaves as the '--debug' flag.
  * 'FORCE': behaves as the '-f, --force' flag.
  * 'MIRROR': behaves as the '--mirror' flag.
  * 'OS': behaves as the '--os' flag.
  * 'SCRIPTS_DIR': behaves as the '--scripts' flag.
  * 'SCRIPTS_MIRROR': behaves as the '--smirror' flag.
  * 'SU_PASSWD': behaves as the '-P, --passwd' flags.
  * 'SUDO': behaves as the '--sudo' flags.
  * 'TARGETS_MIRROR': behaves as the '--tmirror' flag.
  * 'TMP_DIR': behaves as the '--temp' flag.

Copyright (c) 2019 Miguel Angel Rivera Notararigo
Released under the MIT License
EOF

  return 0
}

export TMP_DIR="${TMP_DIR:-/tmp}"
export CACHE_DIR="${CACHE_DIR:-$TMP_DIR}"
export SUDO="${SUDO:-false}"
export SU_PASSWD="$SU_PASSWD"
export FORCE="${FORCE:-false}"

MODES="${MODES:-download main}"
MIRROR="${MIRROR:-https://post-install.nt.web.ve}"
SCRIPTS=""
SCRIPTS_DIR="${SCRIPTS_DIR:-$TMP_DIR}"
SCRIPTS_MIRROR="${SCRIPTS_MIRROR:-$MIRROR/scripts}"
TARGETS_MIRROR="${TARGETS_MIRROR:-$MIRROR/targets}"

export OS="${OS:-$(get_os)}"
export ARCH="${ARCH:-$(uname -m)}"
export EXEC_MODE="${EXEC_MODE:-local}"
export BASEPATH="${BASEPATH:-~/.local}"
export RELEASE
export DEBUG="${DEBUG:-false}"

