# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

while [ $# -gt 0 ]; do
  FILE="$1"
  shift
  sha256sum < "$FILE" > "src/checksums/$(basename $FILE).sha256"
done

