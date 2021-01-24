#!/bin/bash

SSH_PROFILE=/home/leo/.ssh/leo19941227.pem

OS=$1
shift
MACHINE=$1
shift
WORKDIR=$1
shift
COMMAND=$*

LOGDIR="./logs/"${COMMAND// /_}
mkdir -p $LOGDIR
rm -rf $LOGDIR"/*"

if [ $(df "logs" | grep "aws" | wc -l) == "0" ]; then
    echo logs/ is not mounted from AWS EFS.
    exit 1
fi

if [ -z "$OS" ]; then
    echo OS argument is empty
    exit 1
fi

efs_mount_point_1=/mnt/efs/fs1/
if [ "$OS" == "amazon_linux2" ]; then
    IMAGE="ami-09aed85ddf3e7c184"
    CONDA_ROOT=$efs_mount_point_1"/miniconda3_amazon_linux2/"
    NONROOT_USER="ec2-user"

elif [ "$OS" == "ubuntu18" ]; then
    IMAGE="ami-0b1a80ce62c464a55"
    CONDA_ROOT=$efs_mount_point_1"/miniconda3_ubuntu18/"
    NONROOT_USER="ubuntu"
fi

if [ -z "$IMAGE" ]; then
    echo Unsupported OS argument
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

sed -i "s|COMMAND_PLACEHOLDER|$COMMAND|g" ./tmp.sh
sed -i "s|SCRIPT_PLACEHOLDER|$(base64 ./tmp.sh -w0)|g" ./tmp.json
sed -i "s|MACHINE_PLACEHOLDER|$MACHINE|g" ./tmp.json
sed -i "s|IMAGE_PLACEHOLDER|$IMAGE|g" ./tmp.json

FLEETID=$(aws ec2 request-spot-fleet --spot-fleet-request-config file://tmp.json --query \"SpotFleetRequestId\")

rm ./tmp.json
rm ./tmp.sh

if [ -z $FLEETID ]; then
    echo no returned fleetid. exit.
    exit 1
fi

TERMINATE_COMMAND="aws ec2 cancel-spot-fleet-requests --region us-west-2 --spot-fleet-request-ids $FLEETID --terminate-instances"

touch $LOGDIR"/command" $LOGDIR"/terminate"
echo $COMMAND > $LOGDIR"/command"
echo $TERMINATE_COMMAND > $LOGDIR"/terminate"

# wait for 10 mins
for i in $(seq 1 60);
do
    if [ -f $LOGDIR"/ssh" ]; then
        echo ssh profile found. connected.
        CONNECTED=ok
        break
    fi
    echo ssh profile not found. retry after 10 secs.
    sleep 10
done

if [ -z "$CONNECTED" ]; then
    echo cancel the spot fleet request.
else
    echo execute the command.
    ssh -o "StrictHostKeyChecking no" -t -i $SSH_PROFILE $(cat $LOGDIR"/ssh") " \
        source ${CONDA_ROOT}/bin/activate benchmark; \
        cd ${efs_mount_point_1}/${WORKDIR}; \
        ${COMMAND}; \
        ${TERMINATE_COMMAND}; \
    "
fi

eval $TERMINATE_COMMAND
rm $LOGDIR"/ssh"

