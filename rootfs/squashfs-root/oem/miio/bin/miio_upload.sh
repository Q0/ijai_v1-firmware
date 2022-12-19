#!/bin/sh

sleep 1

Modify="2021-01-28 19:00:14.225003471 +0800"
echo $Modify

while true;
do
    
    # lDate=`date "+%Y-%m-%d %H:%M:%S"; wpa_cli scan_results | grep ":"`
    # echo -e "$lDate \n" >> /userdata/log/rssi.log
    if [ -f "/tmp/messages.0" ]; then
        test=$(stat /tmp/messages.0 | grep Modify | awk -F 'Modify: ' '{print $2}')
        echo $test

        if [ "${Modify}" == "${test}" ]; then
            echo "hahaha\n"
        else
            echo "hehehe\n"
            curtime=$(date +%s)
            target="/userdata/log/message-$curtime.temp.gz"
            echo $target
            Modify=$test
            glog=$(gzip -c /tmp/messages.0 > $target)
            echo $Modify
            echo $glog
        fi
    fi

    sleep 5

done
