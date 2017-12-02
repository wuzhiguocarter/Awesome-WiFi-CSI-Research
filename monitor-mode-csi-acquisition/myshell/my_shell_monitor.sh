#!/bin/bash
# 
currentDir=`pwd`
WIFIDEV=wlan0

cd ../injection
if [ $1 == 0 ]
then 
	modprobe -r iwlwifi mac80211 cfg80211 && sleep 1
	modprobe    iwlwifi connector_log=0x1 && sleep 1
    echo "end"
else 
	cd ../injection
	ip link set ${WIFIDEV} down && sleep 1
	iw dev ${WIFIDEV} set type monitor && sleep 1
	ip link set ${WIFIDEV} up && sleep 1
	iw dev ${WIFIDEV} set channel $2 $3 && sleep 1
	echo "logging csi data to file ..."
	../netlink/log_to_file ../data/$2_$3.$(date -d "today" +"%Y%m%d_%H%M%S").dat  &
	sleep 30
	pkill log_to_file
	cd ${currentDir}
fi
