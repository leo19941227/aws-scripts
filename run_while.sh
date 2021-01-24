#!/bin/bash

for i in $(seq 1 100);
do
    eval $*
    echo Issue the same command again in 10 secs...
    sleep 10
done

