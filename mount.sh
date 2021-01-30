#!/bin/bash

DIRNAME=$1
if [ -z $DIRNAME ]; then
    echo DIRNAME is empty
    exit 1
fi

mkdir -p $DIRNAME
sshfs leo-sftp@s-34eae7ba3f5c48d5a.server.transfer.us-west-2.amazonaws.com:/fs-33f71937/$DIRNAME $DIRNAME
