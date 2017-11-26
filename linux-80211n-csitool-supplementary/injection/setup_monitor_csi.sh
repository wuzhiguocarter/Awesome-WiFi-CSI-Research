#!/usr/bin/sudo /bin/bash
modprobe -r iwlwifi mac80211 cfg80211
modprobe iwlwifi connector_log=0x1
# Setup monitor mode, loop until it works
iwconfig wlan0 mode monitor 2>/dev/null 1>/dev/null
while [ $? -ne 0 ]
do
	iwconfig wlan0 mode monitor 2>/dev/null 1>/dev/null
done
iw wlan0 set channel $1 $2
ifconfig wlan0 up
