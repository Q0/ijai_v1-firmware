#!/bin/sh

WIFI_CONF_FILE="/etc/miio/wifi.conf"
DEVICE_CONFIG_FILE="/etc/miio/device.conf"

TEST_MODE="/etc/miio/testmode"

wifi_ap_mode()
{
    # AP mode
    MODEL=`cat $DEVICE_CONFIG_FILE | grep -v ^#`
    MODEL=${MODEL##*model=}
    MODEL=`echo $MODEL | cut -d ' ' -f 1`
    vendor=`echo ${MODEL} | cut -d '.' -f 1`
    product=`echo ${MODEL} | cut -d '.' -f 2`
    version=`echo ${MODEL} | cut -d '.' -f 3`

    #CMD="${WIFI_SETUP_SCRIPT}  wlan0 ap nl80211 ${vendor}-${product}-${version}_miap$1 0 open"
    #CMD="softap_up ${vendor}-${product}-${version}_miap$1 open broadcast 6"
    #echo "CMD=${CMD}"
    #${CMD}
}

wifi_sta_mode()
{
    CMD="wifi_start.sh sta_mode wifi_connect_ap_test $1 $2"
    echo "CMD=${CMD}"
}

get_ssid_passwd()
{
    STRING=`cat $WIFI_CONF_FILE | grep -v ^#`
    key_mgmt=${STRING##*key_mgmt=}
    if [ $key_mgmt == "NONE" ]; then
	passwd=""

	ssid=${STRING##*ssid=\"}
	ssid=${ssid%%\"*}
    else
	passwd=${STRING##*psk=\"}
	passwd=${passwd%%\"*}

	ssid=${STRING##*ssid=\"}
	ssid=${ssid%%\"*}
    fi
}

start()
{
    if [ -e $TEST_MODE ]; then
	rm -rf $TEST_MODE
        exit	
    fi

    if [ -e $WIFI_CONF_FILE ]; then
	get_ssid_passwd
	wifi_sta_mode $ssid $passwd
    else
	STRING=`ifconfig wlan0`

	macstring=${STRING##*HWaddr }
	macstring=`echo ${macstring} | cut -d ' ' -f 1`

	mac1=`echo ${macstring} | cut -d ':' -f 5`
	mac2=`echo ${macstring} | cut -d ':' -f 6`
	MAC=${mac1}${mac2}

	wifi_ap_mode $MAC
    fi
}

start
