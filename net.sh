#!/usr/bin/env bash
shopt -s extglob

#set -e
set -x

function help(){
echo "
                                     HELP FILE FOR THE NET.SH SCRIPT

DESCRIPTION
               With the net.sh script you can manage openvswitch,create vxlan ports,bridges,fake bridges,
               set port trunk and vlan tag,create the interface's configuration files (for redhat based hosts)
               and add/remove ip from/to ovs bridges.

USAGE:
               net.sh [OPTION] [SUBOPTION-ARGUMENT]
		       EXAMPLE: net.sh --ab br0
		       EXAMPLE: net.sh --ab br0 --db br0

OPTIONS:
               --help || -h
               With this option you print the help file.

               --show || -s
               With this option you print the ovs configuration.

               --add-br || --ab
               With this option you can create a new ovs bridge on the host.Takes one argument the name of the bridge.
               IF it is an rh based host then it will configure/add the interfaces config files.
               EXAMPLE: net.sh --ab br0

               --del-br || --db
               With this option you can delete an ovs bridge on the host.Takes one argument the name of the bridge.
               IF it is an rh based host then it will configure/remove the interfaces config files.
               EXAMPLE: net.sh --db br0

               --add-fake-br || --afb
               With this option you create an ovs fake bridge on the host.Takes three arguments.
               IF it is an rh based host then it will configure/add the interfaces config files.

               -b
               The name of the ovs bridge that already exists(Parent bridge).

               -f
               The name of the fake bridge to be created on the parent bridge.

               -v
               The vlan number which the fake will use.
               EXAMPLE : net.sh --afb -b br0 -f fake-bridge -v 10
               This will create a fake bridge with name fake-bridge in vlan 10 in parent bridge br0

               --del-fake-br || --dfb
               With this option you delete one or multiple fake bridges.It takes one suboption and one argument.
               IF it is an rh based host then it will configure/remove the interfaces config files.

               -br
               The name of the bridge to be deleted.

               EXAMPLE:net.sh --dfb -br br0  ,  net.sh --dfb -br br0 -br br1

               --add-port || --ap
               With this option you can create/add a port in an ovs bridge.It takes two suboptions with one argument each.
               It is realy meant to use for adding real interfaces to an ovs bridge but you can add also a non-existing port.
               The ovs will create it but it will complain about it.IF it is an rh based host then it will configure/add the
               interfaces config files.

               -p
               The name of the port to be added.

               -b
               The name of the bridge where the port will be added.

               EXAMPLE: net.sh --ap -p eth0 -b br0

               --del-port || --dp
               With this option you remove a port from ovs bridge.It takes one argument the name of the port to be deleted.
               IF it is an rh based host then it will configure/remove the interfaces config files.

               EXAMPLE: net.sh --dp  eth0

               --set-port || --sp
               With this option you can set the tag,trunk values of a port.You can add trunk vlans or set the native vlan or you can
               remove the vlan and trunk values from the port configuration.

               -p
               The name of port to configure/add.

               -v
               To set the vlan tag of the interface.With this setting you can set the port as access port or
               set the native vlan of a trunked port.

               -t
               To set the trunks of the port.You have to supply multiple times the -t argument
               for each vlan you want to set.like : -t 10 -t 11 -t 12

               -dt
               To delete the the trunk configuration of the port.
               You must specify the port with -p.

               -dv
               To delete the tag configuration of the port.
               You must specify the port with -p.

               EXAMPLE: net.sh --sp -p vnet0 -v 10 -t 1 -t 2 -t 4
               This will set the port vnet0 native vlan to 10 and olso set the port trunk to  vlan 1,2,4,10.
               if you remove the native vlan tag then you have to recreate the trunks also (if you ever  you
               have before set specific vlans for trunks) because if you remove the the native vlan it is
               not automaticaly removed from the trunk vlans also.
               So if you do something like: net.sh --sp -dv 10 and before you add it you have already set
               manual the trunks to something (and automaticaly inserted the vlan 10 because
               you set the native vlan) you have to reconfigure also the vlans like -t 1 -t 2 -t 4
               so the vlan 10 be not trunked anymore else remains in the ovs configuration.

               --add-vxport || --avxp
               With this option you add a vxlan port to an ovs bridge.It takes four suboptions with one argument each.

               -p
               The port name to be created.

               -b
               The bridge that port will be created.

               -r
               The ip address of the remote endpoint.

               -k
               The vni key for the vxlan network.

               EXAMPLE: net.sh --avxp -p vxlan1 -b br0 -r 1.2.3.4 -k 1234
               This creates a vxlan port vxlan1 on bridge br0 with remote endpoint the host 1.2.3.4 and tunnel key 1234.

               --del-vxport || --dvxp
               With this option you remove a vxlan port.It takes one argument the name of the bridge.
               EXAMPLE: net.sh --dvxp  vx1

               --add-patch-port || --app
               With this option you create a patch connection between two bridges.It creates patch ports in every
               bridge you provide and creates a connection between them.
               It takes two suboptions with one argument each.

               -b || -bridge
               The first bridge to peer

               -p || -peer
               The peer bridge

               EXAMPLE: net.sh --app -b br0 -p br1
               This creates patch ports to br0->br1  and to br1->br0.

               --del-patch-port || --dpp
               With this option you can delete the patch ports of two bridges that you previusly
               created with --add-patch-port.It takes two suboptions with one argument each.
               CAUTION: This option can't delete patch ports that weren't created by net.sh
               -b
               The first peer bridge

               -peer
               The first's bridges peer

               EXAMPLE: net.sh --dpp -b br0 -p br1
               This deletes the patch ports to br0->br1 and br1->br0.

               --add-ip || --aip
               With this option you can add an ip address to an ovs bridge.It takes three suboptions with one argument each.
               IF it is an rh based host then it will configure/add the interfaces config files.

               -ip
               The ip address you want to configure.like 192.168.10.4,Do not specify mask here!! like /24 etc.

               -b
               The name of ovs bridge that will configure.

               -m
               The subnet mask value .Take a value between 1-32.

               EXAMPLE: net.sh --aip -ip 192.168.19.2 -b br0 -m 24
               This command will add the ip 192.168.19.2 with mask 24(255.255.255.0) to the bridge br0

               --del-ip || --dip
               With this option you canm delete an ip address from an ovs bridge.It takes three suboptions with one argument each.
               IF it is an rh based host then it will configure/remove the interfaces config files.

               -ip
               The ip address you want to configure.like 192.168.10.4,Do not specify mask here!! like /24 etc.

               -b
               The name of ovs bridge that will configure.

               -m
               The subnet mask value .Take a value between 1-32.

               EXAMPLE: net.sh --dip -ip 192.168.19.2 -b br0 -m 24
               This command will remove the ip 192.168.19.2 with mask 24(255.255.255.0) from the bridge br0.
"
}

