#!/bin/bash

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <resulting-image-name> <image1> <image2> ... <imageN>"
  exit 1
fi

TARGET=$1
shift

#(
  echo "FROM scratch"
  for image in "$@"; do
      echo "COPY --from=$image / /"
  done
#) | docker build -t "$TARGET" -
