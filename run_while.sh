#!/bin/bash

for i in $(seq 1 100);
do
    eval $*
    if [ ! -z $TERMINATE_COMMAND ]; then
        eval $TERMINATE_COMMAND
    fi
    echo Issue the same command again in 10 secs...
    sleep 10
done