function show(){
logger "net.sh|SHOW|INFO|asked to print the ovs configuration"
ovs-vsctl show
if [[ "$?" = 0 ]];then
   logger "net.sh|SHOW|INFO|Printed the running ovs configuration"
   return 0
else
   logger "net.sh|SHOW|ERROR|Could not print the ovs configuration"
   return 1
fi
}

function if_up(){
local int="$1"
logger "net.sh|IFUP|INFO|Request to set interface $int up"
local sup="$(ip link set dev $int up)"
ip link show ${int} | egrep "UP|UNKNOWN" >/dev/null
if [[ "$?" = 0 ]];then
    logger "net.sh|IFUP|INFO|Interface $int is up"
    return 0
else
    logger "net.sh|IFUP|ERROR|Interface $int is not up"
    return 1
fi
}

function if_down(){
local int="$1"
logger "net.sh|IF-DOWN|INFO|Request to set interface $int down"
local sup="$(ip link set dev $int down)"
ip link show $int | egrep "DOWN" >/dev/null
if [[ "$?" = 0 ]];then
    logger "net.sh|IF-DOWN|INFO|Interface $int is down"
    return 0
else
    logger "net.sh|IF-DOWN|ERROR|Interface $int is not down"
    return 1
fi
}

function add_ip(){
local int="$1"
local ip="$2"
local sip="$(ip addr add $ip dev $int 2>&1)"
local aip="$(ip -4 addr show dev $int | grep inet | awk '{print $2}')"
if [[ "$ip" = $aip ]];then
    logger "net.sh|ADD-IP|INFO|Ip $ip created on interface $int "
    return 0
else
    logger "net.sh|ADD-IP|ERROR|Cannot create ip $ip to the inteface $int"
    return 1
fi
}

function del_ip(){
local int="$1"
local ip="$2"
local dip="$(ip addr del $ip dev $int 2>&1)"
local aip="$(ip -4 addr show dev $int | grep inet | awk '{print $2}')"
if [[ "$aip" = "" ]];then
    logger "net.sh|ADD-IP|INFO|Ip $ip deleted from interface $int "
    return 0
else
    logger "net.sh|ADD-IP|ERROR|Cannot delete ip $ip from the inteface $int"
    return 1
fi
}

function check_if_physical(){
local inf="$1"
declare phys=($(lshw -c network | egrep "name|capabilities" | grep -B1 "cap_list" | awk '{print $3}' | awk NR%2))
for in in "${phys[@]}";do
    if [[ "$in" = $inf ]];then
         local ret=0
    fi
done
if [[ "$ret" = 0 ]];then
    logger "net.sh|CHECK_IF_PHYSICAL|INFO|The port $inf is physical"
    return 0
else
    #[[ "$ret" = 1 ]];then
    logger "net.sh|CHECK_IF_PHYSICAL|ERROR|The port $inf is not physical"
    return 1
fi
}

function check_if_Deb_or_RH(){
which apt-get &> /dev/null
local isdeb="$?"
which yum &> /dev/null
local isred="$?"

if [[ "$isdeb" = 0 ]] && [[ "$isred" = 0 ]];then
    logger "net.sh.|check_if_Deb_or_RH|ERROR|Can not be the at same time Debian based and Rhat based distro.Exiting"
    return 2
elif
    [[ "$isdeb" = 0 ]];then
    logger "net.sh.|check_if_Deb_or_RH|INFO|The host is debian based"
    return 0
elif
    [[ "$isred" = 0 ]];then
    logger "net.sh.|check_if_Deb_or_RH|INFO|The host is red hat based"
    return 1
fi
}

function del_inf_config_RH(){
local inf="/etc/sysconfig/network-scripts/ifcfg-$1"
logger "net.sh|del_inf_config_RH|INFO|Requested to delete the interface configuration file ifcfg-$1."
if [[ -e $inf ]];then
    :
else
    logger "net.sh|del_inf_config_RH|ERROR|The configuration file of port $1 does not exist"
    echo "The configuration file of interface $1 does not exist"
    sleep 1
    return 1
fi
rminf="$(rm -f $inf 2>&1)"
if [[ "$rminf" = "" ]];then
    logger "net.sh|del_inf_config_RH|INFO|Deleted the interface configuration file ifcfg-$1."
    return 0
else
    logger "net.sh|del_inf_config_RH|ERROR|Some error occured.Check the logs."
    echo "The interface $1 cannot be deleted."
    sleep 1
    return 1
fi
}

function create_real_inf_port_to_bridge_RH(){
local dev="$1"
local bridge="$2"
local dir=/etc/sysconfig/network-scripts/
logger "net.sh|Create_real_inf_port_to_bridge_RH|INFO|Requested to create interface configuration file for port $dev which is attached to bridge $bridge."
echo "TYPE=Ethernet
DEVICE="dev"
NAME=$dev
ONBOOT=yes
OVS_BRIDGE=$bridge
TYPE="OVSPort"
DEVICETYPE="ovs" " > $dir/ifcfg-$dev
if [[ -e $dir/ifcfg-$dev ]];then
    logger "net.sh|Create_real_inf_port_to_bridge_RH|INFO|Created interface configuration file for port $dev which is attached to bridge $bridge."
    return 0
else
    logger "net.sh|Create_real_inf_port_to_bridge_RH|ERROR|Cannot create interface configuration file for port $dev which is attached to bridge $bridge."
    echo "Cannot create interface configuration file for port $dev which is attached to bridge $bridge."
    return 1
fi
}

function create_bridge_with_ip_RH(){
local bridge="$1"
local ip="$2"
local subnet="$3"
local gate="$4"
local dns="$5"
local dir=/etc/sysconfig/network-scripts/
#GATEWAY=$gate
#DNS1=$dns
logger "net.sh|Create_bridge_with_ip_RH|INFO|Requested to create interface configuration file for bridge $bridge with ip $ip/$subnet,gateway $gate and dns $dns."
echo "DEVICE="$bridge"
BOOTPROTO="none"
IPADDR=$ip
PREFIX=$subnet
ONBOOT="yes"
TYPE="OVSBridge"
DEVICETYPE="ovs" " > $dir/ifcfg-$bridge
if [[ -e $dir/ifcfg-$bridge ]];then
    logger "net.sh|Create_bridge_with_ip_RH|INFO|Created interface configuration file for bridge $bridge with ip $ip/$subnet,gateway $gate and dns $dns."
    return 0
else
    logger "net.sh|Create_bridge_with_ip_RH|ERROR|Cannot create interface configuration file for bridge $bridge with ip $ip/$subnet,gateway $gate and dns $dns."
    echo "Cannot create interface configuration file for bridge $bridge with ip $ip/$subnet,gateway $gate and dns $dns."
    return 1
fi
}

