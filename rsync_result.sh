#!/bin/bash

IP=$1
rsync -r -e "ssh -i /home/leo/.ssh/leo19941227.pem" ubuntu@${IP}:/mnt/efs/fs1/s3prl/result/ ../s3prl/result/aws/
