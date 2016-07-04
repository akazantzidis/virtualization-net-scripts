#!/bin/bash
#set -e
set -x
config="interfaces"
cp $config $config.new

function check_if_br_has_ports(){
bridge="$1"
have_ports="$(echo $(cat $config.new | egrep "allow-ovs $bridge|ovs_type OVSBridge|ovs_ports" | head -n+3 | tail -n1))"

if [[ "$have_ports" = "ovs_ports"* ]];then
    ports="$(echo "$have_ports" | sed 's/ovs_ports//g')"
    echo "$ports"
else
    echo ""
fi
}

function create_Br_Deb(){
local set_ports="$1"
local bridge="$2"
local ip="$3"
local mask="$4"
local gate="$5"
local dns="$6"
if [[ "$set_ports" = y ]];then
    has_ports="ovs_ports"
elif
   [[ "$set_ports" = n ]];then
    has_ports=""
else
    exit 1
fi

function dhcp(){
echo "
#
allow-ovs $1
auto $1
iface $1 inet dhcp
    ovs_type OVSBridge
    $has_ports
" | sed '/^\s*$/d' | sed 's/#//g' >>$config.new
}
function static_manual(){
echo "
#
allow-ovs $1
auto $1
iface $1 inet $2
    $ipset
    ovs_type OVSBridge
    $has_ports
" | sed '/^\s*$/d' | sed 's/#//g' >>$config.new
}

if [[ "$ip" = "" && "$mask" = "" && "$gate" = ""  && "$dns" = "" ]];then
    unset ipset
    static_manual "$bridge" manual
elif [[ "$ip" != "" && "$mask" != "" && "$gate" = ""  && "$dns" = "" ]];then
    local ipset="$(echo "address $ip
    netmask $mask")"
    static_manual "$bridge" static
elif [[ "$ip" != "" && "$mask" != "" && "$gate" != ""  || "$dns" != "" ]];then
    local ipset="$(echo "address $ip
    netmask $mask
    gateway $gate
    dns-nameservers $dns")"
    static_manual "$bridge" static
elif [[ "$ip" = dhcp && "$mask" = "" && "$gate" = ""  || "$dns" = "" ]];then
    dhcp "$bridge"
else
    exit 1
fi
}

