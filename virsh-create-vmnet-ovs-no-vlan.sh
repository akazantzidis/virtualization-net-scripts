#!/usr/bin/env bash
name=$1
ovsbr=$2

echo "
 <network>
 <name>$name</name>
 <uuid>$(uuid)</uuid>
 <forward mode='bridge'/>
 <bridge name='$ovsbr'/>
 <virtualport type='openvswitch'/>
 </network> " > $name.xml
virsh net-define $name.xml &> /dev/null
virsh net-start $name &> /dev/null
virsh net-autostart $name &> /dev/null
rm $name.xml
exit 0

