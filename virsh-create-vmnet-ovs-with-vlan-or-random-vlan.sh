#!/usr/bin/env bash

#set -x
#set -e

name="$1"
ovsbr="$2"
vlan="$3"
rvlan="$(shuf -i 2-4094 -n 1)"


function usage(){
##########################
# prints the usage info ##
##########################

echo "$0 network-name ovs_bridge vlan"
exit 1
}

function check_input(){
#########################################
# checks if input parameters are empty ##
#########################################

if [[ "$name" = "" ]] || [[ "$ovsbr" = "" ]];then
        usage
else
        create_net $name $ovsbr $vlan
fi
}

function ck_br_vl(){
#####################################################
## checks if the network or the vlan already exist ##
#####################################################
nm=$1
br=$2
vl=$3
declare -a nets=($(virsh net-list | awk '{print $1}' | tail -n+3 | sed '/^\s*$/d'))

for i in ${nets[@]};do
	if [[ $i = $nm ]];then
		echo "A network with the name $i already exists"
		exit 1
	fi
done
for i in ${nets[@]};do
        if   [[ "$vl" = "" ]];then
                break
	elif [[ "$vl" = $(virsh net-dumpxml $i | grep "tag id" | awk -F"'" '{print $2}') ]];then
		echo "The vlan $vl is already in use by network $i "
		exit 1
	fi
done
}

function create_net(){
#####################################
## Creates and starts the networks ##
#####################################

if [ "$vlan" = "" ];then
	ck_br_vl $name $ovsbr
        echo "
         <network>
         <name>$name</name>
	 <uuid>$(uuid)</uuid>
         <forward mode='bridge'/>
         <bridge name='$ovsbr'/>
         <vlan>
            <tag id='"$rvlan"'/>
         </vlan>
         <virtualport type='openvswitch'/>
         </network> " > $name.xml
         virsh net-define $name.xml &> /dev/null 
         virsh net-start $name &> /dev/null
         virsh net-autostart $name &> /dev/null
         rm $name.xml
         echo "Network $name created in vlan $rvlan" 
         exit 0
else
	ck_br_vl $name $ovsbr $vlan
        echo "
          <network>
          <name>"$name"</name>
	  <uuid>$(uuid)</uuid>
          <forward mode='bridge'/>
          <bridge name='"$ovsbr"'/>
          <vlan>
             <tag id='"$vlan"'/>
          </vlan>
          <virtualport type='openvswitch'/>
          </network> " > $name.xml
          virsh net-define $name.xml &> /dev/null
          virsh net-start $name  &> /dev/null
          virsh net-autostart $name &> /dev/null
          rm $name.xml
          echo "Network $name created in vlan $vlan"
          exit 0
fi
}
function main(){
check_input
}
main 
