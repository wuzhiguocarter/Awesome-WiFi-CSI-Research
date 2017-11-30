#!/bin/bash

if [ $1 == 0 ]
then 
	echo "reload driver"
	sudo modprobe -r iwlwifi mac80211    && sleep 1
	sudo  modprobe iwlwifi debug=0x40000 && sleep 1
	echo "del wlan0  mon0 "
	iw dev wlan0 del && sleep 1
	iw dev mon0  del && sleep 1
	echo "add mon0"
	iw phy phy0 interface add mon0 type monitor && sleep 1
	ip link set mon0 up && sleep 1
	echo "end"
else 
	#echo "reload driver"
	#sudo modprobe -r iwlwifi mac80211    && sleep 1
	#sudo  modprobe iwlwifi debug=0x40000 && sleep 1
	#echo "del wlan0  mon0 "
	#iw dev wlan0 del && sleep 1
	#iw dev mon0  del && sleep 1
	#echo "add mon0"
	#iw phy phy0 interface add mon0 type monitor && sleep 1
	#ip link set mon0 up && sleep 1
	cd ../injection
	echo "changing channel"
	iw dev mon0 set channel $2 $3 && sleep 1
	ifconfig mon0 up && sleep 1
	echo 0x4101 |sudo tee /sys/kernel/debug/ieee80211/phy0/iwlwifi/iwldvm/debug/monitor_tx_rate
    echo "start injection at "$(date -d "today" +"%Y%m%d_%H%M%S")
    ./random_packets 10000 100 1 
    echo "end injection at "$(date -d "today" +"%Y%m%d_%H%M%S")
fi

