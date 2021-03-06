#!/bin/bash

IP=$1
src_dir=$2
tgt_dir=$3

if [ -z $IP ]; then
    echo ec2 IP is empty.
    exit 1
fi

if [ -z $src_dir ]; then
    echo src_dir is empty.
    exit 1
fi

if [ -z $tgt_dir ]; then
    echo tgt_dir is empty.
    exit 1
fi

rsync -r --delete -e "ssh -i /home/leo/.ssh/leo19941227.pem" $src_dir ubuntu@${IP}:/mnt/efs/fs1/$tgt_dir

