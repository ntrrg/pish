# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

main() {
  while [ $# -gt 0 ]; do
    case $1 in
      --arch )
        ARCH="$2"
        shift
        ;;

      --cache )
        CACHEDIR="$2"
        shift
        ;;

      --checksums )
        CHECKSUMSDIR="$(realpath "$2")"
        shift
        ;;

      --debug )
        DEBUG="true"
        ;;

      --download )
        STAGE="download"
        ;;

      -f | --force )
        FORCE="true"
        ;;

      -h | --help )
        show_help
        return
        ;;

      -m | --mode )
        EXEC_MODE="$2"
        shift
        ;;

      --mirror )
        MIRROR="$2"
        shift
        ;;

      --no-checksum )
        NOCHECKSUM="true"
        ;;

      --os )
        OS="$2"
        shift
        ;;

      -P | --passwd )
        SU_PASSWD="$2"
        shift
        ;;

      --root )
        BASEPATH="$2"
        shift
        ;;

      --scripts )
        SCRIPTSDIR="$2"
        shift
        ;;

      --sudo )
        SUDO="true"
        ;;

      --temp )
        TMPDIR="$2"
        shift
        ;;

      * )
        break
        ;;
    esac

    shift
  done

  mkdir -p "$SCRIPTSDIR"

  if [ $# -eq 0 ]; then
    eval set -- "-"
  fi

  for TARGET in "$@"; do
    echo
    echo "############################################################"
    echo "$TARGET"
    echo "############################################################"
    echo
    run_target "$TARGET"
  done
}

check_rules() {
  local ERRORS="false"
  local FILE="$1"

  # ENV

  local RULES="$(grep "^# ENV=" "$FILE" | sed "s/# ENV=//" | tr ";" " ")"
  local RULE

  for RULE in $RULES; do
    local NAME
    local VALUE

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

  if [ "$ERRORS" = "true" ]; then
    return 1
  fi
}

check_su_passwd() {
  if [ -n "$SU_PASSWD" ]; then
    return 0
  fi

  local FILE="$1"

  if grep -q "^# SUPER_USER=false" "$FILE" &&
      grep -q "^# EXEC_MODE=local" "$FILE" &&
      [ "$EXEC_MODE" = "local" ]; then
    return 0
  fi

  REQUIRE_SU_PASSWD="true"
}

get_os() {
  case "$(uname -s)" in
    Darwin* )
      echo "macos"
      ;;

    * )
      if which lsb_release; then
        echo "$(lsb_release -si | tr "[:upper:]" "[:lower:]")-$(lsb_release -sr)"
      elif which getprop; then
        echo "android-$(getprop ro.build.version.release)"
      else
        echo "all"
      fi
      ;;
  esac
}

run_script() {
  local FILE="$1"
  local RUN_STAGE="${2:-$STAGE}"

  if [ "$RUN_STAGE" != "all" ]; then
    eval "$FILE $RUN_STAGE $(debug not printf "> /dev/null 2> /dev/null")"
    return 0
  fi

  local ERRORS="false"

  BIN_DEPS="$(
    grep "^# BIN_DEPS=" "$FILE" |
    sed "s/# BIN_DEPS=//" |
    tr ";" " "
  )"

  for BIN_DEP in $BIN_DEPS; do
    if ! which_print "$BIN_DEP"; then
      ERRORS="true"
    fi
  done

  if [ "$ERRORS" = "true" ]; then
    return 1
  fi

  eval "$FILE $RUN_STAGE $(debug not printf "> /dev/null 2> /dev/null")"
}

