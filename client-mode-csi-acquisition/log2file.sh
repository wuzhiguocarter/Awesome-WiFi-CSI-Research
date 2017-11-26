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

AP=$1
Attribute=$2

rootDir=~/Desktop/csiRAW/${AP}/$(date -d "today" +"%Y%m%d")/${Attribute}

mkdir -p rootDir
chown wzg ~/Desktop/csiRAW/${AP}
chown wzg ~/Desktop/csiRAW/${AP}/$(date -d "today" +"%Y%m%d")
chown wzg ${rootDir}

datDir=${rootDir}/data
logDir=${rootDir}/log
figDir=${rootDir}/fig
mkdir -p ${datDir}
chown wzg ${datDir}
mkdir -p ${logDir}
chown wzg ${logDir}
mkdir -p ${figDir}
chown wzg ${figDir}

logCMDpath=/home/wzg/Downloads/csitool-14.04/linux-80211n-csitool-supplementary/netlink

echo "...iw dev wlan0 link"
# iw dev wlan0 link | grep freq | awk '{print $2}' >> ${datDir}/readme.md
iw dev wlan0 link >> ${datDir}/readme.md
chown wzg ${datDir}/readme.md

sudo ${logCMDpath}/log_to_file ${datDir}/$(date -d "today" +"%Y%m%d_%H%M%S").dat