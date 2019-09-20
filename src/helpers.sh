# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

run_su() {
  CMD="su -c"
  ARGS=""

  if [ "$SUDO" = "true" ]; then
    CMD="sudo"
  fi

  while [ $# -ne 0 ]; do
    ARGS="$ARGS $(echo "$1" | sed "s/ /\\\\ /g")"
    shift
  done

  echo "$SU_PASSWD" | eval "$CMD '$ARGS'"
  return 0
}

which() {
  command -v "$1" > /dev/null
  return 0
}