run_target() {
  REQUIRE_SU_PASSWD="false"
  local ERRORS="false"
  local SCRIPTS=""
  local TARGET="$1"

  if [ -z "$TARGET" ] || [ "$TARGET" = "-" ]; then
    TARGET="-"
  elif [ ! -f "$TARGET" ]; then
    echo "Can't find '$TARGET'"
    printf "Downloading from '%s'... " "$TARGETS_MIRROR"
    download_file "$TARGETS_MIRROR/$TARGET"
    echo "[DONE]"
  fi

  local LINE

  # shellcheck disable=SC2002 disable=2013
  for LINE in $(cat "$TARGET" | grep -v "^#" | grep -v "^$"); do
    if echo "$LINE" | grep -q "="; then
      local NAME="$(echo "$LINE" | cut -d "=" -f 1)"
      local VALUE="$(echo "$LINE" | cut -d "=" -f 2)"

      if [ "$NAME" = "BASEPATH" ] && echo "$VALUE" | grep -q "^\~"; then
        VALUE="$HOME/$(echo "$VALUE" | sed "s/^\~\///")"
      fi

      export "$NAME"="$VALUE"
    else
      SCRIPTS="$SCRIPTS $LINE"
      local NAME="$LINE"
      local FILE="$SCRIPTSDIR/$(echo "$LINE" | cut -d '#' -f 1).sh"

      if [ ! -f "$FILE" ]; then
        echo "Can't find '$FILE'"
        printf "Downloading from '%s'... " "$SCRIPTS_MIRROR"

        (
          download_file "$SCRIPTS_MIRROR/$(basename "$FILE").gz" "$FILE.gz"
          gzip -d "$FILE.gz"
        ) || true

        download_and_check_file "$SCRIPTS_MIRROR/$(basename "$FILE")" "$FILE"
        chmod +x "$FILE"
        echo "[DONE]"
      fi

      if [ "$STAGE" = "download" ]; then
        continue
      fi

      echo "Checking '$NAME'..."
      check_su_passwd "$FILE"
      check_rules "$FILE" || ERRORS="true"
    fi
  done

  if [ "$ERRORS" = "true" ]; then
    return 1
  fi

  if [ "$REQUIRE_SU_PASSWD" = "true" ]; then
    trap "stty echo" EXIT
    stty -echo
    printf "%s" "Root password: "
    IFS= read -r SU_PASSWD
    stty echo
    trap - EXIT
    echo
  fi

  echo
  local SCRIPT

  for SCRIPT in $SCRIPTS; do
    debug echo
    printf "Running '%s'... " "$SCRIPT"

    local RE="^.\+-v\([0-9]\+\(\.[0-9]\+\)*\)$"
    RELEASE="$SCRIPT"
    SCRIPT="$(echo "$SCRIPT" | cut -d '#' -f 1)"

    if echo "$RELEASE" | grep -q "#"; then
      RELEASE="$(echo "$RELEASE" | cut -sd '#' -f 2)"
    elif echo "$RELEASE" | grep -q "$RE"; then
      RELEASE="$(echo "$RELEASE" | sed "s/$RE/\1/")"
    else
      RELEASE="$(
        DEBUG="true" run_script "$SCRIPTSDIR/$SCRIPT.sh" get_latest_release
      )"

      printf "(v%s) " "$RELEASE"
    fi

    debug echo
    run_script "$SCRIPTSDIR/$SCRIPT.sh"
    debug not echo "[DONE]"
  done
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
      --cache=PATH      Set the cache directory to find/download the needed
                        files by the scripts. The user must have write
                        permissions. ($CACHEDIR)
      --checksums=PATH  Use PATH as checksums directory. ($CHECKSUMSDIR)
      --debug           Print debugging messages.
  -D, --download        Just run the download stage of every script.
  -f, --force           Run the scripts even if they can be skipped.
  -h, --help            Show this help message.
  -m, --mode=MODE       Set the execution mode to MODE. Valid values are
                        'local' or 'system'. ($EXEC_MODE)
      --mirror=URL      Use URL as base mirror for targets and scripts.
                        ($MIRROR)
      --no-checksum     Disable files checksum comprobation.
      --os=OS           Set environment OS to OS. Valid values are 'debian-10',
                        'android-9', etc... ($OS)
  -P, --passwd=PASSWD   Use PASSWD as super-user password.
      --root=PATH       Set installation path to PATH. Usual values are
                        '/', '/usr' and '~/.local'. ($BASEPATH)
      --scripts=PATH    Use PATH as scripts directory. ($SCRIPTSDIR)
      --sudo            Use 'sudo' for running super-user commands.
      --temp=PATH       Use PATH as temporal filesystem. The user must have
                        write permissions. ($TMPDIR)

Script list file syntax:
  A line-separated list of scripts to run. Each line must have one of the
  following syntax:

    KEY=VALUE       # Environment variable
    NAME[#RELEASE]  # Script

  See $TARGETS_MIRROR/template.slist

Scripts syntax:
  * The script must be POSIX compliant, but can use the 'local' keyword.
  * The script should have at least the 'main' stage.
  * The script may have custom functions and variables.
  * The script must pass shellcheck.

  See $MIRROR/src/scripts/template.sh

Environment variables:
  * 'ARCH': behaves as the '--arch' flag.
  * 'BASEPATH': behaves as the '--root' flag.
  * 'CACHEDIR': behaves as the '--cache' flag.
  * 'CHECKSUMSDIR': behaves as the '--checksums' flag.
  * 'DEBUG': behaves as the '--debug' flag.
  * 'EXEC_MODE': behaves as the '-m, --mode' flag.
  * 'FORCE': behaves as the '-f, --force' flag.
  * 'MIRROR': behaves as the '--mirror' flag.
  * 'NOCHECKSUM': behaves as the '--no-checksum' flag.
  * 'OS': behaves as the '--os' flag.
  * 'SCRIPTSDIR': behaves as the '--scripts' flag.
  * 'SU_PASSWD': behaves as the '-P, --passwd' flags.
  * 'SUDO': behaves as the '--sudo' flags.
  * 'TMPDIR': behaves as the '--temp' flag.

Copyright (c) 2019 Miguel Angel Rivera Notararigo
Released under the MIT License
EOF
}

export TMPDIR="${TMPDIR:-/tmp}"
export CACHEDIR="${CACHEDIR:-$TMPDIR}"
export SUDO="${SUDO:-false}"
export SU_PASSWD="$SU_PASSWD"
export FORCE="${FORCE:-false}"
export NOCHECKSUM="${NOCHECKSUM:-false}"
export DEBUG="${DEBUG:-false}"

REQUIRE_SU_PASSWD="false"
STAGE="all"
SCRIPTSDIR="${SCRIPTSDIR:-$TMPDIR}"
MIRROR="${MIRROR:-https://post-install.nt.web.ve}"
TARGETS_MIRROR="$MIRROR/targets"
SCRIPTS_MIRROR="$MIRROR/scripts"

export CHECKSUMSDIR
CHECKSUMSDIR="$(realpath "${CHECKSUMSDIR:-$TMPDIR}")"
export CHECKSUMS_MIRROR="$MIRROR/checksums"

export OS="${OS:-$(get_os)}"
export ARCH="${ARCH:-$(uname -m)}"
export EXEC_MODE="${EXEC_MODE:-local}"
export BASEPATH="${BASEPATH:-$HOME/.local}"
export RELEASE

