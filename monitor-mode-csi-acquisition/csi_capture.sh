#!/usr/bin/expect
##参数设置 工控机 & 笔记本

# 发射机
set user_injection csi-sender
set password_injection 1111
set ip_injection 10.109.9.142


# 接收机
set user_monitor wzg
set password_monitor 1111
set ip_monitor 10.109.9.60

# 设置路径
set monitor_shell_dir   /home/wzg/Desktop/liuyx/linux-80211n-csitool-supplementary/myshell
set injection_shell_dir /home/csi-sender/Desktop/liuyx/linux-80211n-csitool-supplementary/myshell

set timeout 30
#initialization the array of channel
# channel 1,2, ..., 13
set channel(0) 1
set cnt 0

while { $cnt < 13 } {
	set channel($cnt) [expr $cnt+1]
	puts "value of channel($cnt): $channel($cnt)"
	incr cnt
}

# channel 36,40, ... , 64 
set channel($cnt) 36
puts "value of channel($cnt): $channel($cnt)"
set cnt2 $cnt
incr cnt
while  { $cnt < 21} {
	set channel($cnt) [expr $channel($cnt2)+4]
	puts "value of channel($cnt): $channel($cnt)"
	incr cnt
	incr cnt2
}

# channel 100,104, ... , 140  
set channel($cnt) 100
puts "value of channel($cnt): $channel($cnt)"
set cnt2 $cnt
incr cnt
while  { $cnt < 32 } {
	set channel($cnt) [expr $channel($cnt2)+4]
	puts "value of channel($cnt): $channel($cnt)"
	incr cnt
	incr cnt2
}

# injection
puts stdout "\n Loging to injection... \n"
spawn ssh $user_injection@$ip_injection
expect "yes/no"    {send "yes\n"} \
"*password:*" {send "$password_injection\n"} \
"*assword:" {send "$password_injection\n"}
set id_injection $spawn_id

expect "$user_injection@*" {send "sudo -s\n"}
expect "password" {send "$password_injection\n"} "root@" 

# monitor 
puts stdout "\n Loging to monitor...\n"
spawn ssh $user_monitor@$ip_monitor
expect "yes/no"    {send "yes\n"} \
"*password:*" {send "$password_monitor\n"} \
"*assword:" {send "$password_monitor\n"}
set id_monitor $spawn_id

expect "$user_monitor@*"   {send "sudo -s\n"}
expect "password" {send "$password_monitor\n"} "root@" 

set spawn_id $id_monitor 
# 初始化
expect "root@" {send "cd $monitor_shell_dir\n"}
expect "root@" {send "bash ./my_shell_monitor.sh 0\n"}
expect "end"

set spawn_id $id_injection 
expect "root@" {send "cd $injection_shell_dir\n"}
expect "root@" {send "bash ./my_shell_injection.sh 0\n"}
expect "end"


set spawn_id $id_monitor
expect "root@" {send "rm -rf ../data \n"}
expect "root@" {send "mkdir ../data \n"}
# expect "root@" {send "sudo /etc/init.d/network-manager stop\n"}

# 开始扫描
set cnt_index 0
while { $cnt_index < $cnt } {
	set spawn_id $id_monitor
	expect "root@" {send "bash ./my_shell_monitor.sh 1 $channel($cnt_index) HT20\n"}
	expect "end"
	set spawn_id $id_injection
	expect "root@" {send "bash ./my_shell_injection.sh 1 $channel($cnt_index) HT20\n"}
	expect "end"
	set spawn_id $id_monitor
	expect "root@" {send "sleep 10\n"}
	expect "root@" {send "pkill log_to_file\n"}
	incr cnt_index
}
set spawn_id $id_monitor
#expect "root@" {send "cd .. && ./mvdat.sh\n"}
#expect "end"

interact


