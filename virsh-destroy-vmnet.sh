#!/usr/bin/env bash
net=$1

function ret_help(){
echo "You must specify a network to destroy.
like: "virsh-destroy-vmnet.sh my-network" "
exit 0
}

function dest_net(){
virsh net-destroy $net &> /dev/null
virsh net-undefine $net &> /dev/null
logger "Network $net removed"
echo "Network" $net "removed"
exit 0
}

function main(){
if [[ "$net" == "" ]];then
    ret_help
    exit 0
else
        dest_net $net
        exit 0
fi
}
main