function create_port(){

function magic(){
typeofport="$1"

function ipset(){
local ip="$1"
local mask="$2"
local gate="$3"
local dns="$4"

if [[ "$ip" = "" && "$mask" = "" && "$gate" = ""  && "$dns" = "" ]];then
    unset ipset
    #static_manual "$bridge" manual
elif [[ "$ip" != "" && "$mask" != "" && "$gate" = ""  && "$dns" = "" ]];then
    ipset="$(echo "address $ip
    netmask $mask")"
    #static_manual "$bridge" static
elif [[ "$ip" != "" && "$mask" != "" && "$gate" != ""  || "$dns" != "" ]];then
    ipset="$(echo "address $ip
    netmask $mask
    gateway $gate
    dns-nameservers $dns")"
fi
}

function ovstype(){
local type="$1"
ovs_type="$(echo "ovs_type $type")"
}

function ovsbond(){
local bond="$1"
ovs_bond="$(echo "ovs_bonds $bond")"
}

function ovsoptions(){
local options="$1"
ovs_options="$(echo ""ovs_options" $options")"
}

function ovstunneloptions(){
local ip="$1"
local key="$2"
ovs_tunnel_options="$(echo "ovs_tunnel_options options:remote_ip="$ip" options:key="$key"")"
}

function ovstunneltype(){
local tunneltype="$1"
ovs_tunnel_type="$(echo "ovs_tunnel_type $tunneltype")"
}

function ovspatchpeer(){
local peer="$1"
ovs_patch_peer="$(echo "ovs_patch_peer $peer")"
}

function make_config(){
echo "
#
allow-$bridge $portname
iface $portname inet $type
    ovs_bridge $bridge
    $ipset
    $ovs_type
    $ovs_tunnel_type
    $ovs_tunnel_options
    $ovs_patch_peer
    $ovs_bond
    $ovs_options
#" | sed '/^\s*$/d' | sed 's/#//g' >> $config.new
}

if [[ "$typeofport" = bondport ]];then
     local bridge="$2"
     local type=manual
     local portname="$3"
     local bond="$4"
     local options="$5"
     for i in {1..5};do
         shift
     done
     ovsoptions "$options"
     ovstype "OVSBond"
     ovsbond "$bond"
     make_config
elif [[ "$typeofport" = bridgeport ]];then
     local bridge="$2"
     local type=manual
     local portname="$3"
     for i in {1..3};do
         shift
     done
     if [[ "$1" = "--options" ]];then
         shift
         local options="$@"
         ovsoptions "$options"
     else
         unset ovs_options
     fi
     ovstype "OVSPort"
     make_config
elif [[ "$typeofport" = internalport ]];then
     if [[ "$2" = "--dhcp" ]];then
         local type=dhcp
         local bridge="$3"
         local portname="$4"
         local vlan="$5"
         for i in {1..5};do
             shift
         done
         if [[ "$1" = "--options" ]];then
             shift
             local options="$@"
             ovsoptions "tag=$vlan $options"
         else
             ovsoptions "tag=$vlan"
         fi
         ovstype "OVSIntPort"
         make_config
     elif [[ "$2" = "--manual" ]];then
         local type=manual
         local bridge="$3"
         local portname="$4"
         local vlan="$5"
         for i in {1..5};do
                shift
            done
         if [[ "$1" = "--options" ]];then
             shift
             local options="$@"
             ovsoptions "tag=$vlan $options"
         else
             ovsoptions "tag=$vlan"
         fi
         ovstype "OVSIntPort"
         make_config
     elif [[ "$2" = "--static" ]];then
         local type=static
         local bridge="$3"
         local portname="$4"
         local vlan="$5"
         local ip="$6"
         local mask="$7"
         local gate="$8"
         local dns="$9"
         if [[ "$8" = "--options" ]];then
            unset gate
            unset dns
            for i in {1..8};do
                shift
            done
            local options="$@"
            ovsoptions "tag=$vlan $options"
         elif [[ "$9" = "--options" ]];then
            unset dns
            for i in {1..9};do
                shift
            done
            local options="$@"
            ovsoptions "tag=$vlan $options"
         elif [[ "$10" = "--options" ]];then
            for i in {1..10};do
                shift
            done
            local options="$@"
            ovsoptions "tag=$vlan $options"
         else
            ovsoptions "tag=$vlan"
         fi
         ipset "$ip" "$mask" "$gate" "$dns"
         ovstype "OVSIntPort"
         make_config
     fi
elif [[ "$typeofport" = tunnelport ]];then
     local bridge="$2"
     local portname="$3"
     local tunneltype="$4"
     local remoteip="$5"
     local key="$6"
     if [[ "$7" = "--options" ]];then
         for i in {1..7};do
                shift
         done
         local options="$@"
         ovsoptions "$options"
     else
         unset ovs_options
     fi
     local type=manual
     ovstunneloptions "$remoteip" "$key"
     ovstunneltype "$tunneltype"
     ovstype "OVSTunnel"
     make_config
elif [[ "$typeofport" = patchport ]];then
     local bridge1="$2"
     local bridge2="$3"
     local bridge1patch="$4"
     local bridge2patch="$5"
     if [[ "$6" = "--options" ]];then
         for i in {1..6};do
                shift
         done
         local options="$@"
         ovsoptions "$options"
     else
         unset ovs_options
     fi
     local type=manual
     #PATCH PORT 1
     local bridge="$bridge1"
     local portname="$bridge1patch"
     ovspatchpeer "$bridge2patch"
     ovstype "OVSPatchPort"
     make_config
     #PATCH PORT 2
     local bridge="$bridge2"
     local portname="$bridge2patch"
     ovspatchpeer "$bridge1patch"
     ovstype "OVSPatchPort"
     make_config
fi
}

porttype="$1"
    if [[ "$porttype" = "--bridge" ]];then
        shift
        magic bridgeport $@
        #
    elif [[ "$porttype" = "--internal" ]];then
        shift
        magic internalport "$@"
        #exit 0
    elif [[ "$porttype" = "--tunnel" ]];then
        shift
        magic tunnelport "$@"
        #exit 0
    elif [[ "$porttype" = "--patch" ]];then
        shift
        magic patchport "$@"
        #exit 0
     elif [[ "$porttype" = "--bond" ]];then
        shift
        magic bondport "$@"
        #exit 0
    else
        exit 1
    fi
}

