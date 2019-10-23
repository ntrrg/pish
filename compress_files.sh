# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

while [ $# -gt 0 ]; do
  FILE="$1"
  shift
  gzip -c "$FILE" > "$FILE.gz"
done