function create_bridge_RH(){
local bridge="$1"
local dir=/etc/sysconfig/network-scripts/
echo "DEVICE="$bridge"
BOOTPROTO="none"
ONBOOT="yes"
TYPE="OVSBridge"
DEVICETYPE="ovs" " > $dir/ifcfg-$bridge
if [[ -e $dir/ifcfg-$bridge ]];then
    logger "net.sh|Create_bridge_RH|INFO|Created interface configuration file for bridge $bridge."
    return 0
else
    logger "net.sh|Create_bridge_RH|ERROR|Cannot create interface configuration file for bridge $bridge."
    echo "Cannot create interface configuration file for bridge $bridge."
    return 1
fi
}

function check_if_vxport_exists(){
local vxport_to_check="$1"
local ret=0
declare vxports=($(ovs-vsctl list interface | egrep "name|type" | grep -B1 vxlan | head -n1 | awk '{print $3}' | tr -d \"/))
for vx in "${vxports[@]}";do
    if [[ "$vx" = $vxport_to_check ]];then
         ret=1
    fi
done
if [[ "$ret" = 0 ]];then
    logger "net.sh|CHECK_IF_VXPORT_EXISTS|INFO|The vxlan port $vxport_to_check the user provided does not exist"
    return 0
else
    logger "net.sh|CHECK_IF_VXPORT_EXISTS|ERROR|The ip $vxport_to_check the user provided already exists"
    return 1
fi
}

check_mask(){
if [[ "$1" -ge 1 && "$1" -le 32 ]];then
     local ret=0
fi
if [[ "$ret" = 0 ]];then
    logger "net.sh|CHECK_MASK|INFO|The network mask $1 is legit network mask"
    return 0
else
    logger "net.sh|CHECK_MASK|ERROR|The network mask $1 is not legit network mask"
    echo "The network mask $1 is not in legit network mask range (1..32)"
    exit 1
fi

}
function check_vxkey(){
if [[ "$1" -ge 1 && "$1" -le 16777215 ]];then
     local ret=0
fi
if [[ "$ret" = 0 ]];then
    logger "net.sh|CHECK_VxKEY|INFO|The vxlan key $1 is legit vxlan vni key"
    return 0
else
    logger "net.sh|CHECK_VxKEY|ERROR|The vxlan key $1 is not legit vxlan vni key"
    echo "The vxlan key $1 is not in the legit vxlan range (1..16777215)"
    exit 1
fi
}

function check_if_ip_valid(){
local ip_check="$1"
if [[ "$ip_check" =~ ^((1?[0-9]{1,2}|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9]{1,2}|2[0-4][0-9]|25[0-5])$ ]]; then
  logger "net.sh|CHECK_IF_IP_IS_VALID|INFO|The user specified ip is valid"
  return 0
else
  logger "net.sh|CHECK_IF_IP_IS_VALID|ERROR|The user specified ip is invalid"
  return 1
fi
}

function check_if_ip_exits(){
local ip_to_check="$1"
declare ips=($(ip addr | grep inet | awk '{print $2}' | awk -F / '{print $1}'))
for ip in "${ips[@]}";do
    if [[ "$ip" = $ip_to_check ]];then
        local ret=0
    fi
done
if [[ "$ret" = 0 ]];then
    logger "net.sh|CHECK_IF_IP_EXISTS|INFO|The ip $ip_to_check the user provided exists"
    return 0
else
    logger "net.sh|CHECK_IF_IP_EXISTS|ERROR|The ip $ip_to_check the user provided does not exist"
    echo "The ip $ip_to_check does not exist"
    exit 1
fi
}

function check_if_port_exists(){
local port_to_check="$1"
declare pinfs=($(lshw -c network | egrep "name|capabilities" | grep -B1 "cap_list" | awk '{print $3}' | awk NR%2))
declare ovsinfs=($(ovs-vsctl list port | grep name | awk -F: '{print $2}' | tr -d \"/))
declare ipinfs=($(ip link show | awk -F: '{print $2}' | awk NR%2))
for port in "${ipinfs[@]}";do
    if [[ "$port" = $port_to_check ]];then
        local ret=0
        break
    fi
done
for port in "${pinfs[@]}";do
    if [[ "$port" = $port_to_check ]];then
        local ret=0
        break
    fi
done
for port in "${ovsinfs[@]}";do
    if [[ "$port" = $port_to_check ]];then
        local ret=0
        break
    fi
done
if [[ "$ret" = 0 ]];then
    logger "net.sh|CHECK_IF_PORT_EXISTS|INFO|The port $port_to_check the user provided exists"
    return 0
else
    logger "net.sh|CHECK_IF_PORT_EXISTS|ERROR|The port $port_to_check the user provided does not exist"
    echo "The port $port_to_check does not exist"
    exit 1
fi
}

function check_vlan(){
if [[ "$1" -ge 1 && "$1" -le 4094 ]];then
     local ret=0
fi
if [[ "$ret" = 0 ]];then
    logger "net.sh|CHECK_VLAN|INFO|The vlan $1 is legit vlan number"
    return 0
else
    logger "net.sh|CHECK_VLAN|ERROR|The vlan $1 is not legit vlan number"
    echo "The vlan $1 is not in the legit vlan range (1..4094)"
    exit 1
fi
}

function check_if_bridge_Exists(){
local bridge="$1"
local system_bridges="$(ovs-vsctl list-br)"
for br in $system_bridges;do
    if [[ "$bridge" = $br ]];then
        local ret=0
    fi
done
if [[ "$ret" = 0 ]];then
    logger "net.sh|CHECK_IF_BRIDGE_EXISTS|INFO|The bridge $bridge the user provided exist"
    return 0
else
    logger "net.sh|CHECK_IF_BRIDGE_EXISTS|ERROR|The bridge $bridge the user provided does not exist"
    echo "The bridge $bridge does not exist"
    exit 1
fi
}

function create_bridge(){
if [[ "$1" != "" ]];then
    :
else
    logger "net.sh|CREATE_BRIDGE|ERROR|INPUT ARGUMENT WAS NULL"
    exit 1
fi
local bridge="$1"
local var="$(ovs-vsctl add-br "$bridge" 2>&1)"
if [[ "$var" = "" ]];then
    logger "net.sh|INFO|Created bridge $bridge"
    return 0
else
    logger "net.sh|CREATE_BRIDGE|ERROR|Could not create the bridge $bridge"
    logger "net.sh|CREATE_BRIDGE|ERROR|$var"
    echo "Could not create the bridge $bridge,due $var"
    exit 1
fi
}

function delete_bridge(){
if [[ "$1" = "" ]];then
    logger "net.sh|CHECK_IF_BRIDGE_EXISTS|ERROR|The user provided NULL bridge value"
    echo "You have to specify a bridge to delete"
    exit 1
fi
check_if_bridge_Exists "$1"
if [[ "$?" -eq 0 ]];then
    local bridge="$1"
    if_down "$bridge"
    local var="$(ovs-vsctl del-br "$bridge" 2>&1)"
    if [[ "$var" = "" ]];then
       logger "net.sh|DELETE_BRIDGE|INFO|Deleted bridge $bridge"
       return 0
    else
       logger "net.sh|DELETE_BRIDGE|ERROR|Could not delete the bridge $bridge"
       logger "net.sh|DELETE_BRIDGE|ERROR|$var"
       echo "Could not delete the bridge $bridge due $var"
       exit 1
    fi
fi
}

function create_fbridge(){
if [[ "$1" = "" ]];then
    logger "net.sh|CREATE_FBRIDGE|ERROR|The user provided NULL bridge value"
    echo "You have to specify an existing  bridge"
    exit 1
fi
check_if_bridge_Exists "$1"
if [[ "$?" -eq 0 ]];then
    local bridge="$1"
fi
if [[ "$2" = "" ]];then
    logger "net.sh|CREATE_FBRIDGE|ERROR|The user provided NULL fake bridge value"
    echo "You have to specify a fake bridge name"
    exit 1
fi
local fbridge="$2"
check_vlan "$3"
if [[ "$?" -eq 0 ]];then
    local vlan="$3"
fi
local var="$(ovs-vsctl add-br "$fbridge" "$bridge" "$vlan" 2>&1)"
if [[ "$var" = "" ]];then
    logger "net.sh|CREATE_FBRIDGE|INFO|Created bridge "$fbridge" on vlan $vlan on parent bridge $bridge"
    return 0
else
    logger "net.sh|CREATE_FBRIDGE|ERROR|Could not create the bridge "$fbridge" on vlan $vlan on parent bridge $bridge"
    logger "net.sh|CREATE_FBRIDGE|ERROR|$var"
    echo "Could not create the bridge $fbridge on vlan $vlan on parent bridge $bridge due $var"
    exit 1
fi
}

function inf_file_deb(){
local debfile=/etc/network/interfaces
}

function add-port(){
check_if_bridge_Exists "$2"
local br="$2"
local port="$1"
local var="$(ovs-vsctl add-port "$br" "$port" 2>&1)"
if [[ "$var" = "" ]];then
    logger "net.sh|ADD-PORT|INFO|Added port "$port" on bridge $br"
    return 0
else
    logger "net.sh|ADD-PORT|ERROR|Could not add port "$port" on bridge $br"
    logger "net.sh|ADD-PORT|ERROR|$var"
    echo "Could not add port "$port" on bridge $br due $var"
    exit 1
fi
}

function del-port(){
check_if_port_exists "$1"
local port="$1"
local var="$(ovs-vsctl del-port "$port" 2>&1)"
if [[ "$var" = "" ]];then
    logger "net.sh|DEL-PORT|INFO|Deleted port $port"
    return 0
else
    logger "net.sh|DEL-PORT|ERROR|Could not delete port $port"
    logger "net.sh|DEL-PORT|ERROR|$var"
    echo "Could not delete port $port due $var"
    exit 1
fi
}

function set-port(){
for arg in "$@";
do
  case "$arg" in
  -p)
    check_if_port_exists "$2"
    local port="$2"
    ;;
  -v)
     check_vlan "$2"
     local tag="$2"
     ;;
  -t)
     local trunks="$2"
     ;;
  -dv)
     ovs-vsctl set port "$2" tag=[]
     logger "net.sh|SET-PORT|INFO|remove from port $port the native vlan"
     ;;
  -dt)
     ovs-vsctl set port "$2" trunk=[]
     logger "net.sh|SET-PORT|INFO|remove from port $port the trunk-vlans"
     ;;
     esac
     shift
