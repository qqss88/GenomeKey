#!/bin/bash

# Make sure /mnt was correctly setup before running this script

GLUSTER_VOLUME=$1
NUMBER_OF_NODES=$2

if [ `hostname` == "master" ]; then
    for node in `cat /etc/hosts | awk '{print $1}'`; do
        gluster peer probe "$node"
    done
    sudo mkdir -p /mnt/"${GLUSTER_VOLUME}"1
    
    # ssh "node001" "sudo mkdir -p /mnt/gv2"   # if you want to add this storage to the volume
    
    sudo gluster volume create ${GLUSTER_VOLUME} master:/mnt/"${GLUSTER_VOLUME}"1
    
    # sudo gluster volume create ${GLUSTER_VOLUME} master:/mnt/gv1 node001:/mnt/gv2 # if you want to add master:/gv0 AND node001:/gv1
    
    sleep 10
    
    sudo gluster volume start  ${GLUSTER_VOLUME}
fi


# Do this here to save some time for setting up glusterfs in the master node
for i in master $(printf "node%03d " {1..${NUMBER_OF_NODES}});
do
    ssh "$i" "sudo mkdir -p /gluster/${GLUSTER_VOLUME} && sudo mount -t glusterfs master:/${GLUSTER_VOLUME} /gluster/${GLUSTER_VOLUME}"
    ssh "$i" "sudo chown -R ubuntu:ubuntu /gluster/${GLUSTER_VOLUME}"
done

echo "gluster volume: $GLUSTER_VOLUME created"
echo "gluster volume mounted on all the $NUMBER_OF_NODES compute nodes"
