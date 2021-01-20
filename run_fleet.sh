#!/bin/bash

SCRIPT=$1
MACHINE=$2

if [ -z "$SCRIPT" ]; then
    echo SCRIPT argument is empty
    exit 1
fi

if [ -z "$MACHINE" ]; then
    echo MACHINE argument is empty
    exit 1
fi

cp ./spot_fleet_config.json ./tmp.json
USER_DATA=`base64 $SCRIPT -w0`
sed -i "s|base64_encoded_bash_script|$USER_DATA|g" ./tmp.json
sed -i "s|instance_placeholder|$MACHINE|g" ./tmp.json

aws ec2 request-spot-fleet --spot-fleet-request-config file://tmp.json

rm ./tmp.json

