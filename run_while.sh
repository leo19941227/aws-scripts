#!/bin/bash

LOGDIR=$1
shift
COMMANDS=$*

if [ ! -d "$LOGDIR" ]; then
    echo LOGDIR argument is not a directory
    exit 1
fi

if [ -z "$COMMANDS" ]; then
    echo COMMANDS argument is empty
    exit 1
fi

for i in $(seq 1 100); do
    if [ -f $LOGDIR"/"${COMMANDS// /_}".done" ]; then
        break
    fi
    eval $COMMANDS
done

