#!/bin/bash

MACHINE=$1
shift
COMMANDS=$*

if [ -z "$MACHINE" ]; then
    echo MACHINE argument is empty
    exit 1
fi

if [ -z "$COMMANDS" ]; then
    echo COMMANDS argument is empty
    exit 1
fi

cp ./spot_fleet_config.json ./tmp.json
cp ./user_data_script.sh ./tmp.sh

sed -i "s|COMMAND_PLACEHOLDER|$COMMANDS|g" ./tmp.sh
sed -i "s|base64_encoded_bash_script|$(base64 ./tmp.sh -w0)|g" ./tmp.json
sed -i "s|instance_placeholder|$MACHINE|g" ./tmp.json

aws ec2 request-spot-fleet --spot-fleet-request-config file://tmp.json

rm ./tmp.json
rm ./tmp.sh
