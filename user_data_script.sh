#!/bin/bash

EFS_ID="fs-33f71937"
file_system_id_1=$EFS_ID
efs_mount_point_1=/mnt/efs/fs1/

if [ "$(cat /etc/os-release | head -n 1)" == "NAME=\"Amazon Linux\"" ]; then
    sudo yum -y update
    sudo yum -y upgrade

    yum install -y amazon-efs-utils
    yum install -y nfs-utils

    CONDA_ROOT=$efs_mount_point_1"/miniconda3_amazon_linux2/"
    NONROOT_USER="ec2-user"

elif [ "$(cat /etc/os-release | head -n 1)" == "NAME=\"Ubuntu\"" ]; then
    sudo apt-get -y update
    sudo apt-get -y upgrade

    git clone https://github.com/aws/efs-utils
    cd efs-utils/
    sudo apt install make
    sudo apt install binutils
    ./build-deb.sh
    sudo apt install -y ./build/$(ls ./build | grep amazon-efs-utils)
    cd ../

    CONDA_ROOT=$efs_mount_point_1"/miniconda3_ubuntu18/"
    NONROOT_USER="ubuntu"
fi

# mount efs
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

SESSION=launch
sudo -H -u $NONROOT_USER tmux new -ds $SESSION
sudo -H -u $NONROOT_USER tmux send -t $SESSION " \
cd ${efs_mount_point_1}; \
LOGNAME=\"COMMAND_PLACEHOLDER\"; \
LOGDIR=${efs_mount_point_1}\"/logs/\"\${LOGNAME// /_}; \
mkdir -p \${LOGDIR}; \
echo ${NONROOT_USER}@$(curl http://169.254.169.254/latest/meta-data/public-ipv4) > \${LOGDIR}/ssh" ENTER
