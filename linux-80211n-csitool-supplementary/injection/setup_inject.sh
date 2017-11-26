#!/usr/bin/sudo /bin/bash
WIFIDEV=wlan0
echo "...shut down ${WIFIDEV}"
sudo iw dev ${WIFIDEV} disconnect
sudo ifconfig ${WIFIDEV} down
sleep 1

echo "...unload 802.11 driver"
sudo modprobe -r iwlwifi mac80211 cfg80211 iwldvm
sleep 1


#echo "...reload 802.11 driver with CSI logging enabled"
#sudo modprobe iwlwifi connector_log=0x1
#sleep 1

#sudo modprobe -r iwldvm iwlwifi mac80211
#sudo modprobe -r cfg80211
#sudo modprobe iwlwifi debug=0x40000
#if [ "$#" -ne 2 ]; then
#    echo "Going to use default settings!"
#    chn=64
#   bw=HT20
#else
#    chn=$1
#    bw=$2
#fi
#ifconfig ${WIFIDEV} 2>/dev/null 1>/dev/null
#while [ $? -ne 0 ]  
#do  
#   ifconfig ${WIFIDEV} 2>/dev/null 1>/dev/null  
#done  
#iw dev ${WIFIDEV} interface add mon0 type monitor  
  
#ifconfig ${WIFIDEV} down  
#while [ $? -ne 0 ]  
#do  
#    ifconfig ${WIFIDEV} down  
#done  
#ifconfig mon0 up  
#while [ $? -ne 0 ]  
#do  
#    ifconfig mon0 up  
#done  
  
#iw mon0 set channel $chn $bw  



modprobe -r iwlwifi mac80211 cfg80211
modprobe iwlwifi debug=0x40000
ifconfig wlan0 2>/dev/null 1>/dev/null
while [ $? -ne 0 ]
do
	        ifconfig wlan0 2>/dev/null 1>/dev/null
done
iw dev wlan0 interface add mon0 type monitor
iw mon0 set channel $1 $2
ifconfig mon0 up

