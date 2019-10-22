# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

if [ $# -eq 0 ] || [ "$1" = "all" ]; then
  check
  _download
  _main
else
  $1
fi

