#!/bin/bash

EFS_ID="fs-33f71937"

# update packages
sudo yum -y update
sudo apt-get -y update

sudo yum -y upgrade
sudo apt-get -y upgrade

# install packages for efs
yum install -y amazon-efs-utils
apt-get -y install amazon-efs-utils

yum install -y nfs-utils
apt-get -y install nfs-common

# mount efs
file_system_id_1=$EFS_ID
efs_mount_point_1=/mnt/efs/fs1
mkdir -p "${efs_mount_point_1}"
test -f "/sbin/mount.efs" && printf "\n${file_system_id_1}:/ ${efs_mount_point_1} efs tls,_netdev\n" >>/etc/fstab || printf "\n${file_system_id_1}.efs.us-west-2.amazonaws.com:/ ${efs_mount_point_1} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0\n" >>/etc/fstab
test -f "/sbin/mount.efs" && printf "\n[client-info]\nsource=liw\n" >>/etc/amazon/efs/efs-utils.conf
retryCnt=15
waitTime=30
while true; do
    mount -a -t efs,nfs4 defaults
    if [ $? = 0 ] || [ $retryCnt -lt 1 ]; then
        echo File system mounted successfully
        break
    fi
    echo File system not available, retrying to mount.
    ((retryCnt--))
    sleep $waitTime
done

WAIT_BEFORE_EXECUTION=30
sleep $WAIT_BEFORE_EXECUTION

SESSION=work
sudo -H -u ec2-user tmux new -ds $SESSION
sudo -H -u ec2-user tmux send -t $SESSION "cd /mnt/efs/fs1/; \
source ./miniconda3_amazon_linux2/bin/activate benchmark; \
cd ./s3prl; \
git config --global user.name \"leo19941227\"; \
git config --global user.email \"leo19941227@gmail.com\"; \
git checkout aws; \
git pull origin aws; \
mkdir -p logs/; \
AWS_REGION=\$(curl http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\\\" '{print \$4}'); \
INSTANCE_ID=\$(curl -s http://169.254.169.254/latest/meta-data/instance-id); \
SPOT_FLEET_REQUEST_ID=\$(aws ec2 describe-spot-instance-requests --region \$AWS_REGION --filter \"Name=instance-id,Values=\$INSTANCE_ID\" --query \"SpotInstanceRequests[].Tags[?Key=='aws:ec2spot:fleet-request-id'].Value[]\" --output text); \
LOGNAME=\$(date +%Y%m%d%H%M%S)\"_COMMAND_PLACEHOLDER\"; \
TERMINATE_COMMAND=\"aws ec2 cancel-spot-fleet-requests --region \$AWS_REGION --spot-fleet-request-ids \$SPOT_FLEET_REQUEST_ID --terminate-instances\"; \
echo \$TERMINATE_COMMAND > \"logs/\"\${LOGNAME// /_}\".terminate\"; \
COMMAND_PLACEHOLDER 2> \"logs/\"\${LOGNAME// /_}\".log\"; \
WAIT_BEFORE_TERMINATION=30; \
sleep \$WAIT_BEFORE_TERMINATION; \
eval \$TERMINATE_COMMAND" ENTER
