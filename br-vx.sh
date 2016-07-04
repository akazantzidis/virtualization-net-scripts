#!/usr/bin/env bash

#set -x
#set -v

log="/var/log/"
config="/etc/network/interfaces"
scriptname="$0"
exec > >(tee -i $log/$scriptname.log)
exec 2>&1

usage(){
echo "
 This is the help file of $scriptname.This script helps you configure your vlan/tunnel/bridge interfaces
 on an debian based host.
 It also let you attach the created interfaces on a bridge.You can pass multiple arguments in the script
 like: $scriptname -addbr br1 -delbr br2 etc.

 It was created with virtualization/sdn purpose in mind,but you can use it as you wish.


 HELP:

 -addbr [ NAME ] [ FLAGS ]

    FLAGS:
      -stp) on|off Enables/disables stp on the bridge
       -fd) VALUE  Sets fd value on the bridge

      Usage:Creates a bridge interface on the host and creates its entry to the configuration file to be persistent.

 -delbr [ NAME ]

      Usage:Deletes a bridge interface from the host and deletes its entry from configuration file.

 -addtun [ NAME ] [ FLAGS ]

    FLAGS:
      -id) Tunnel id
      -r)  Remote host
      -l)  Local host ip
      -t)  Tunnel type. Valid tunnel types:[vxlan]
      -i)  Local interface to initiate the tunnel

       Usage:Creates a tunnel interface and creates its entry to configuration file to be persistent.


 -deltun [ NAME ]

       Usage:Deletes a tunnel interface and deletes its entry from the configuration file.

 -addpb [ INTERFACE ] [BRIDGE ]

       Usage:Add an interface to a bridge.Updates also the configuration file for the change to be persistent.

 -delpb [ INTERFACE ] [BRIDGE ]

       Usage:Deletes an interface from a bridge.Updates also the configuration file for the change to be persistent.

 -addvl [ VLAN ID ] [ PHYSICAL INTERFACE ]

       Usage:Creates a vlan subinterface on a physical port.Creates an entry to the configuration file to be persistent.

 -delvl [ VLAN INTERFACE NAME ]

       Usage:Deletes a vlan subinterface from a physical port.Deletes the interface entry from the configuration file.

 -h
       Usage:Prints this help file.
"
}

function check_if_ip_valid(){
local ip_check="$1"
if [[ "$ip_check" =~ ^((1?[0-9]{1,2}|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9]{1,2}|2[0-4][0-9]|25[0-5])$ ]]; then
  return 0
else
  return 1
fi
}

function check_vlan(){
if [[ "$1" -ge 1 && "$1" -le 4094 ]];then
     local ret=0
fi
if [[ "$ret" = 0 ]];then
    return 0
else
    echo "The vlan $1 is not in the legit vlan range (1..4094)"
    return 1
fi
}

function check_vxkey(){
if [[ "$1" -ge 1 && "$1" -le 16777215 ]];then
     local ret=0
fi
if [[ "$ret" = 0 ]];then
    return 0
else
    echo "The vxlan key $1 is not in the legit vxlan range (1..16777215)"
    return 1
fi
}

#function check_grekey(){
#if [[ "$1" -ge 0 && "$1" -le 4294967295  ]];then
#     local ret=0
#fi
#if [[ "$ret" = 0 ]];then
#    return 0
#else
#    echo "The vxlan key $1 is not in the legit vxlan range (1..16777215)"
#    return 1
#fi
#}

check_link_up_down(){
echo ""
}

return_status(){
if [[ "$?" = 0 ]];then
    return 0
else
    return $?
fi
}

cp_config.new_config.pre(){
cp $config.new $config.pre
}

fix_config_file(){
echo -e "$(cat -s $config.new)" >$config
rm $config.new
}

fix_config_file_pre(){
echo -e "$(cat -s $config.pre)" >$config.new
rm $config.pre
}

item_items(){
local link="$1"
local items="$(cat $config.pre | grep -B1 -A 20 "iface $link inet")"

echo -e "$items" | while read -r line;do
	if [[ ! -z "$line" ]];then
	    echo -e "$line"
	else
	    break
	fi
done
}

