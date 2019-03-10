#!/bin/bash

HOST_ID=$(nodetool info | sed -rn 's/ID.*: ([a-zA-Z0-9-]+)/\1/p')

if [[ $(nodetool status | grep $HOST_ID) == *"UN"* ]]; then
  if [[ $DEBUG ]]; then
    echo "UN";
  fi
  exit 0;
else
  if [[ $DEBUG ]]; then
    echo "Not Up";
  fi
  exit 1;
fi