function item_items(){
for arg in "$@";
do
case "$arg" in
 port)
     local port="$2"
     ;;
 bridge)
     local bridge="$2"
     ;;
     esac
     shift
done
if [[ "$port" != "" && "$bridge" != "" ]];then
    local items="$(cat $config.new | grep -A 100 "allow-$bridge $port")"
elif [[ "$bridge" != "" && "$port" = "" ]];then
    local items="$(cat $config.new | grep -A 100 "allow-ovs $bridge")"
elif [[ "$bridge" = "" && "$port" != "" ]];then
    local items="$(cat $config.new | grep -B1 -A 100 "iface $port")"
else [[ "$bridge" != "" && "$port" = "" ]];
        exit 1
fi
echo -e "$items" | while read -r line;do
	if [[ ! -z "$line" ]];then
	    echo -e "$line"
	else
	    break
	fi
done
}

function delete_elem(){
for arg in "$@";
do
  case "$arg" in
  port-only)
        if [[ "$#" -eq 2 ]];then
        local port="$2"
        local start="$(cat -n $config.new | grep "$(item_items port $port | head -n1 )" | awk '{print $1}')"
        local c=0
        OLFIFS="$IFS"
        IFS=$'\n'
        for item in $(item_items port $port);do
	        if [[ ! $item == [^[:space:]] ]];then
	            c=$((c+1))
	        else
	            break
            fi
            local line="$item"
            for i in {1..$c};do
                #echo "Now i am deleting line:$line "
                sed -i "${start}d" $config.new
            done
        done
        fi
        IFS="$OLDIFS"
        ;;
  port)
        if [[ "$#" -eq 3 ]];then
        local port="$3"
        local bridge="$2"
        local start="$(cat -n $config.new | grep "$(item_items port $port bridge $bridge | head -n1)" | awk '{print $1}')"
        local c=0
        OLFIFS="$IFS"
        IFS=$'\n'
        for item in $(item_items port $port bridge $bridge);do
	        if [[ ! $item == [^[:space:]] ]];then
	            c=$((c+1))
	        else
	            break
            fi
            local line="$item"
            for i in {1..$c};do
                #echo "Now i am deleting line:$line "
                sed -i "${start}d" $config.new
            done
        done
        fi
        IFS="$OLDIFS"
        ;;
  bridge)
        if [[ "$#" -eq 2 ]];then
        local bridge="$2"
        local start="$(cat -n $config.new | grep "$(item_items bridge $bridge | head -n1 )" | awk '{print $1}')"
        local c=0
        OLFIFS="$IFS"
        IFS=$'\n'
        for item in $(item_items bridge $bridge);do
	        if [[ ! $item == [^[:space:]] ]];then
	            c=$((c+1))
	        else
	            break
            fi
            local line="$item"
            for i in {1..$c};do
                #echo "Now i am deleting line: $line "
                sed -i "${start}d" $config.new
            done
        done
        fi
        IFS="$OLDIFS"
        ;;
        esac
done
}

function fix_config_file(){
echo -e "$(cat -s $config.new)" >$config
}