done
if [[ "$port" != "" ]] && [[ "$tag" != "" ]] && [[ "$trunks" != "" ]];then
    local var="$(ovs-vsctl set port "$port" tag=["$tag"] -- set port "$port" trunks=["$trunks"] 2>&1)"
    if [[ "$var" = "" ]];then
        logger "net.sh|SET-PORT|INFO|set port $port with native vlan $tag and trunks $trunks"
        return 0
    else
        logger "net.sh|SET-PORT|ERROR|set port $port with native vlan $tag and trunks $trunks failed"
        logger "net.sh|SET-PORT|ERROR|$var"
        echo "set port $port with native vlan $tag and trunks $trunks due $var"
        exit 1
    fi
elif [[ "$port" != "" ]] && [[ "$tag" != "" ]];then
    local var="$(ovs-vsctl set port "$port" tag=["$tag"] 2>&1)"
    if [[ "$var" = "" ]];then
        logger "net.sh|SET-PORT|INFO|set port $port with native vlan $tag"
        return 0
    else
        logger "net.sh|SET-PORT|ERROR|set port $port with native vlan $tag failed"
        logger "net.sh|SET-PORT|ERROR|$var"
        echo "set port $port with native vlan $tag due $var"
        exit 1
    fi
elif [[ "$port" != "" ]] && [[ "$trunks" != "" ]];then
    local var="$(ovs-vsctl set port "$port" trunks=["$trunks"] 2>&1)"
    if [[ "$var" = "" ]];then
        logger "net.sh|SET-PORT|INFO|set port $port with trunk-vlans $trunks"
        return 0
    else
        logger "net.sh|SET-PORT|ERROR|set port $port with trunks-vlans $trunks failed"
        logger "net.sh|SET-PORT|ERROR|$var"
        echo "set port $port trunk-vlans $trunks due $var"
        exit 1
    fi
fi
}

