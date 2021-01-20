#!/bin/bash

aws ec2 run-instances \
    --query "Instances[0].InstanceId" \
    --image-id ami-0027dfad6168539c7 \
    --security-group-ids sg-03beee836a87a3015 \
    --count 1 \
    --instance-type p2.xlarge \
    --key-name leo19941227 \
    --subnet-id subnet-cb0ba5b3 \
    --placement "AvailabilityZone='us-west-2a, us-west-2b, us-west-2c, us-west-2d'" \
    # --user-data "" \ 
    # --iam-instance-profile "" \ 
    # --instance-initiated-shutdown-behavior "terminate" \
