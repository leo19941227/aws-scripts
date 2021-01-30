#!/bin/bash

tmp_sh=$(mktemp)
tmp_json=$(mktemp)
cp ./user_data_script.sh $tmp_sh
cp ./spot_fleet_config.json $tmp_json

sed -i "s|COMMAND_PLACEHOLDER|$COMMAND|g" $tmp_sh
sed -i "s|SCRIPT_PLACEHOLDER|$(base64 ${tmp_sh} -w0)|g" $tmp_json
sed -i "s|MACHINE_PLACEHOLDER|$MACHINE|g" $tmp_json
sed -i "s|IMAGE_PLACEHOLDER|$IMAGE|g" $tmp_json

FLEETID=$(aws ec2 request-spot-fleet --spot-fleet-request-config file://${tmp_json} --query \"SpotFleetRequestId\")

rm $tmp_sh
rm $tmp_json

if [ -z $FLEETID ]; then
    echo no returned fleetid. exit.
    return 1
fi

TERMINATE_COMMAND="aws ec2 cancel-spot-fleet-requests --region us-west-2 --spot-fleet-request-ids $FLEETID --terminate-instances"