function add_delete_port_bridge(){
for arg in "$@";
do
 case "$arg" in
  add-br)
      for arg in "$@";
      do
       case "$arg" in
          --static)
              local bridge="$3"
              local ip="$4"
              local mask="$5"
              local gate="$6"
              local dns="$7"
              local ports="$8"
              if [[ "$ports" = "--standalone" ]];then
                  create_Br_Deb n "$bridge" "$ip" "$mask" "$gate" "$dns"
                  fix_config_file
              elif [[ "$ports" = "--withports" ]];then
                  create_Br_Deb y "$bridge" "$ip" "$mask" "$gate" "$dns"
                  fix_config_file
              fi
              ;;
          --manual)
              local bridge="$3"
              local ports="$4"
              if [[ "$ports" = "--standalone" ]];then
                  create_Br_Deb n "$bridge"
                  fix_config_file
              elif [[ "$ports" = "--withports" ]];then
                  create_Br_Deb y "$bridge"
                  fix_config_file
              fi
              ;;
          --dhcp)
              local bridge="$3"
              local ports="$4"
              if [[ "$ports" = "--standalone" ]];then
                  create_Br_Deb n "$bridge" dhcp
                  fix_config_file
              elif [[ "$ports" = "--withports" ]];then
                  create_Br_Deb y "$bridge" dhcp
                  fix_config_file
              fi
              ;;
              esac
      done
      ;;
  del-br)
      local bridge="$2"
      local ports="$(item_items bridge $bridge | egrep "ovs_ports" | sed 's/ovs_ports//g')"
      if [[ "$ports" != "" ]];then
          for i in $ports;do
              delete_elem port "$bridge" "$i"
          done
      fi
      delete_elem bridge "$bridge"
      fix_config_file
      ;;
  add-port)
      local line=""
      local var=""
      local ed_bit=""
      local line=""
      local addport=""
      local addbridge=""
      if [[ "$2" = port ]];then
          addport="$4"
          addbridge="$3"
          line="$(cat -n $config.new | egrep "$addbridge|$(item_items bridge $addbridge)" | egrep "iface $addbridge inet|ovs_ports" | egrep -A1 "iface $addbridge inet" | tail -n1 | awk '{print $1}' |sed 's/ //g')"
          ed_bit="$(item_items bridge $addbridge | tail -n1 | egrep "ovs_ports")"
          var="$(echo "$ed_bit $addport")"
          sed -i "${line}s/$ed_bit/$var/g" $config.new
          fix_config_file
      elif [[ "$2" = cport ]];then
          addport="$4"
          addbridge="$3"
          line="$(cat -n $config.new | egrep "$addbridge|$(item_items bridge $addbridge)" | egrep "iface $addbridge inet|ovs_ports" | egrep -A1 "iface $addbridge inet" | tail -n1 | awk '{print $1}' | sed 's/ //g')"
          ed_bit="$(item_items bridge $addbridge | tail -n1 | egrep "ovs_ports")"
          var="$(echo "$ed_bit $addport")"
          sed -i "${line}s/$ed_bit/$var/g" $config.new
          create_port --bridge "$addbridge" "$addport"
          fix_config_file
      elif [[ "$2" = vlan ]];then
          local netype="$3"
          local nameport="$5"
          local bridge="$4"
          local vlan="$6"
          local ip="$7"
          local mask="$8"
          local gate="$9"
          local dns="$10"
          if [[ "$netype" = --ip ]];then
              create_port --internal --static "$bridge" "$nameport" "$vlan" "$ip" "$mask" "$gate" "$dns"
              add_delete_port_bridge add-port port "$bridge" "$nameport"
              fix_config_file
              return 0
          elif [[ "$netype" = --dhcp ]];then
              create_port --internal --dhcp "$bridge" "$nameport" "$vlan"
              add_delete_port_bridge add-port port "$bridge" "$nameport"
              fix_config_file
              return 0
          elif [[ "$netype" = --manual ]];then
              create_port --internal --manual "$bridge" "$nameport" "$vlan"
              add_delete_port_bridge add-port port "$bridge" "$nameport"
              fix_config_file
              return 0
           else
              echo "You must provide network type --ip/--dhcp/--manual"
              exit 1
           fi
      elif [[ "$2" = bond ]];then
          local bondname="$4"
          local bondbridge="$3"
          local bondoptions="$5"
          if [[ "$bondoptions" = "" ]];then
              echo "You must specify bond options"
              exit 1
          fi
          bondinfs=""
          echo "Now you will configure the bond"
          echo "If you dont want to add any more interfaces then input exit to the prompt"
          for i in {1..5};do
              shift
          done
          while [[ "$#" -gt 0 ]];do
              for arg in "$@";do
                  case $arg in
                    -t)
                     local inf="$2"
                     bondinfs=""$bondinfs" "$inf""
                     ;;
                  esac
                  shift
              done
          done
          c=0
          for i in $bondinfs;do
              local c=$((c+1))
          done
          if [[ "$c" -eq 1 ]];then
              echo "You cannot bond only one interface.exiting.."
              exit 1
          elif [[ "$c" -eq 0 ]];then
              echo "You must specify an interface to bond.exiting.."
              exit 1
          else
              :
          fi
           fbond="$(for i in $bondinfs;do echo -n "$i ";done)"
           create_port --bond "$bondbridge" "$bondname" "$fbond" "$bondoptions"
           add_delete_port_bridge add-port port "$bondbridge" "$bondname"
           fix_config_file
      elif [[ "$2" = tunnel ]];then
           local addport="$4"
           local addbridge="$3"
           local type="$5"
           local remoteip="$6"
           local key="$7"
           create_port --tunnel "$addbridge" "$addport" "$type" "$remoteip" "$key"
           add_delete_port_bridge add-port port "$addbridge" "$addport"
           fix_config_file
      elif [[ "$2" = patch ]];then
           local var="$(grep "allow-ovs $3" $config)"
           if [[ "$var" != "" ]];then
               local patchbr1="$3"
           else
               create_Br_no_ip "$3"
               local patchbr1="$3"
           fi
           local var2="$(grep "allow-ovs $4" $config)"
           if [[ "$var2" != "" ]];then
               local patchbr2="$4"
           else
               create_Br_no_ip "$4"
               local patchbr2="$4"
           fi
           local patchbr1port="$patchbr1-patch-port"
           local patchbr2port="$patchbr2-patch-port"
           create_port --patch "$patchbr1" "$patchbr2" "$patchbr1port" "$patchbr2port"
           add_delete_port_bridge add-port port "$patchbr1" "$patchbr1port"
           add_delete_port_bridge add-port port "$patchbr2" "$patchbr2port"
           fix_config_file
      fi
      ;;
  del-port)
      if [[ "$2" = --fb ]];then
          local delport="$4"
          local delbridge="$3"
          local line="$(cat -n $config.new | egrep "$delbridge|$(item_items bridge $delbridge)" | egrep "iface $delbridge inet|ovs_ports" | egrep -A1 "iface $delbridge inet" | tail -n1 | awk '{print $1}' | sed 's/ //g')"
          local ed_bit="$(item_items bridge $delbridge | egrep "ovs_ports")"
          local var="$(echo "$ed_bit" | sed "s/ $delport//g")"
          sed -i "${line}s/$ed_bit/$var/g" $config.new
          delete_elem port "$delbridge" "$delport"
          fix_config_file
      elif [[ "$2" = --po ]];then
          local delport="$3"
          delete_elem port-only "$delport"
          fix_config_file
      fi
      ;;
  del-bond)
      local delbond="$3"
      local delbondbridge="$2"
      local ed_bit="$(item_items bridge $delbondbridge | egrep "ovs_ports")"
      local var="$(echo "$ed_bit" | sed "s/ $delbond//g")"
      sed -i "s/$ed_bit/$var/g" $config.new
      delete_elem port "$delbondbridge" "$delbond"
      fix_config_file
      ;;
  del-fbridge)
      local delfbridge="$2"
      parent_bridge="$(cat $config.new | egrep "ovs_ports|$delfbridge" | egrep allow- | awk '{print $1}' | awk -F- '{print $2}' | sed 's/ //g')"
      add_delete_port_bridge del-port --fb "$parent_bridge" "$delfbridge"
      fix_config_file
      ;;
  del-tunnel)
      local tunnelport="$2"
      tunnelbridge="$(cat $config.new | egrep "allow-|$tunnelport" | grep "$tunnelport" | grep "allow-" | awk '{print $1}' | awk -F- '{print $2}')"
      add_delete_port_bridge del-port --fb "$tunnelbridge" "$tunnelport"
      fix_config_file
      ;;
   del-patch)
      local patchbr1="$2"
      local patchbr2="$3"
      add_delete_port_bridge del-port --fb $patchbr1 $patchbr1-patch-port
      add_delete_port_bridge del-port --fb $patchbr2 $patchbr2-patch-port
      fix_config_file
      ;;
      esac
done
}

function main(){
#test "$@"
add_delete_port_bridge "$@"
#delete_elem "$@"
#add_delete_port_to_bridge "$@"
#items_bridge "$1"
#item_items "$@"
#props $BRIDGE
#if [[ "$@" = -h ]];then
#    echo "help"
#    exit 0
#elif [[ "$@" != "" ]];then
#	add_delete_port_bridge "$@"
#	fix_config_file
#	exit 0
#else
#	fix_config_file
#   exit 0
#fi
}
main "$@"