function create_vxlan(){
local bridge="$1"
local name="$2"
local rip="$3"
local key="$4"
local var="$(ovs-vsctl add-port $bridge $name -- set interface $name type=vxlan options:remote_ip=$rip options:key=$key 2>&1)"
if [[ "$var" = "" ]];then
        logger "net.sh|CREATE_VXLAN|INFO|created vxlan $name port in bridge $bridge with remote endpoint $rip and key $key"
        return 0
    else
        logger "net.sh|CREATE_VXLAN|ERROR|Cannot create vxlan $name port in bridge $bridge with remote endpoint $rip and key $key"
        logger "net.sh|CREATE_VXLAN|ERROR|$var"
        echo "Cannot create vxlan $name port in bridge $bridge with remote endpoint $rip and key $key"
        exit 1
fi
}

function create_patch(){
local br1="$1"
local br2="$2"
ovs-vsctl --may-exist add-br "$br1"
ovs-vsctl --may-exist add-br "$br2"
local crp1="$(ovs-vsctl add-port $br1 patch-connect-$br1 -- set interface patch-connect-$br1 type=patch options:peer=patch-connect-$br2 2>&1)"
if [[ "$crp1" = "" ]];then
    logger "net.sh|CREATE_PATCH|INFO|Created patch port patch-connect-$br1"
    if [[ "$?" = 0 ]];then
       logger "net.sh|CREATE_PATCH|INFO|PORT patch-connect-$br1 is up"
    else
       logger "net.sh|CREATE_PATCH|ERROR|PORT patch-connect-$br1 is not up"
    fi
else
    logger "net.sh|CREATE_PATCH|ERROR|Cannot create patch port patch-connect-$br1"
    logger "net.sh|CREATE_PATCH|ERROR|$crp1"
    echo  "Cannot create patch port patch-connect-$br1"
    exit 1
fi
local crp2="$(ovs-vsctl add-port $br2 patch-connect-$br2 -- set interface patch-connect-$br2 type=patch options:peer=patch-connect-$br1 2>&1)"
if [[ "$crp2" = "" ]];then
    logger "net.sh|CREATE_PATCH|INFO|Created patch port patch-connect-$br2"
    if [[ "$?" = 0 ]];then
       logger "net.sh|CREATE_PATCH|INFO|PORT patch-connect-$br2 is up"
    else
       logger "net.sh|CREATE_PATCH|ERROR|PORT patch-connect-$br2 is not up"
    fi
else
    logger "net.sh|CREATE_PATCH|ERROR|Cannot create patch port patch-connect-$br2"
    logger "net.sh|CREATE_PATCH|ERROR|$crp2"
    echo  "Cannot create patch port patch-connect-$br2"
    echo "restoring interfaces to the state before.."
    dport="$(ovs-vsctl del-port patch-connect-$br1 2>&1)"
    if [[ "$dport" = "" ]];then
        logger "net.sh|CREATE_PATCH_ERROR_CREATE_PATCH_2|ERROR|Deleted the previous created patch port patch-connect-$br1"
        echo "Cleaned the previous created patch interface patch-connect-$br1"
        exit 1
    else
         logger "net.sh|CREATE_PATCH_ERROR_CREATE_PATCH_2|ERROR|Cannot remove the previous created patch port patch-connect-$br1"
         echo "The interface patch-connect-$br1 could not be deleted.You must manual remove it"
         exit 1
    fi
fi
return 0
}

function delete_patch(){
local delbr="$1"
local delpeerbr="$2"
#local delpeerbr="$(ovs-vsctl show | egrep "($del-patch-br)|peer" | tail -n+2 | grep peer | awk -F: '{print $2}' | tr -d "\"{}/"  | awk -F= '{print $2}')"
local dp1="$(ovs-vsctl del-port patch-connect-$delbr 2>&1)"
if [[ "$dp1" = "" ]];then
    logger "net.sh|DELETE_PATCH|INFO|Deleted patch port patch-connect-$delbr"
else
    logger "net.sh|DELETE_PATCH|ERROR|Cannot delete patch port patch-connect-$delbr"
    logger "net.sh|DELETE_PATCH|ERROR|$dp1"
    echo "Cannot delete patch-port patch-connect-$delbr.You must manual remove it"
    exit 1
fi
local dp2="$(ovs-vsctl del-port patch-connect-$delpeerbr 2>&1)"
if [[ "$dp2" = "" ]];then
    logger "net.sh|DELETE_PATCH|INFO|Deleted patch port patch-connect-$delpeerbr"
else
    logger "net.sh|DELETE_PATCH|ERROR|Cannot delete patch port patch-connect-$delpeerbr"
    logger "net.sh|DELETE_PATCH|ERROR|$dp2"
    echo "Cannot delete patch-port patch-connect-$delpeerbr.You must manual remove it"
    exit 1
fi
}