delete_elem(){
local elem="$1"
local start="$(echo -n $(cat -n $config.pre | egrep -w "$(item_items $elem | head -n1 )" | awk '{print $1}') | sed 's/ //g')"
local c=0
OLFIFS="$IFS"
IFS=$'\n'
for item in $(item_items $elem);do
    if [[ ! $item == [^[:space:]] ]];then
	    c=$((c+1))
	else
	    break
    fi
    local line="$item"
    for i in {1..$c};do
        sed -i "${start}d" $config.pre
    done
done
IFS="$OLDIFS"
}

check-link-if-exists-in-config(){
local link="$1"
cat $config.pre | grep "iface $link inet" >/dev/null
return_status
}

check-link-if-exists(){
local link="$1"
ip link show | grep -w "$link" >/dev/null
return_status
}

check-bridge-if-exists(){
local bridge="$1"
brctl show | grep "$bridge">/dev/null
return_status
}

setup(){
if [[ "$1" = createbridge ]];then
    shift
	add-br "$@"
	return_status
elif [[ "$1" = deletebridge ]];then
    del-br "$2"
    return_status
elif [[ "$1" = createtunnel ]];then
    shift
    add-tun "$@"
    return_status
elif [[ "$1" = deletetunnel ]];then
    del-tun "$2"
    return_status
elif [[ "$1" = addporttobridge ]];then
    add-port-to-bridge "$2" "$3"
    return_status
elif [[ "$1" = deleteportfrombridge ]];then
    del-port-from-bridge "$2" "$3"
    return_status
elif [[ "$1" = addvlaninterface ]];then
    add-vlan "$2" "$3"
    return_status
elif [[ "$1" = deletevlaninterface ]];then
    del-vlan "$2"
    return_status
fi
}

set_up(){
ip link set dev "$1" up >/dev/null
return_status
}
set_down(){
ip link set dev "$1" down >/dev/null
return_status
}

add-br(){
cp_config.new_config.pre
local bridge="$1"
check-bridge-if-exists "$bridge"
if [[ "$?" = 0 ]];then
    echo "The bridge $bridge already exists"
    echo "Cancelling changes and exiting.."
    rm $config.pre >/dev/null
    return 1
elif [[ "$?" = 1 ]];then
    :
fi
if [[ "$2" = fd ]];then
	local fd="$3"
fi
if [[ "$2" = stp ]];then
	local stp="$3"
fi
if [[ "$2" = fd ]] && [[ "$4" = stp ]];then
	local fd="$3"
	local stp="$5"
fi

brctl addbr "$bridge" >/dev/null
if [[ ! "$fd" = "" ]];then
	brctl setfd "$bridge" "$fd" >/dev/null
	local setfd="bridge_fd $fd"
fi
if [[ ! "$stp" = "" ]];then
	brctl stp "$bridge" "$stp" >/dev/null
	local setstp="bridge_stp $stp"
fi

echo "
#
auto $bridge
iface $bridge inet manual
        bridge_ports
        $setfd
        $setstp
        pre-up ip link set dev \$IFACE up
        post-down ip link set dev \$IFACE down
#" | sed '/^\s*$/d' | sed 's/#//g' >> $config.pre
set_up "$bridge"
fix_config_file_pre
return 0
}

del-br(){
cp_config.new_config.pre
local bridge="$1"
check-bridge-if-exists "$bridge"
if [[ $? = 1 ]];then
	echo "The bridge $bridge does not exist."
	echo "Canceling changes and exiting.."
	rm $config.pre > /dev/null
	return 1
else
	:
fi
set_down "$bridge"
for i in $(bridge link show | grep -w "$bridge" | awk '{print $2}');do
	brctl delif "$bridge" "$i" >/dev/null
done
brctl delbr "$bridge" >/dev/null
delete_elem "$bridge"
fix_config_file_pre
return 0
}

