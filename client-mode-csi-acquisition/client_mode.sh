#!/bin/bash
# %%
# % The MIT License (MIT)
# % Copyright (c) 2017 Wu Zhiguo <wuzhiguo@bupt.edu.cn>
# % 
# % Permission is hereby granted, free of charge, to any person obtaining a 
# % copy of this software and associated documentation files (the "Software"), 
# % to deal in the Software without restriction, including without limitation 
# % the rights to use, copy, modify, merge, publish, distribute, sublicense, 
# % and/or sell copies of the Software, and to permit persons to whom the 
# % Software is furnished to do so, subject to the following conditions:
# % 
# % The above copyright notice and this permission notice shall be included 
# % in all copies or substantial portions of the Software.
# % 
# % THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
# % OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# % FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# % AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# % LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
# % FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
# % DEALINGS IN THE SOFTWARE.
# %
# %% Some useful scripts for csi collecting
# % 
# % Developed by Wu Zhiguo(Beijing University of Post and Telecommunication)
# % QQ group for discusion: 366102075
# % EMAIL:1600682324@qq.com wuzhiguo@bupt.edu.cn
# % Github: https://github.com/wuzhiguocarter/Awesome-WiFi-CSI-Research
# % Blog: http://www.jianshu.com/c/6e0897ba0cec [WiFi CSI Based Indoor Localization]

echo "...shut down wlan0"
sudo iw dev wlan0 disconnect
sudo ifconfig wlan0 down
sleep 1

# echo "...cd csitool-14.04 folder"
# cd Downloads/csitool-14.04/

echo "...iwconfig"
iwconfig

echo "...unload 802.11 driver"
sudo modprobe -r iwlwifi mac80211 cfg80211
sleep 1

echo "...reload 802.11 driver with CSI logging enabled"
sudo modprobe iwlwifi connector_log=0x1

sleep 1

echo "...activate wlan0"
sudo iwconfig wlan0 txpower auto
sudo ifconfig wlan0 up
sleep 1

## warning: command failed: Device or resource busy (-16)
# echo "...set channel type <HT>, and channel width 20MHz"
# sudo iw dev wlan0 set channel 6 HT20

echo "...scanning"
sudo iw dev wlan0 scan 2>/dev/null 1>/dev/null
sleep 1

# AP=TP-LINK_1CBE | TP-LINK_3FF6 | HMwzzggg
AP=$1
Interval=$2
IP=$3
Attribute=$4

echo "...connect hotpot ssid:${AP}"
sudo iw dev wlan0 connect ${AP}
sleep 1

# echo 0x6907 | sudo tee /sys/kernel/debug/ieee80211/phy0/netdev:wlan0/stations/00:0f:34:9d:01:a0/rate_scale_table

# don't use in client mode
#echo "...set transmit bitrates"
#sudo iw dev wlan0 set bitrates mcs-2.4 16 #180 Mbps

# */2 *	* * *	root    cd /home/wzg && sh client_mode.sh HMwzzggg && ping -i 1 192.168.43.1 --report /etc/cron.hourly
## run only once
sudo killall dhcpcd-bin
echo "...obtain wireless ip addr"
sudo dhcpcd wlan0
sleep 1


# echo "...iw dev wlan0 link"
# iwconfig | grep Frequency | awk '{print $2}' >> ~/Desktop/csiRAW/csi_client_${AP}/data/readme.md
sudo ping -i ${Interval} ${IP} 2>/dev/null 1>/dev/null &

sudo pkill log_to_file
# echo "...logging csi for Client mode ${k}-th file"
# sudo linux-80211n-csitool-supplementary/netlink/log_to_file  ~/Desktop/csiRAW/csi_client_${AP}/data/csi_${AP}_$(date -d "today" +"%Y%m%d_%H%M%S").dat

for k in $( seq 1 10 )
do
	echo "...logging csi for Client mode ${k}-th file"
	~/log2file.sh ${AP} ${Attribute} &
	sleep 60
	pkill log_to_file
	pkill log2file.sh
done