function pars(){
for arg in "$@"
do
  case "$arg" in
  --show|-s)
      show
      return "$?"
      ;;
  --add-br|--ab)
       local br="$2"
       logger "net.sh|CREATE-BRIDGE|INFO|Request to add bridge $br"
       create_bridge "$br"
       if_up "$br"
       check_if_Deb_or_RH
       if [[ "$?" = 0 ]];then
           echo "Debian based host detected.You must modify your own the interface configuration entries file"
           exit 0
       elif
           [[ "$?" = 1 ]];then
               create_bridge_RH "$br"
           if [[ "$?" = 0 ]];then
               exit 0
           else
               exit 1
           fi
       fi
       ;;
  --del-br|--db)
       local br="$2"
	   logger "net.sh|DELETE-BRIDGE|INFO|The bridge $br requested for deletion"
       delete_bridge "$br"
       check_if_Deb_or_RH
       if [[ "$?" = 0 ]];then
           echo "Debian based host detected.You must modify your own the interface configuration entries file"
           exit 0
       elif
           [[ "$?" = 1 ]];then
               del_inf_config_RH "$br"
           if [[ "$?" = 0 ]];then
               exit 0
           else
               exit 1
           fi
       fi
       ;;
  --add-fake-br|--afb)
       if [[ "$#" -eq 7 ]];then
           :
       elif [[ "$#" -lt 7 ]];then
           echo "You did not provide enough arguments"
           exit 1
       elif [[ "$#" -gt 7 ]];then
           echo "You provided to many arguments"
           exit 1
       fi
       for arg in "$@"
       do
         case "$arg" in
          -b)
           check_if_bridge_Exists "$2"
           local br="$2"
	       ;;
	      -f)
       	   local fbr="$2"
	       ;;
          -v)
           check_vlan "$2"
	       local vlan="$2"
	       ;;
	       esac
	       shift
       done
       if [[ "$br" != "" ]] && [[ "$fbr" != "" ]] && [[ "$vlan" != "" ]];then
           logger "net.sh|ADD-FAKE-BRIDGE|INFO|The fake bridge $fbr requested to be created on bridge $br on vlan $vlan"
           create_fbridge "$br" "$fbr" "$vlan"
           if_up "$fbr"
           check_if_Deb_or_RH
           if [[ "$?" = 0 ]];then
               echo "Debian based host detected.You must modify your own the interface configuration file."
               exit 0
           elif
               [[ "$?" = 1 ]];then
               create_bridge_RH "$br"
               if [[ "$?" = 0 ]];then
                   exit 0
               else
                   exit 1
               fi
           fi
       else
	       if [[ "$br" = "" ]];then
		       logger "net.sh|ADD-FAKE-BRIDGE|ERROR|User didn't provided parent bridge when he tried to create the fake bridge $fbr on vlan $vlan"
		       echo "You must specify a parent bridge with -b parent bridge"
		       return 1
           elif [[ "$fbr" = "" ]];then
		       logger "net.sh|ADD-FAKE-BRIDGE|ERROR|User didn't provided the name of fake bridge when he tried to create it on bridge $br on vlan $vlan"
		       echo "You must specify the fake bridge name with -f name"
		       return 1
           elif [[ "$vlan" = "" ]];then
		       logger "net.sh|ADD-FAKE-BRIDGE|ERROR|User didn't provided vlan number when he tried to create the fake bridge $fbr on bridge $br"
		       echo "You must specify a vlan with -v vlan"
		       return 1
	       fi
	   fi
       ;;
  --del-fake-br|--dfb)
       for arg in "$@"
       do
         case "$arg" in
         -br)
          check_if_bridge_Exists "$2"
          logger "net.sh|DELETE-FAKE-BRIDGE|INFO|$2 deletion requested"
          local br="$2"
          if_down "$br"
          delete_bridge "$br"
          check_if_Deb_or_RH
          if [[ "$?" = 0 ]];then
              echo "Debian based host detected.You must modify your own the interface configuration entry file."
              exit 0
          elif
             [[ "$?" = 1 ]];then
             del_inf_config_RH "$br"
             if [[ "$?" = 0 ]];then
                 exit 0
             else
                 exit 1
             fi
          fi
          ;;
          esac
          shift
       done
       ;;
  --add-port|--ap)
       shift
       if [[ "$#" != 4 ]];then
              logger "net.sh|ADD-PORT|ERROR|Bad number of arguments specified by user"
              echo "Bad number of arguments specified by user.You have to specify one port and one bridge every time."
              exit 1
       fi
       for ar in "$@"
       do
         case "$ar" in
	     -p)
	       check_if_port_exists "$2"
           local port="$2"
	       ;;
         -b)
           check_if_bridge_Exists "$2"
           local brg="$2"
	       ;;
	     esac
	     shift
       done
       if [[ "$brg" != "" ]] && [[ "$port" != "" ]];then
	       logger "net.sh|ADD-PORT|INFO|Request to add port $port to bridge $brg"
	       add-port "$port" "$brg"
	       check_if_physical "$port"
	       if [[ "$?" = 0 ]];then
	           create_real_inf_port_to_bridge_RH "$brg"
	           if  [[ "$?" = 0 ]];then
	               exit 0
	           else
	               exit 1
	           fi
	       fi
	       if_up "$brg"
	       if_up "$port"
	       return 0
       elif [[ "$brg" = "" ]];then
               logger "net.sh|ADD-PORT|ERROR|User didn't provided a bridge to add port $port"
	           echo "You must provide a bridge with -b bridge"
	           exit 1
       elif [[ "$port" = "" ]];then
               logger "net.sh|ADD-PORT|ERROR|User didn't provided an interface to add bridge $brg"
	           echo "You must specify an interface to connect to the bridge $brg"
	           exit 1
       fi
       ;;
   --set-port|--sp)
       #if [[ "$#" -ge 4 && "$#" -le 5 ]];then
       #    :
       #elif [[ "$#" -lt 3 ]];then
       #    echo "You did not provide enough arguments"
       #    exit 1
       #elif [[ "$#" -gt 5 ]];then
       #    echo "You provided to many arguments"
       #    exit 1
       #fi
       local declare trunks
       for arg in "$@"
       do
	     case "$arg" in
         -p)
          check_if_port_exists "$2"
          local port="$2"
	      ;;
         -v)
          check_vlan "$2"
          local vlan="$2"
	      ;;
         -t)
          check_vlan "$2"
          trunks+=("$2")
	      ;;
	      -dt)
	       for i in "$@";
	       do
	         case "$i" in
	         -p)
	          local port="$3"
	          set-port -dt "$port"
	          exit "$?"
	           ;;
	          esac
	       done
	       ;;
	      -dv)
	       for j in "$@";
	       do
	        case "$j" in
	        -p)
	         local port="$3"
	         set-port -dv "$port"
	         #return "$?"
	         ;;
	         esac
	       done
	       ;;
	      esac
	      shift
	   done
	   local var=""
	   if [[ "$vlan" != "" && "${#trunks[@]}" != 0 ]];then
	       var=$vlan
	       for i in ${trunks[@]};do
	           var="$var,$i"
           done
	       local fvar="$(echo "$var" | cut -c1-)"
	   else
	       for i in ${trunks[@]};do
	           var="$var,$i"
           done
	       local fvar="$(echo "$var" | cut -c2-)"
	   fi
	   if [[ "$port" != "" ]] && [[ "$vlan" != "" ]] && [[ "$fvar" != "" ]];then
           logger "net.sh|SET-PORT|INFO|Request to set port $port with native vlan $vlan and trunk-vlans $fvar"
	       set-port  -p "$port" -v "$vlan" -t "$fvar"
	       return "$?"
	   elif [[ "$port" != "" ]] && [[ "$fvar" != "" ]] && [[ "$vlan" = "" ]];then
	       logger "net.sh|SET-PORT|INFO|Request to set port $port with vlan-trunks $fvar"
           set-port -p "$port" -t "$fvar"
           return "$?"
       elif [[ "$port" != "" ]] && [[ "$vlan" != "" ]] && [[ "$fvar" = "" ]];then
	       logger "net.sh|SET-PORT|INFO|Request to set port $port in vlan $vlan"
	       set-port -p "$port" -v "$vlan"
	       return "$?"
	   elif [[ "$port" = "" ]];then
	       logger "net.sh|SET-PORT|ERROR|User didn't specify a port to set"
	       echo "You must specify a port to set a value "
	       exit 1
       fi
       ;;
  --del-port|--dp)
       if [[ "$#" = 2 ]];then
            :
        elif [[ "$#" -lt 2 ]];then
           echo "You did not provide enough arguments"
           exit 1
       elif [[ "$#" -gt 2 ]];then
           echo "You provided to many arguments"
           exit 1
       fi
       check_if_port_exists "$2"
       local port="$2"
       logger "net.sh|DELETE-PORT|INFO|Request to delete port $port"
       if_down "$port"
       del-port "$port"
       check_if_physical "$port"
       if [[ "$?" = 0 ]];then
          del_inf_config_RH "$port"
          if [[ "$?" = 0 ]];then
              exit 0
          else
              exit 1
          fi
       else
           exit 0
       fi
       ;;
  --add-vxport|--avxp)
        if [[ "$#" = 9 ]];then
            :
        elif [[ "$#" -lt 9 ]];then
           echo "You did not provide enough arguments"
           exit 1
       elif [[ "$#" -gt 9 ]];then
           echo "You provided to many arguments"
           exit 1
       fi
        for i in "$@";
        do
          case "$i" in
          -p)
          check_if_vxport_exists "$2"
          if [[ "$?" = 1 ]];then
              echo " The port $2 already exists,please specify another one or delete this port and recreate it."
              logger "net.sh|ADD-VXLAN-PORT|ERROR|The user specified port already exists"
              exit 1
          else
              local vxport="$2"
          fi
           ;;
          -b)
           check_if_bridge_Exists "$2"
           local br="$2"
           ;;
          #-l)
           #check_if_ip_valid "$2"
           #check_if_ip_exists "$2"
           #local ltun="$2"
           #;;
          -r)
           check_if_ip_valid "$2"
           if [[ "$?" = 0 ]];then
              local rtun="$2"
           else
               exit 1
           fi
           ;;
          -k)
           check_vxkey "$2"
           local key="$2"
           ;;
           esac
           shift
       done
       if [[ "$vxport" != "" ]] && [[ "$br" != "" ]] && [[ "$rtun" != "" ]] && [[ "$key" != "" ]];then
           logger "net.sh|ADD-VXLAN-PORT|INFO|Request to add vxlan port $vxport on bridge $br with VNI $key and remote endpoint $rtun"
           create_vxlan $br $vxport $rtun $key
           return "$?"
       elif
           [[ "$vxport" = "" ]];then
               logger "net.sh|ADD-VXLAN-PORT|ERROR|The user didn't specify vxlan port name"
               echo "you must specify a name for the vxlan port to be created."
               exit 1
       elif
            [[ "$br" = "" ]];then
                logger "net.sh|ADD-VXLAN-PORT|ERROR|The user didn't specify bridge name"
                echo "you must specify a name for the bridge which the vxlan port is going to be created."
                exit 1
       #elif
       #     [[ "$ltun" = "" ]];then
       #         logger "net.sh|ADD-VXLAN-PORT|ERROR|The user didn't specify local tunnel endpoint"
       #         echo "you must specify a local tunnel endpoint"
       #         exit 1
       elif
            [[ "$rtun" = "" ]];then
                logger "net.sh|ADD-VXLAN-PORT|ERROR|The user didn't specify remote tunnel endpoint"
                echo "you must specify a remote tunnel endpoint"
                exit 1
       elif
            [[ "$key" = "" ]];then
                logger "net.sh|ADD-VXLAN-PORT|ERROR|The user didn't specify a vxlan tunnel key"
                echo "you must specify a tunnel key."
                exit 1
       fi
       ;;
  --del-vxport|--dvxp)
       if [[ "$#" -eq 2 ]];then
           :
       elif [[ "$#" -ge 3 ]];then
           echo "You provided to many arguments"
           exit 1
       fi
       check_if_vxport_exists "$2"
       if [[ "$?" = 0 ]];then
           echo " The port $2 does not exists,please specify another one or the correct port name"
           logger "net.sh|DEL-VXLAN-PORT|ERROR|The user specified port that does not exist"
           exit 1
       else
              local vxport="$2"
       fi
       logger "net.sh|DELETE-VXLAN-PORT|INFO|Request to remove vxlan port $vxport"
       del-port "$vxport"
       return "$?"
       ;;
  --add-patch-port|--app)
       if [[ "$#" -eq 5 ]];then
           :
       elif [[ "$#" -lt 5 ]];then
           echo "You did not provide enough arguments"
           exit 1
       elif [[ "$#" -gt 5 ]];then
           echo "You provided to many arguments"
           exit 1
       fi
       for arg in "$@";
       do
        case "$arg" in
        -b|-bridge)
         local br="$2"
         ;;
        -p|-peer)
         local peer="$2"
         ;;
         esac
         shift
        done
        if [[ "$br" != "" ]] && [[ "$peer" != "" ]];then
            logger "net.sh|ADD-PATCH-PORT|INFO|Request to add patch ports on bridge $br with peer bridge $peer"
            create_patch $br $peer
            return "$?"
        elif
            [[ "$br" = "" ]];then
                logger "net.sh|ADD-PATCH-PORT|ERROR|The user did not provided bridge for the patch port"
                echo "You have to provide a bridge to create a patch port"
                exit 1
        elif
            [[ "$peer" = "" ]];then
                logger "net.sh|ADD-PATCH-PORT|ERROR|The user did not provided a peer name for the patch port"
                echo "You have to provide a peer name to create a patch port"
                exit 1
        fi
       ;;
  --del-patch-port|--dpp)
       if [[ "$#" -eq 5 ]];then
           :
       elif [[ "$#" -lt 5 ]];then
           echo "You did not provide enough arguments"
           exit 1
       elif [[ "$#" -gt 5 ]];then
           echo "You provided to many arguments"
           exit 1
       fi
       for arg in "$@";
       do
        case "$arg" in
        -b|-bridge)
         local br="$2"
         ;;
        -p|-peer)
         local peer="$2"
         ;;
         esac
         shift
        done
        if [[ "$br" != "" ]] && [[ "$peer" != "" ]];then
            logger "net.sh|DEL-PATCH-PORT|INFO|Request to delete patch ports on bridge $br with peer bridge $peer"
            delete_patch $br $peer
            return "$?"
        elif
            [[ "$br" = "" ]];then
                logger "net.sh|ADD-PATCH-PORT|ERROR|The user did not provided bridge for the patch port"
                echo "You have to provide a bridge to create a patch port"
                exit 1
        elif
            [[ "$peer" = "" ]];then
                logger "net.sh|ADD-PATCH-PORT|ERROR|The user did not provided a peer name for the patch port"
                echo "You have to provide a peer name to create a patch port"
                exit 1
        fi
       ;;
  --add-ip|--aip)
      if [[ "$#" -eq 7 ]];then
           :
       elif [[ "$#" -lt 7 ]];then
           echo "You did not provide enough arguments"
           exit 1
       elif [[ "$#" -gt 7 ]];then
           echo "You provided to many arguments"
           exit 1
       fi
       for arg in "$@";
       do
        case "$arg" in
        -ip)
         check_if_ip_valid "$2"
         local ip="$2"
         ;;
        -b)
         check_if_bridge_Exists "$2"
         local br="$2"
         ;;
        -m)
         check_mask "$2"
         local mask="$2"
         ;;
         esac
         shift
        done
        #-d)
        #check_if_ip_valid "$2"
        #local dns="$2"
        #;;
        #-g)
        #check_if_ip_valid "$2"
        #local gw="$2"
        #
        if [[ "$ip" != "" ]] && [[ "$br" != "" ]] && [[ "$mask" != "" ]];then
            logger "net.sh|ADD-IP|INFO|Request to add ip $ip/$mask on bridge $br"
             add_ip "$br" "$ip/$mask"
             if [[ "$?" = 0 ]];then
                 check_if_Deb_or_RH
                 if [[ "$?" = 1 ]];then
                     create_bridge_with_ip_RH "$br" "$ip/$mask"
                     if [[ "$?" = 0 ]];then
                         logger "net.sh|ADD-IP|INFO|Created conf file ifcfg-$br with ip $ip and subnet $mask because is a RH based host"
                         return 0
                     else
                         logger "net.sh|ADD-IP|ERROR|Could not create conf file ifcfg-$br with ip $ip and subnet $mask"
                         return 1
                     fi
                 else
                     logger "net.sh|ADD-IP|INFO|Will not create configuration file,due to debian based host.User must create it by himself"
                     return 2
                 fi
             else
                 logger "net.sh|ADD-IP|ERROR|Could not add to $br ip $ip with subnet $mask"
                 echo "Could not add to $br ip $ip with subnet mask $mask"
                 return 1
             fi
             if [[ "$?" = 0 || "$?" = 2 ]];then
                 if_up "$br"
                 return "$?"
             fi
        elif
            [[ "$ip" = "" ]];then
                logger "net.sh|ADD-IP|ERROR|The user did not specify ip."
                echo "You have to provide a valid ip."
                exit 1
        elif
            [[ "$br" = "" ]];then
                logger "net.sh|ADD-IP|ERROR|The user did not specify bridge."
                echo "You have to provide a bridge to operate on"
                exit 1
        elif
            [[ "$mask" = "" ]];then
                logger "net.sh|ADD-IP|ERROR|The user did not specify a valid network mask."
                echo "You have to provide a valid network mask"
                exit 1
        fi
       ;;
  --del-ip|--dip)
       if [[ "$#" -eq 7 ]];then
           :
       elif [[ "$#" -lt 7 ]];then
           echo "You did not provide enough arguments"
           exit 1
       elif [[ "$#" -gt 7 ]];then
           echo "You provided to many arguments"
           exit 1
       fi
       for arg in "$@";
       do
        case "$arg" in
        -ip)
         check_if_ip_valid "$2"
         local ip="$2"
         ;;
        -b)
         check_if_bridge_Exists "$2"
         local br="$2"
         ;;
        -m)
         check_mask "$2"
         local mask="$2"
         ;;
        #-i)
        # check_if_port_exists "$2"
        # local int="$2"
        # ;;
         esac
         shift
        done
        if [[ "$ip" != "" ]] && [[ "$mask" != "" ]] && [[ "$br" != "" ]];then #|| [[ "$int" != "" ]];then
            logger "net.sh|ADD-IP|INFO|Request to delete ip $ip/$mask from $br" #$br
            del_ip "$br" "$ip/$mask"
            if [[ "$?" = 0 ]];then
                check_if_Deb_or_RH
                if [[ "$?" = 1 ]];then
                    del_inf_config_RH "$br"
                    if [[ "$?" = 0 ]];then
                        create_bridge_RH "$br"
                        if [[ "$?" = 0 ]];then
                            logger "net.sh|DEL-IP|INFO|Created configuration file ifcfg-$br with no ip configuration because is a RH based host"
                            return 0
                        else
                            logger "net.sh|DEL-IP|ERROR|Could not create configuration file for ifcfg-$br"
                            return 1
                        fi
                    else
                        logger "net.sh|DEL-IP|ERROR|Could not delete configuration file ifcfg-$br"
                        return 1
                    fi
                else
                    logger "net.sh|DEL-IP|INFO|Will not create configuration file,due to debian based host.User must create it by himself"
                    return 2
                fi
            else
                logger "net.sh|DEL-IP|ERROR|Could not remove ip $ip and subnet $mask from interface $br"
                return 1
            fi
        elif
            [[ "$ip" = "" ]];then
                logger "net.sh|DEL-IP|ERROR|The user did not specify ip."
                echo "You have to provide a valid ip."
                exit 1
        elif
            [[ "$br" = "" ]];then
                logger "net.sh|DEL-IP|ERROR|The user did not specify bridge."
                echo "You have to provide a bridge to operate on"
                exit 1
        elif
            [[ "$mask" = "" ]];then
                logger "net.sh|DEL-IP|ERROR|The user did not specify a valid network mask."
                echo "You have to provide a valid network mask"
                exit 1
        fi
        ;;
  --help|-h )
      help
      return 0
      ;;
  * )
      echo "unknown command $1 use --help for help"
      return 1
      ;;
    esac
    shift
done
}

main(){
#del_ip "$@"
#add_ip "$@"
#if_down $1
#if_up $1
#check_if_physical "$1"
#create_bridge_with_ip_RH $@
#create_bridge_RH $1
#$create_real_inf_port_to_bridge_RH $1 $2
#del_inf_config_RH "$1"
#check_if_ip_valid "$1"
#check_if_Deb_or_RH
#check_if_bridge_Exists "$1"
#check_if_port_exists "$1"
#check_vlan "$1"
pars "$@"
}
if [[ "$#" = 0 ]];then
    echo "No arguments provided.Use --help for help"
    exit 1
else
    main "$@"
fi