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

## TP-Link(WR886N)
# sudo ./client_mode.sh TP-LINK_3FF6 0.03 192.168.1.1
# sudo ./client_mode.sh TP-LINK_3FF6 0.03 10.3.8.211
AP=TP-LINK_3FF6
Interval=0.03
IP=192.168.1.1
Attribute=room1015-bet2desks-0deg-185cm
# Attribute=room1015-xiaotang2desk-15deg

sudo ./client_mode.sh ${AP} ${Interval} ${IP} ${Attribute}

# $1 SSID of AP
# $2 interval of ping cmd
# $3 ip of AP
# $4 DoA[deg],range[m]

# sudo ping -i 0.03 192.168.1.1 &

# while [ 1 -lt 10 ]
# do
# 	./client_mode.sh TP-LINK_3FF6 &
# 	sleep 60
# done

## TP-Link(WR742N)
# sudo ping -i 0.03 192.168.1.1 &

# while [ 1 -lt 10 ]
# do
# 	./client_mode.sh TP-LINK_1CBE &
# 	sleep 60
# done

# sudo ./client_mode.sh TP-LINK_1CBE 0.03 192.168.1.1

## Mobile Hotpot
# sudo ping -i 0.03 192.168.43.1 &
# while [ 1 -lt 10 ]
# do
# 	./client_mode.sh HMwzzggg &
# 	sleep 60
# done

# sudo ping -i 0.03 192.168.43.1 &
# sudo ./client_mode.sh HMwzzggg