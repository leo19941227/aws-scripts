#!/bin/bash

SSH_PROFILE=/home/leo/.ssh/leo19941227.pem

SPOT=$1
shift
OS=$1
shift
MACHINE=$1
shift
WORKDIR=$1
shift
COMMAND=$*

LOGDIR="./logs/"$(echo "$COMMAND" | sha256sum | cut -d" " -f1)
mkdir -p $LOGDIR
rm -rf $LOGDIR"/*"

if [ $(df "logs" | grep "aws" | wc -l) == "0" ]; then
    echo logs/ is not mounted from AWS EFS.
    return 1
fi

if [ -z "$SPOT" ]; then
    echo SPOT argument is empty
    return 1
fi

if [ -z "$OS" ]; then
    echo OS argument is empty
    return 1
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
    return 1
fi

if [ -z "$MACHINE" ]; then
    echo MACHINE argument is empty
    return 1
fi

if [ -z "$WORKDIR" ]; then
    echo WORKDIR argument is empty
    return 1
fi

if [ -z "$COMMAND" ]; then
    echo COMMAND argument is empty
    return 1
fi

if [ $SPOT == "1" ]; then
    source ./run_spot.sh
else
    source ./run_demand.sh
fi

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
    echo cancel the request.
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