add-tun(){
#$add_tun_name $tunnel_type $tunnel_id $remote_end $local_end $interface
cp_config.new_config.pre
local name="$1"
local type="$2"
local id="$3"
local remote="$4"
local local="$5"
local int="$6"
check_if_ip_valid "$remote"
if [[ "$?" = 0 ]];then
    :
else
    echo "Not valid ip provided in remote."
    echo "Canceling changes and exiting.."
    rm $config.pre > /dev/null
    return 1
fi

check_if_ip_valid "$local"
if [[ "$?" = 0 ]];then
    :
else
    echo "Not valid ip provided in local."
    echo "Canceling changes and exiting.."
    rm $config.pre > /dev/null
    return 1
fi

#if [[ "$type" = gretap ]];then
#    name="$id"
#    check-tun-if-exists "$name" "$id" "$remote" "$type"
#    echo "
#
#auto $name
#iface $name inet manual
#       pre-up ip link add $name type gretap local $local remote $remote dev $int
#       post-up ip link set dev \$IFACE up
#       pre-down ip link set dev \$IFACE down
#" | sed '/^\s*$/d' | sed 's/#//g' >> $config.pre
#    ip link add "$name" mode gretap local "$local" remote "$remote" dev $int 2>/dev/null
#    set_up "$name"
#    fix_config_file_pre
#    return 0
if [[ "$type" = vxlan ]];then
   check-tun-if-exists "$name" "$id" "$remote" "$type"
   if [[ "$?" = 1 ]];then
       rm $config.pre > /dev/null
       return 1
   fi
   echo "
#
auto $name
iface $name inet manual
       pre-up ip link add $name type vxlan id $id remote $remote local $local dev $int
       post-up ip link set dev \$IFACE up
       pre-down ip link set dev \$IFACE down
#" | sed '/^\s*$/d' | sed 's/#//g' >> $config.pre
    ip link add "$name" type vxlan id "$id" remote "$remote" local "$local" dev "$int" 2>/dev/null
    set_up "$name"
    fix_config_file_pre
    return 0
fi
}

check-link-if-is-physical(){
local if="$1"
declare phys=($(lshw -c network | egrep "name|capabilities" | grep -B1 "cap_list" | awk '{print $3}' | awk NR%2))
for i in "${phys[@]}";do
    if [[ "$i" = $if ]];then
         return 0
    fi
done
return 1
}

check-link-if-exists-in-a-bridge(){
local link="$1"
bridge link show | grep $link >/dev/null
return_status
}

del-tun(){
local tuninf="$1"
cp_config.new_config.pre
check-link-if-exists "$1"
if [[ "$?" = 1 ]];then
	echo "The tunnel interface $tuninf does not exist"
	echo "Canceling changes and exiting.."
	rm $config.pre > /dev/null
	return 1
else
	:
fi
set_down "$tuninf"
check-link-if-exists-in-a-bridge "$tuninf"
local var="$?"
if [[ "$var" = 1 ]];then
    ip link del dev "$tuninf" >/dev/null
    delete_elem "$tuninf" >/dev/null
elif [[ "$var" = 0 ]];then
    local bridgeofinf="$(bridge link show | grep $tuninf | awk '{print $10}')"
    del-port-from-bridge "$tuninf" "$bridgeofinf"
    cp_config.new_config.pre
    delete_elem "$tuninf"
    ip link del dev "$tuninf" >/dev/null
fi
fix_config_file_pre
return 0
}

add-port-to-bridge(){
cp_config.new_config.pre
local addport="$1"
local tobridge="$2"

check-bridge-if-exists "$tobridge"
if [[ "$?" = 0 ]];then
    :
else
    echo "Bridge $tobridge does not exist."
    echo "Canceling changes and exiting.."
    rm $config.pre
    return 1
fi

check-link-if-exists "$addport"
if [[ "$?" = 0 ]];then
    :
else
    echo "Interface $addport does not exist."
    echo "Canceling changes and exiting.."
    rm $config.pre
    return 1
fi

check-link-if-exists-in-a-bridge "$addport"
if [[ "$?" = 1 ]];then
    :
else
    echo "The interface $addport is already attached to another bridge."
    echo "Canceling changes and exiting.."
    rm $config.pre
    return 1
fi

local line="$(cat -n $config.pre | egrep "iface $tobridge inet|bridge_ports" | egrep -A1 "iface $tobridge inet" | tail -n1 | awk '{print $1}' |sed 's/ //g')"
local ed_bit="$(item_items "$tobridge" | egrep "bridge_ports")"


local var="$(echo "$ed_bit" "$addport")"
sed -i "${line}s/$ed_bit/$var/g" $config.pre
brctl addif "$tobridge" "$addport" >/dev/null
set_up "$addport"
set_up "$tobridge"
fix_config_file_pre
return 0
}

