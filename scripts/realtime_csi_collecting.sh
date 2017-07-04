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

AP=TP-LINK_3FF6
Interval=0.1 #0.03
IP=192.168.1.1
serverIP=10.109.11.17
port=8080

sudo pkill ping
sudo pkill dhcpcd-bin

echo "...shut down wlan0"
sudo iw dev wlan0 disconnect
sudo ifconfig wlan0 down
sleep 1

echo "...iwconfig"
iwconfig

echo "...unload 802.11 driver"
sudo modprobe -r iwlwifi mac80211 cfg80211
sleep 0.1

echo "...reload 802.11 driver with CSI logging enabled"
sudo modprobe iwlwifi connector_log=0x1

sleep 0.1

echo "...activate wlan0"
sudo iwconfig wlan0 txpower auto
sudo ifconfig wlan0 up
sleep 0.1

echo "...scanning"
sudo iw dev wlan0 scan 2>/dev/null 1>/dev/null
sleep 1

echo "...connect hotpot ssid:${AP}"
sudo iw dev wlan0 connect ${AP}
sleep 0.1

echo "...obtain wireless ip addr"
sudo dhcpcd wlan0
sleep 0.1

sudo ping -i ${Interval} ${IP} #2>/dev/null 1>/dev/null &

#open another terminal and do the following cmd
#sudo ./log_to_server ${serverIP} ${port}