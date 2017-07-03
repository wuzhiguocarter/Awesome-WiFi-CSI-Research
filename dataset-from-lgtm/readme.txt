WiFi CSI定位数据集
此数据集，节选自开源项目lgtm
1. 数据集描述
lgtm-monitor.dat--1m-10-degrees--laptop-2--test-7
lgtm    …… 项目名称 Look Good To Me的缩写
monitor …… 表示采用Monitor模式
1m	…… 表示接收端与发射端的距离为1m
10degrees …… 表示视距路径与接收端天线阵的法线夹角为10degrees
laptop-2  …… 表示该文件是在第2台笔记本上采集的
test-7    …… 表示采集条件为<1m, 10deg, laptop-2>的第7个文件

fc = 5.32 * 10^9;
delta_f = (40 * 10^6) / 30;
Nc = 30;
Nrx = 3;

2. 数据集大小
采集条件<Distance, Angle, Laptop> 组成的三元组
Distance = {1m, 2m, 3m}
Angle = { -20deg, -10deg, 0deg, 10deg, 20deg}
Laptop = {laptop-1,laptop-2}
所以，总的采集情况有30种，每种情况重复采集10次，所以总共300个数据文件。
每个数据文件有1025个Packet的CSI采样值，所以总共是300*1025个CSI样本

3. 分类还是回归？
综上，有30个标签可以学习，每个标签有10*1025个样本数据
分类的话，只能在上述样本范围内实现定位。
回归的话，外推的可靠性如何？