del-port-from-bridge(){
cp_config.new_config.pre
local delport="$1"
local frombridge="$2"
check-bridge-if-exists "$frombridge"
if [[ "$?" = 0 ]];then
    :
else
    echo "Bridge $frombridge does not exist."
    echo "Canceling changes and exiting.."
    rm $config.pre
    return 1
fi
check-link-if-exists "$delport"
if [[ "$?" = 0 ]];then
    :
else
    echo "Interface $delport does not exist."
    echo "Canceling changes and exiting.."
    rm $config.pre
    return 1
fi
bridge link | grep "$delport" | grep "$frombridge" 2>/dev/null
if [[ "$?" = 0 ]];then
    :
else
    echo "Interface $delport does not exist on bridge $frombridge."
    echo "Canceling changes and exiting.."
    rm $config.pre
    return 1
fi

local line="$(cat -n $config.pre | egrep "iface $frombridge inet|bridge_ports" | egrep -A1 "iface $frombridge inet" | tail -n1 | awk '{print $1}' |sed 's/ //g')"
local ed_bit="$(item_items "$frombridge" | egrep "bridge_ports")"
local var="$(echo "$ed_bit" | sed "s/ $delport//g")"
sed -i "${line}s/$ed_bit/$var/g" $config.pre
fix_config_file_pre
set_down "$delport"
brctl delif "$frombridge" "$delport" >/dev/null
return 0
}

add-vlan(){
cp_config.new_config.pre
local vlanif="$2"
local vlanid="$1"
check_vlan "$vlanid"
if [[ "$?" = 0 ]];then
    :
else
     echo "Canceling changes.."
     rm $config.pre >/dev/null
    return 1
fi

check-link-if-exists "$vlanif"
if [[ "$?" = 0 ]];then
    :
else
    echo "Interface $vlanif does not exist."
    echo "Canceling changes and exiting.."
    rm $config.pre
    return 1
fi
check-link-if-is-physical "$vlanif"
if [[ "$?" = 0 ]];then
    :
else
    echo "Interface $vlanif is not physical interface."
    echo "Canceling changes and exiting.."
    rm $config.pre
    return 1
fi

echo "
#
auto "$vlanif.$vlanid"
iface "$vlanif.$vlanid" inet manual
        post-up ip link set dev \$IFACE up
        pre-down ip link set dev \$IFACE down
#" | sed '/^\s*$/d' | sed 's/#//g' >> $config.pre
ip link add link $vlanif name $vlanif.$vlanid type vlan id $vlanid >/dev/null
set_up "$vlanif.$vlanid"
fix_config_file_pre
return 0
}

del-vlan(){
cp_config.new_config.pre
local dvlif="$1"
check-link-if-exists "$dvlif"
if [[ "$?" = 0 ]];then
    :
else
    echo "Interface $dvlif does not exist."
    echo "Cancel changes and exiting.."
    rm $config.pre
    return 1
fi
check-link-if-exists-in-a-bridge "$dvlif"
if [[ "$?" = 1 ]];then
    set_down "$dvlif"
    ip link del dev "$dvlif" >/dev/null
    delete_elem "$dvlif" >/dev/null
else
    local bridgeofdvlif="$(bridge link show | grep $dvlif | awk '{print $10}')"
    del-port-from-bridge "$bridgeofdvlif" "$dvlif"
    delete_elem "$dvlif"
fi
fix_config_file_pre
return 0
}

#check_number_arg(){
#argmusthave="$1"
#arghas="$2"
#into="in $3"
#if [[ $arghas -eq $argmusthave ]];then
#	:
#elif [[ $arghas -lt $argmusthave ]];then
#	echo "Too few arguments provided $into"
#	usage
#	exit 1
#elif [[ $arghas -gt $argmusthave ]];then
#	echo "Too many arguments provided $into"
#	usage
#	exit 1
#fi
#}

