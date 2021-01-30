#!/bin/bash

KEYNAME=leo19941227
SECURITY_ID=sg-03beee836a87a3015
SUBNET_ID=subnet-cb0ba5b3

tmp_sh=$(mktemp)
cp ./user_data_script.sh $tmp_sh
sed -i "s|COMMAND_PLACEHOLDER|$COMMAND|g" $tmp_sh

INSTANCEID=$(aws ec2 run-instances \
    --image-id $IMAGE \
    --count 1 \
    --instance-type $MACHINE \
    --key-name $KEYNAME \
    --security-group-ids $SECURITY_ID \
    --subnet-id $SUBNET_ID \
    --user-data file://${tmp_sh} \
    --query Instances[0].InstanceId)

rm $tmp_sh

if [ -z $INSTANCEID ]; then
    echo No instance is created.
    return 1
fi

TERMINATE_COMMAND="aws ec2 terminate-instances --instance-ids $INSTANCEID"
