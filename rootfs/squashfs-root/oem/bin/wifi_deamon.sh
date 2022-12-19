#!/bin/sh
sleep 5

GPIO_RECOVEY_KEY=6
gpioInit()
{
	if [ ! -d "/sys/class/gpio/gpio$1" ];then
		echo $1 > /sys/class/gpio/export
		echo in > /sys/class/gpio/gpio$1/direction
	fi
}

sysConfigdefault()
{
	lDate=`date "+%Y-%m-%d %H:%M:%S"`                          
	echo "sysConfigdefault  start at $lDate" >> /userdata/log/wifi_deamon.log
        killall Monitor
	killall RobotApp AuxCtrl upgrade wifiManager log-server
	rm -rf /userdata/config/*
	rm -rf /userdata/log/*
	rm -rf /data/cfg/*
	sync
	lDate=`date "+%Y-%m-%d %H:%M:%S"`                  
        echo "sysConfigdefault end at $lDate" >> /userdata/log/wifi_deamon.log

}


checkRecoveyKey()                                         
{
checkCount=0
while true;
do

	recovery_key=`cat /sys/class/gpio/gpio${GPIO_RECOVEY_KEY}/value`
	if [ $recovery_key -eq 1 ]
	then
		echo "recovery key is down count $checkCount " >> /userdata/log/wifi_deamon.log
		if [ $checkCount -gt 3 ]
		then
			play /oem/audio/mandarin/sound_reset_factory_config.mp3
			sysConfigdefault
			echo "system config default now" >> /userdata/log/wifi_deamon.log
			reboot -f 
		fi
		checkCount=0
		break
	else
		checkCount=`expr $checkCount + 1`
		if [ $checkCount -gt 10 ]             # check if key down 5s will enter recovey
		then
			echo "recovery key is down count $checkCount need default config and backup system" >> /userdata/log/wifi_deamon.log
			play /oem/audio/mandarin/sound_reset_factory_config_successful.mp3
			/usr/bin/updateEngine --misc=other
			touch /userdata/sys_defaut_reset
			sysConfigdefault
			echo "default config and backup system finish reboot robot" >> /userdata/log/wifi_deamon.log
			reboot -f 
		else
			echo "wait defaultsystem config  $checkCount" >> /userdata/log/wifi_deamon.log
		fi
	fi
	sleep 1
	
done
}

checkKeyStatus()                                         
{                                                         
        recovery_key=`cat /sys/class/gpio/gpio6/value`                       
        if [ $recovery_key -eq 0 ]                                           
        then                                                                                                
        	checkRecoveyKey
	fi                                                                                       
}

checkwifiManager()
{
	wifi_pid=`pidof wifiManager`
	if [ -z $wifi_pid ];then
		lDate=`date "+%Y-%m-%d %H:%M:%S"`
		echo "$lDate :wifiManager not run" >> /userdata/log/miio_deamon.log
	else
		if [ -f "/tmp/wifi_ap_mode" ]; then
			echo  "wifi ap mode..."
		else
			pid=`pidof miio_client`
			if [ -z $pid ];then
				lDate=`date "+%Y-%m-%d %H:%M:%S"`
				echo "$lDate :miio_client restart" >> /userdata/log/miio_deamon.log
				killall miio_client_helper.sh
				if [ -f "/userdata/debug_mode" ];then
				    /oem/miio/bin/miio_client -l 1 -L /userdata/log/miio_client.temp -d /userdata/miio/conf/ -o MSC -o DISABLE_PSM -n 128 -D
				    /oem/miio/bin/miio_client_helper.sh >> /userdata/log/miio_client.temp &
				else
				    /oem/miio/bin/miio_client -l 1 -d /userdata/miio/conf/ -o MSC -o DISABLE_PSM -n 128 -D
				    /oem/miio/bin/miio_client_helper.sh &
				fi
			fi
			
			pid=`pidof miio_client_helper.sh`
			if [ -z $pid ];then
				lDate=`date "+%Y-%m-%d %H:%M:%S"`
				echo "$lDate :miio_client_helper restart" >> /userdata/log/miio_deamon.log
				killall miio_client
				if [ -f "/userdata/debug_mode" ];then
				    /oem/miio/bin/miio_client -l 1 -L /userdata/log/miio_client.temp -d /userdata/miio/conf/ -o MSC -o DISABLE_PSM -n 128 -D
				    /oem/miio/bin/miio_client_helper.sh >> /userdata/log/miio_client.temp &
				else
				    /oem/miio/bin/miio_client -l 1 -d /userdata/miio/conf/ -o MSC -o DISABLE_PSM -n 128 -D
				    /oem/miio/bin/miio_client_helper.sh &
				fi
			fi
		fi	
	fi

}


checkUpgrade()
{
	upgrade_pid=`pidof upgrade`
        if [ -z $upgrade_pid ];then
                lDate=`date "+%Y-%m-%d %H:%M:%S"`
                echo "$lDate :upgrade not run" >> /userdata/log/wifi_deamon.log
                /oem/bin/upgrade >> /dev/null &
        fi
}


checkLogFile()
{
	if [ -f "/userdata/log/wifi_deamon.log" ];then
                FILE_SIZE=`du /userdata/log/wifi_deamon.log | awk '{print $1}'`
                if [ $FILE_SIZE -ge 1048576 ];then
                        rm -rf /userdata/log/wifi_deamon.log
                        echo echo "/userdata/log/wifi_deamon.log file over delete"
                fi
        fi

 	if [ -f "/userdata/log/miio_client.temp" ];then
                FILE_SIZE=`du /userdata/log/miio_client.temp | awk '{print $1}'`
                if [ $FILE_SIZE -ge 1008576 ];then
			lDate=`date "+%Y-%m-%d %H:%M:%S"`
                        cp -rf /userdata/log/miio_client.temp /userdata/log/$lDate_miio_client.txt
                        echo echo "/userdata/log/wifi_deamon.log file over delete"
                fi
        fi
	if [ -f "/userdata/log/miio_client_helper.temp" ];then
                FILE_SIZE=`du /userdata/log/miio_client_helper.temp | awk '{print $1}'`
                if [ $FILE_SIZE -ge 2008576 ];then
                        lDate=`date "+%Y-%m-%d %H:%M:%S"`
                        cp -rf /userdata/log/miio_client_helper.temp /userdata/log/$lDate_miio_client_helper.txt
                        echo echo "/userdata/log/wifi_deamon.log file over delete"
                fi
        fi


}

checkUsbIp()
{
    STRING=`ifconfig usb0`
#    echo "STRING is $STRING"
    if [ "x$STRING" != "x" ]; then
        ip=${STRING##*inet addr:}
        ip=`echo ${ip} | cut -d ' ' -f 1`
        if [ "$ip" == "10.10.10.1" ]; then
            echo "ip: $ip"
        else
            echo "set usb0 ip"
            ifconfig usb0 10.10.10.1
        fi
    fi
}



gpioInit ${GPIO_RECOVEY_KEY}


LoopCount=0
while true;
do
	sleep 1
	checkKeyStatus
	LoopCount=`expr $LoopCount + 1`
	if [ $LoopCount -gt 5 ]            
	then
		checkwifiManager
		checkUpgrade
		checkLogFile
                checkUsbIp
		LoopCount=0
	fi	
done