check-tun-if-exists(){
local type="$4"
if [[ "$type" = vxlan ]];then
    local tun="$1"
    local tid="$2"
    local remote="$3"
    for i in $(ip -d link show | egrep vxlan | awk -F: '{print $2}');do
        #local name_to_check="$(ip -d link show $tun | awk -F: '{print $2}' | head -n1)"
        local id_to_check="$(ip -d link show $i | egrep "vxlan id" | awk '{print $3}')"
        local remote_to_check="$(ip -d link show $i | egrep "vxlan id $id_to_check" | awk '{print $5}')"
        if [[ "$i" = $tun ]];then
            echo "A vxlan interface with name $tun already exists."
            return 1
        fi
        if [[ "$remote" = $remote_to_check ]] && [[ "$tid" = $id_to_check ]];then
           echo "A vxlan tunnel to remote host $remote with id $tid already exists with name $i."
           return 1
        fi
    done
else
    :
fi
#if [[ "$type" = gretap ]];then
#    local gtun="$1"
#    local gtid="$2"
#    local gremote="$3"
#    for j in $(ip -d link show | egrep gre | awk -F: '{print $2}' | awk -F@ '{print $1}');do
#        local gid_to_check="$(ip -d link show $j | egrep "okey" | awk -Fokey '{print $2}' | awk -F. '{print $4}' | sed 's/ //g')"
#        local gremote_to_check="$(ip -d link show $j | egrep "gre remote" | awk '{print $3}')"
#        if [[ "$j" = $gtun ]];then
#            echo "A gre interface with name $gtun already exists."
#            return 1
#        elif [[ "$gremote" = $gremote_to_check ]] && [[ "$gtid" = $gid_to_check ]];then
#            echo "A gre tunnel to remote host $gremote with id $gtid already exists with name $j."
#            return 1
#        fi
#    done
#else
#    :
#fi
return 0
}

