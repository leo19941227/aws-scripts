#!/bin/bash

MACHINE=$1
shift
WORKDIR=$1
shift
COMMAND=$*

if [ ! -L "logs" ]; then
    echo Please set up logging dir: logs/
    exit 1
fi

if [ -z "$MACHINE" ]; then
    echo MACHINE argument is empty
    exit 1
fi

if [ -z "$WORKDIR" ]; then
    echo WORKDIR argument is empty
    exit 1
fi

if [ -z "$COMMAND" ]; then
    echo COMMAND argument is empty
    exit 1
fi

cp ./user_data_script.sh ./tmp.sh
cp ./spot_fleet_config.json ./tmp.json

sed -i "s|WORKDIR_PLACEHOLDER|$WORKDIR|g" ./tmp.sh
sed -i "s|COMMAND_PLACEHOLDER|$COMMAND|g" ./tmp.sh
sed -i "s|SCRIPT_PLACEHOLDER|$(base64 ./tmp.sh -w0)|g" ./tmp.json
sed -i "s|MACHINE_PLACEHOLDER|$MACHINE|g" ./tmp.json

FLEETID=$(aws ec2 request-spot-fleet --spot-fleet-request-config file://tmp.json --query \"SpotFleetRequestId\")

rm ./tmp.json
rm ./tmp.sh

TERMINATE_COMMAND="aws ec2 cancel-spot-fleet-requests --region us-west-2 --spot-fleet-request-ids $FLEETID --terminate-instances"

LOGDIR="./logs/"${COMMAND// /_}
mkdir -p $LOGDIR
echo $COMMAND > $LOGDIR"/command"
echo $TERMINATE_COMMAND > $LOGDIR"/terminate"
watch -n 0.5 -c cat $LOGDIR"/log"

