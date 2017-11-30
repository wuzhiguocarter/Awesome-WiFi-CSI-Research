#!/bin/bash

# channel list
#channel_1_to_13=`seq 1 1 13`
#channel_36_to_64=`seq 36 4 64`
#channel_100_to_140=`seq 100 4 140`
#channel_array="$channel_1_to_13 $channel_36_to_64 $channel_100_to_140"
#echo "all channel: "$channel_array

# mkdir data
rm -rf ../data
mkdir ../data


if [ $1 == "setup"]
then
# setup(run only once)
	./my_shell_monitor.sh 0
else
# work
#./my_shell_monitor.sh 1 11 HT20
	./my_shell_monitor.sh 1 64 HT20
fi
