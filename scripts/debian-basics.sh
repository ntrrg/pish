#!/bin/sh
# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

set -e
trap _clean EXIT

export STAGE="$1"

check() {
  true
}

download() {
  true
}

main() {
  true
}

clean() {
  true
}

_clean() {
  ERR_CODE="$?"
  set +e
  trap - EXIT
  clean || true
  return "$ERR_CODE"
}

# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

debug() {
  VALUE="true"

  if [ "$1" = "not" ]; then
    VALUE="false"
    shift
  fi

  if [ "$DEBUG" = "$VALUE" ]; then
    "$@"
  fi
}

download_file() {
  URL="$1"
  FILE="${2:-$(basename "$URL")}"

  wget -"$(debug not printf "q")"O "$FILE" "$URL" || (
    ERR="$?"
    echo "[FAIL]"
    ([ "$FILE" != "-" ] && rm -f "$FILE") || true
    return "$ERR"
  )
}

download_file_quiet() {
  DEBUG="false" download_file "$@"
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

run_su() {
  CMD="su -c '%s' -"
  ARGS=""

  if [ "$SUDO" = "true" ]; then
    CMD="sudo '%s'"
  fi

  while [ $# -ne 0 ]; do
    ARGS="$ARGS $(echo "$1" | sed "s/ /\\\\ /g")"
    shift
  done

  # shellcheck disable=2059
  echo "$SU_PASSWD" | eval "$(printf "$CMD" "cd $PWD && $ARGS")"
}

which() {
  command -v "$1" > /dev/null
}

which_print() {
  if ! which "$1"; then
    echo "'$1' not found"
    return 1
  fi
}

# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

#########
# RULES #
#########
# SUPER_USER=true
# ENV=
# EXEC_MODE=system
# BIN_DEPS=
#########

#########
# ENV_* #
#########
# GUI: if 'true', the environment has GUI support.
# HARDWARE: if 'true', the environment has hardware access.
#########

main() {
  cd "$TMP_DIR"

  case "$OS" in
    debian* )
      case "$OS" in
        *-10 )
          run_su apt-get install -y \
            apt-transport-https \
            bc \
            elinks \
            git \
            htop \
            iftop \
            isc-dhcp-client \
            jq \
            lbzip2 \
            locales \
            make \
            mosh \
            netselect \
            p7zip-full \
            pv \
            rsync \
            screen \
            ssh \
            sshfs \
            transmission-cli \
            unzip \
            wget \
            zsh

          if [ "$ENV_GUI" = "true" ]; then
            run_su apt-get install -y \
              chromium \
              conky \
              evince \
              gimp \
              inkscape \
              transmission \
              vlc \
              xfce4 \
              xfce4-goodies
          fi

          if [ "$ENV_HARDWARE" = "true" ]; then
            run_su apt-get install -y \
              btrfs-progs \
              cryptsetup \
              dosfstools \
              lvm2 \
              ntfs-3g \
              pciutils \
              usbutils \
              vbetool

            if [ "$ENV_GUI" = "true" ]; then
              run_su apt-get install -y \
                alsa-utils \
                cups \
                simple-scan \
                system-config-printer \
                xcalib
            fi

            if lspci | grep -q "Network controller"; then
              run_su apt-get install -y rfkill wireless-tools wpasupplicant

              if [ "$ENV_GUI" = "true" ]; then
                run_su apt-get install -y network-manager-gnome
              fi
            fi

            if lsmod | grep -q "bluetooth"; then
              run_su apt-get install -y rfkill

              if [ "$ENV_GUI" = "true" ]; then
                run_su apt-get install -y blueman
              fi
            fi
          fi

          run_su localedef \
            -ci "$(echo "$LOCALE_NAME" | cut -d "." -f 1)" \
            -f "$(echo "$LOCALE_NAME" | cut -d "." -f 2)" \
            -A /usr/share/locale/locale.alias \
            "$LOCALE_NAME"
          ;;

        * )
          echo "Unsupported Debian version '$OS'"
          false
          ;;
      esac
      ;;

    * )
      echo "Unsupported OS '$OS'"
      false
      ;;
  esac
}

LOCALE_NAME="${LOCALE_NAME:-en_US.UTF-8}"

# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

if [ $# -eq 0 ] || [ "$1" = "all" ]; then
  check
  download
  main
else
  $1
fi