main(){
if [[ $EUID -ne 0 ]]; then
   echo "
This script must be run as root." 1>&2
   echo "Exiting.."
   sleep 1
   exit 1
fi

#modprobe ip_gre
#if [[ "$?" = 0 ]];then
#    :
#else
#    "Could not probe the gre module in kernel.Check your system."
#    exit 1
#fi

modprobe vxlan
if [[ "$?" = 0 ]];then
    :
else
    "Could not probe the vxlan module in kernel.Check your system."
    exit 1
fi

if [[ "$@" = "" ]];then
    echo -e "You didn't tell me what you want me to do.\nTry $0 -h for configuration options."
    exit 1
fi

if [[ "$#" = 1 ]] && [[ "$1" = -h ]];then
    usage
    exit 1
fi

cp $config $config.new
local add_tun=""
local addbridge=""
local delbridge=""
local del_tun=""
local addport_to_bridge=""
local deleteport_from_bridge=""
local addvlan=""
local delvlan=""

while [[ "$#" -gt 0 ]];
do
    case "$1" in
   -addbr)
       local setfd=""
       local setstp=""
	   addbridge=createbridge
	   abridge="$2"
	   if [[ "$addbridge" =~ ^[-$] ]];then
	       echo -e "\nYou may not provide an argument for $1 or the argument starts with \"-\" which is not permitted.\nPlease check your input."
	       echo "Exiting.."
	       sleep 1
	       break
	   fi
	   shift 2
	   while [[ "$#" -gt 0 ]];
       do
	     case "$1" in
	       -fd)
	            setfd=fd
	            local fdval="$2";;
	      -stp)
	            local setstp=stp
	            if [[ "$2" = off ]];then
		           local stpval="off"
                elif [[ "$2" = on ]];then
		           local stpval="on"
		        fi;;
		   *)
		        break;;
	     esac;
	     shift 2
	   done;
	   if [[ "$addbridge" = createbridge ]] && [[ ! "$abridge" = "" ]];then
           setup $addbridge $abridge $setfd $fdval $setstp $stpval
           if [[ "$?" = 1 ]];then
	           fix_config_file
	           exit 1
           else
               :
           fi
       fi;;
   -delbr)
	   delbridge=deletebridge
	   dbridge="$2"
	   if [[ "$dbridge" =~ ^[-$] ]];then
	       echo -e "\nYou may not provide an argument for $1 or the argument starts with \"-\" which is not permitted.\nPlease check your input."
	       echo "Exiting.."
	       sleep 1
	       break
	   fi
	   if [[ "$delbridge" = deletebridge ]] && [[ ! "$dbridge" = "" ]];then
           setup $delbridge $dbridge
           if [[ "$?" = 1 ]];then
               fix_config_file
	           exit 1
           else
               shift 2
               :
           fi
       else
               echo "Check your input"
               break
       fi;;
  -addtun)
       add_tun=createtunnel
       add_tun_name="$2"
       if [[ "$add_tun_name" =~ ^[-$] ]];then
	       echo -e "\nYou may not provide an argument for $1 or the argument starts with \"-\" which is not permitted.\nPlease check your input."
	       echo "Exiting.."
	       sleep 1
	       break
	   fi
       shift 2
       while [[ "$#" -gt 0 ]];do
           case "$1" in
            -i)
	           local interface="$2"
	           if [[ "$interface" =~ ^[-$] ]];then
	               echo -e "\nYou may not provide an argument for $1 or the argument starts with \"-\" which is not permitted.\nPlease check your input."
	               echo "Exiting.."
	               sleep 1
	               break
               fi;;
	        -t)
               local tunnel_type="$2"
	           if [[ "$tunnel_type" =~ ^[-$] ]];then
	               echo -e "\nYou may not provide an argument for $1 or the argument starts with \"-\" which is not permitted.\nPlease check your input."
	               echo "Exiting.."
	               sleep 1
	               break
               fi;;
           -id)
	           local tunnel_id="$2"
	           if [[ "$tunnel_id" =~ ^[-$] ]];then
	               echo -e "\nYou may provide an argument for $1 which starts with \"-\" which is not permitted.\nPlease check your input."
	               echo "Exiting.."
	               sleep 1
	               break
               fi;;
	        -r)
	           local remote_end="$2"
	           if [[ "$remote_end" =~ ^[-$] ]];then
	               echo -e "\nYou may not provide an argument for $1 or the argument starts with \"-\" which is not permitted.\nPlease check your input."
	               echo "Exiting.."
	               sleep 1
	               break
               fi;;
            -l)
	           local local_end="$2"
	           if [[ "$local_end" =~ ^[-$] ]];then
	               echo -e "\nYou may not provide an argument for $1 or the argument starts with \"-\" which is not permitted.\nPlease check your input."
	               echo "Exiting.."
	               sleep 1
	               break
               fi;;
	         *)
	           break;;
	       esac;
	       shift 2;
	   done;
       #shift
	   if [[ "$add_tun" = createtunnel ]] && [[ ! "$add_tun_name" = "" ]] && [[ ! "$tunnel_type" = "" ]] && [[ ! "$tunnel_id" = "" ]] && [[ ! "$remote_end" = "" ]] && [[ ! "$local_end" = "" ]] && [[ ! "$interface" = "" ]];then
	       #if [[ "$tunnel_type" = gre ]];then
	       #    setup $add_tun gre-$add_tun_name gretap $remote_end $local_end $interface
           #    if [[ "$?" = 1 ]];then
	       #       fix_config_file
	       #       exit 1
           #    else
           #       #fix_config_file
           #       :
           #    fi
           #elif [[ "$tunnel_type" = vxlan ]];then
               setup $add_tun $add_tun_name $tunnel_type $tunnel_id $remote_end $local_end $interface
               if [[ "$?" = 1 ]];then
	               fix_config_file
	               exit 1
               else
                   #fix_config_file
                   :
               fi
           #fi
       else
           echo "Not enough parameters provided"
           break
       fi;;
  -deltun)
	       del_tun=deletetunnel
	       del_tun_name="$2"
	       if [[ "$del_tun_name" =~ ^[-$] ]];then
	           echo -e "\nYou may not provide an argument for $1 or the argument starts with \"-\" which is not permitted.\nPlease check your input."
	           echo "Exiting.."
	           sleep 1
	           break
	       fi
	       if [[ "$del_tun" = deletetunnel ]] &&  [[ ! "$del_tun_name" = "" ]];then
           setup $del_tun $del_tun_name
               if [[ "$?" = 1 ]];then
                   fix_config_file
                   exit 1
               else
                   shift 2
                   :
               fi
           fi;;
   -addpb)
	       addport_to_bridge=addporttobridge
           local if="$2"
           if [[ "$if" =~ ^[-$] ]];then
	           echo -e "\nYou may not provide an argument for $1 or the argument starts with \"-\" which is not permitted.\nPlease check your input."
	           echo "Exiting.."
	           sleep 1
	           break
	       fi
	       local br="$3"
	       if [[ "$br" =~ ^[-$] ]];then
	           echo -e "\nYou may not provide an argument for $1 or the argument starts with \"-\" which is not permitted.\nPlease check your input."
	           echo "Exiting.."
	           sleep 1
	           break
	       fi
	       if [[ "$addport_to_bridge" = addporttobridge ]] && [[ ! "$if" =  "" ]] && [[ ! "$br" = "" ]];then
               setup $addport_to_bridge $if $br
               if [[ "$?" = 1 ]];then
                   fix_config_file
	               exit 1
               else
                   shift 3
                   :
               fi
           fi;;
   -delpb)
	       deleteport_from_bridge=deleteportfrombridge
           local dif="$2"
           if [[ "$dif" =~ ^[-$] ]];then
	           echo -e "\nYou may not provide an argument for $1 or the argument starts with \"-\" which is not permitted.\nPlease check your input."
	           echo "Exiting.."
	           sleep 1
	           break
	       fi
	       local dbr="$3"
	       if [[ "$dbr" =~ ^[-$] ]];then
	           echo -e "\nYou may not provide an argument for $1 or the argument starts with \"-\" which is not permitted.\nPlease check your input."
	           echo "Exiting.."
	           sleep 1
	           break
	       fi
	       if [[ "$deleteport_from_bridge" = deleteportfrombridge ]] && [[ ! "$dif" = "" ]] && [[ ! "$dbr" = "" ]];then
               setup $deleteport_from_bridge $dif $dbr
               if [[ "$?" = 1 ]];then
                   fix_config_file
	               exit 1
               else
                   shift 3
                   :
               fi
           fi;;
   -addvl)
	       addvlan=addvlaninterface
	       vlan_id="$2"
	       if [[ "$vlan_id" =~ ^[-$] ]];then
	           echo -e "\nYou may not provide an argument for $1 or the argument starts with \"-\" which is not permitted.\nPlease check your input."
	           echo "Exiting.."
	           sleep 1
	           break
	       fi
	       vlan_inf="$3"
	       if [[ "$vlan_inf" =~ ^[-$] ]];then
	           echo -e "\nYou may not provide an argument for $1 or the argument starts with \"-\" which is not permitted.\nPlease check your input."
	           echo "Exiting.."
	           sleep 1
	           break
	       fi
	       if [[ "$addvlan" = addvlaninterface ]] && [[ ! "$vlan_id" = "" ]] && [[ ! "$vlan_inf" = "" ]];then
               setup $addvlan $vlan_id $vlan_inf
               if [[ "$?" = 1 ]];then
                   fix_config_file
	               exit 1
               else
                   shift 3
                   :
               fi
           fi;;
   -delvl)
	       delvlan=deletevlaninterface
	       dvl_if="$2"
	       if [[ "$dvl_if" =~ ^[-$] ]];then
	           echo -e "\nYou may not provide an argument for $1 or the argument starts with \"-\" which is not permitted.\nPlease check your input."
	           echo "Exiting.."
	           sleep 1
	           break
	       fi
	       if [[ "$delvlan" = deletevlaninterface ]] && [[ ! "$dvl_if" = "" ]];then
               setup $delvlan $dvl_if
               if [[ "$?" = 1 ]];then
	               fix_config_file
	               exit 1
               else
                   shift 2
                   :
               fi
           fi;;
        *) # unknown flag
	       echo "Unknown option $1"
	       fix_config_file
	       exit 1;;
    esac
done
fix_config_file
}

main "$@"
