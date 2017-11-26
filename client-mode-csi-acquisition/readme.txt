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

用法一：后处理模式
采集CSI并同步存储到文件,每分钟生成一个新的文件，文件名以时间戳自动命名
sudo ./callEveryMin.sh
采集文件的参考目录视图，见本目录下tree.txt
注意：
1. 该脚本依赖client_mode.sh, log2file.sh以及linux-80211n-csitool-supplementary/netlink文件夹下的log_to_file可执行文件
2. 使用前需要设置的参数
（1）callEveryMin.sh
AP	……Intel 5300要连接的AP名称
Interval……ping发包时间间隔
IP	……路由器IP地址
Attribute……采集csi文件名前缀
（2）log2file.sh
rootDir	……保存采集的csi文件绝对路径


用法二：实时可视化模式
采集CSI，并通过sockets通信与Matlab链接，实时可视化

step1: 将Realtime-processing-for-csitool/network/read_bf_socket.m拷贝到linux-80211n-csitool-supplementary/netlink文件下，并运行运行read_bf_socket.m函数，等待链接

step2: 采集CSI
sudo ./realtime_csi_collecting

step3: 通过TCP将CSI流传到matlab，并激活read_bf_socket中CSI可视化程序
sudo ./log_to_server <ip> <port>

注意：
1. 此模式需要Realtime-processing-for-csitool的支持，工具详见https://github.com/lubingxian/Realtime-processing-for-csitool
2. 下载该工具，需要在netlink文件夹下编译log_to_file，这里直接把编译好的可执行文件放在这里，方便使用


