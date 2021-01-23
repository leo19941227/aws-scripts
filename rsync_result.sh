#!/bin/bash

IP=$1

if [ -z $IP ]; then
    echo ec2 IP is empty.
    exit 1
fi

rsync -r -e "ssh -i /home/leo/.ssh/leo19941227.pem" ubuntu@${IP}:/mnt/efs/fs1/s3prl/result/ ../s3prl/result/aws/
