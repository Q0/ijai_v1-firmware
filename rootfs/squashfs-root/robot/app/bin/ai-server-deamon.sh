#!/bin/sh

sleep 2
echo user_space > /sys/class/thermal/thermal_zone0/policy
echo disabled > /sys/class/thermal/thermal_zone0/mode
echo 0 > /sys/class/thermal/thermal_zone0/cdev0/cur_state
echo 0 > /sys/class/thermal/thermal_zone0/cdev1/cur_state

while true;
do
	
	rkisp_pid=`pidof rkisp_3A_server`
	if [ -z $rkisp_pid ];then
		lDate=`date "+%Y-%m-%d %H:%M:%S"`
		echo "$lDate :Monitor rkisp_3A_server not run" > /tmp/rkisp_3A_server.log
		/etc/init.d/S40rkisp_3A start	
		#killall Ai-server
	fi

	ai_pid=`pidof Ai-server`
        if [ -z $ai_pid ];then
		lDate=`date "+%Y-%m-%d %H:%M:%S"`
		echo "$lDate :Monitor Ai-server not run" > /tmp/Ai-server.log
		/userdata/app/bin/Ai-server &
        fi

	sleep 5
done
