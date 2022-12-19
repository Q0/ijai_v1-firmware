#!/bin/sh

WIFI_START_SCRIPT="/etc/miio/wifi_start.sh"
MIIO_RECV_LINE="/oem/miio/bin/miio_recv_line"
MIIO_SEND_LINE="/oem/miio/bin/miio_send_line"
WIFI_MAX_RETRY=5
WIFI_RETRY_INTERVAL=3
WIFI_SSID=

WIFI_CONF_PATH="/etc/miio/wifi.conf"
WIFI_SSID_CONF_PATH="/etc/miio/wifi_ssid.conf"
DEVICE_UID_PATH="/etc/miio/device.uid"
DEVICE_COUNTRY_PATH="/etc/miio/device.country"
DEVICE_BIND_STATUS_PATH="/etc/miio/bind.status"

DEFAULT_TIMEZONE_LINK="/usr/share/zoneinfo/Asia/Shanghai"
GLIBC_TIMEZONE_DIR="/usr/share/zoneinfo"
UCLIBC_TIMEZONE_DIR="/usr/share/zoneinfo/uclibc"

YOUR_LINK_TIMEZONE_FILE="/mnt/data/TZ"
YOUR_TIMEZONE_DIR=$UCLIBC_TIMEZONE_DIR

LINK_HOSTS_FILE="/etc/miio/hosts"
PRC_LINK_HOSTS_FILE="/etc/miio/hosts.prc"
GLOBAL_LINK_HOSTS_FILE="/etc/miio/hosts.global"

MIIO_NET_PROVISIONER_SSID="25c829b1922d3123_miwifi"
WIFI_RECONNECT_CONF_PATH="/tmp/wifi_reconnect"
WIFI_SELECT_HIDDEN_CONF_PATH="/tmp/wifi_select_hidden"
WIFI_DISABLE_CHECK_STATUS_PATH="/tmp/wifi_disable_check_status"
WPA_SUPPLICANT_CONFIG_FILE="/tmp/wpa_supplicant.conf"

MIIO_NET_AUTO_PROVISION=0
MIIO_NET_SMART_CONFIG=1
MIIO_NET_5G=0
MIIO_AP_MODE=false


if [ $MIIO_NET_AUTO_PROVISION -eq 1 ]; then
	conf_status_params=3
else
	conf_status_params=0
fi

# contains(string, substring)
#
# Returns 0 if the specified string contains the specified substring,
# otherwise returns 1.
contains() {
    string="$1"
    substring="$2"
    if test "${string#*$substring}" != "$string"
    then
        return 0    # $substring is in $string
    else
        return 1    # $substring is not in $string
    fi
}

send_helper_ready() {
    ready_msg="{\"method\":\"_internal.helper_ready\"}"
    echo $ready_msg
    $MIIO_SEND_LINE "$ready_msg"
}

req_wifi_conf_status() {
    wificonf_dir=$1
    echo $wificonf_dir
    wificonf_dir=${wificonf_dir##*params\":\"}
    wificonf_dir=${wificonf_dir%%\"*}
    echo $wificonf_dir
    wificonf_file="${wificonf_dir}wifi.conf"

    echo $wificonf_file

    REQ_WIFI_CONF_STATUS_RESPONSE=""
    if [ -e $wificonf_file ]; then
		REQ_WIFI_CONF_STATUS_RESPONSE="{\"method\":\"_internal.res_wifi_conf_status\",\"params\":1}"
    else
		echo $conf_status_params
		REQ_WIFI_CONF_STATUS_RESPONSE="{\"method\":\"_internal.res_wifi_conf_status\",\"params\":$conf_status_params}"
    fi
}

request_dinfo() {
    # del all msq queue, or cause unexpected issues
    rm -f  /dev/mqueue/miio_queue*

    dinfo_dir=$1
    dinfo_dir=${dinfo_dir##*params\":\"}
    dinfo_dir=${dinfo_dir%%\"*}
    dinfo_file="${dinfo_dir}device.conf"
    echo "dinfo_file:$dinfo_file"

    dinfo_did=`cat $dinfo_file | grep -v ^# | grep did= | tail -1 | cut -d '=' -f 2`
    dinfo_key=`cat $dinfo_file | grep -v ^# | grep key= | tail -1 | cut -d '=' -f 2`
    dinfo_mjac_i2c=`cat $dinfo_file | grep -v ^# | grep mjac_i2c= | tail -1 | cut -d '=' -f 2`
    dinfo_mjac_gpio=`cat $dinfo_file | grep -v ^# | grep mjac_gpio= | tail -1 | cut -d '=' -f 2`
    dinfo_vendor=`cat $dinfo_file | grep -v ^# | grep vendor= | tail -1 | cut -d '=' -f 2`
    dinfo_mac=`cat $dinfo_file | grep -v ^# | grep mac= | tail -1 | cut -d '=' -f 2`
    dinfo_model=`cat $dinfo_file | grep -v ^# | grep model= | tail -1 | cut -d '=' -f 2`
    dinfo_pin_code=`cat $dinfo_file | grep -v ^# | grep pin_code= | tail -1 | cut -d '=' -f 2`
	
    if [ $MIIO_NET_SMART_CONFIG -eq 1 ]; then
	dinfo_wpa_intf='/var/run/wpa_supplicant/wlan0'
    fi
    if [ $MIIO_NET_AUTO_PROVISION -eq 1 ]; then
	dinfo_hostapd_intf='/var/run/hostapd/p2p0'
    fi
    
    # dd if=/dev/mtd0 of=/tmp/uboot.bin count=2 bs=64K
    # dinfo_uboot_ver=`md5sum /tmp/uboot.bin | cut -d ' ' -f 1`
    # rm /tmp/uboot.bin -rf

    echo $dinfo_did
#   echo $dinfo_key
    echo $dinfo_vendor
    echo $dinfo_mac
    echo $dinfo_model
    # echo $dinfo_ctrl_dir
    # echo $dinfo_ifname

    RESPONSE_DINFO="{\"method\":\"_internal.response_dinfo\",\"params\":{"
    if [ x$dinfo_did != x ]; then
	RESPONSE_DINFO="$RESPONSE_DINFO\"did\":$dinfo_did"
    fi
    if [ x$dinfo_key != x ]; then
	RESPONSE_DINFO="$RESPONSE_DINFO,\"key\":\"$dinfo_key\""
    fi
    if [ x$dinfo_mjac_i2c != x ]; then
	RESPONSE_DINFO="$RESPONSE_DINFO,\"mjac_i2c\":\"$dinfo_mjac_i2c\""
    fi
    if [ x$dinfo_mjac_gpio != x ]; then
	RESPONSE_DINFO="$RESPONSE_DINFO,\"mjac_gpio\":\"$dinfo_mjac_gpio\""
    fi
    if [ x$dinfo_vendor != x ]; then
	RESPONSE_DINFO="$RESPONSE_DINFO,\"vendor\":\"$dinfo_vendor\""
    fi
    if [ x$dinfo_mac != x ]; then
	RESPONSE_DINFO="$RESPONSE_DINFO,\"mac\":\"$dinfo_mac\""
    fi
    if [ x$dinfo_model != x ]; then
	RESPONSE_DINFO="$RESPONSE_DINFO,\"model\":\"$dinfo_model\""
    fi
    if [ x$dinfo_uboot_ver != x ]; then
	RESPONSE_DINFO="$RESPONSE_DINFO,\"bootloader_ver\":\"$dinfo_uboot_ver\""
    fi
    if [ x$dinfo_wpa_intf != x ]; then
	RESPONSE_DINFO="$RESPONSE_DINFO,\"wpa_intf\":\"$dinfo_wpa_intf\""
    fi
    if [ x$dinfo_hostapd_intf != x ]; then
	RESPONSE_DINFO="$RESPONSE_DINFO,\"hostapd_intf\":\"$dinfo_hostapd_intf\""
    fi

    #RESPONSE_DINFO="$RESPONSE_DINFO,\"OOB\":[{\"mode\":2,\"ctx\":\"\"},{\"mode\":3,\"ctx\":\"$dinfo_pin_code\"}]"
    RESPONSE_DINFO="$RESPONSE_DINFO,\"sc_type\":[0]"
    RESPONSE_DINFO="$RESPONSE_DINFO}}"
}

request_ot_config() {
    ot_config_string=$1
    ot_config_dir=${ot_config_string##*dir\":\"}
    ot_config_dir=${ot_config_dir%%\"*}
    dtoken_token=${ot_config_string##*ntoken\":\"}
    dtoken_token=${dtoken_token%%\"*}

    MIIO_TOKEN_FILE="${ot_config_dir}device.token"
    dcountry_file="${ot_config_dir}device.country"
    wificonf_file="${ot_config_dir}wifi.conf"
    uid_file="${ot_config_dir}device.uid"
    
    if [ ! -e "${ot_config_dir}wifi.conf" ]; then
        rm -f ${MIIO_TOKEN_FILE}
        rm -f ${dcountry_file}
        rm -f ${uid_file}
    fi
    
    if [ -e ${MIIO_TOKEN_FILE} ]; then
        dtoken_token=`cat ${MIIO_TOKEN_FILE}`
    else
        echo ${dtoken_token} > ${MIIO_TOKEN_FILE}
    fi

    dcountry_country=`cat ${dcountry_file}`
    uid=`cat ${uid_file}`
    
    if [ -f "$WIFI_SSID_CONF_PATH" ];then
		WIFI_SSID=`cat $WIFI_SSID_CONF_PATH | grep ssid_conf`
		WIFI_SSID=${WIFI_SSID#*ssid_conf=}		
		echo "ssid_conf:WIFI_SSID: $WIFI_SSID"					
	else
    	WIFI_SSID=`cat $wificonf_file | grep ssid`
    	WIFI_SSID=${WIFI_SSID#*ssid=\"}
    	WIFI_SSID=${WIFI_SSID%\"*}
    	echo "ssid:WIFI_SSID: $WIFI_SSID"
    fi	

    WIFI_PSK=`cat $wificonf_file | grep psk`
    WIFI_PSK=${WIFI_PSK#*psk=\"}
    WIFI_PSK=${WIFI_PSK%\"*}
    echo "WIFI_PSK: $WIFI_PSK"


	RESPONSE_OT_CONFIG="{\"method\":\"_internal.res_ot_config\",\"params\":{"
	RESPONSE_OT_CONFIG="$RESPONSE_OT_CONFIG\"token\":\"$dtoken_token\""
    if [ x$dcountry_country != x ]; then
	RESPONSE_OT_CONFIG="$RESPONSE_OT_CONFIG,\"country\":\"$dcountry_country\""
    fi
    if [ x$WIFI_SSID != x ]; then
	RESPONSE_OT_CONFIG="$RESPONSE_OT_CONFIG,\"ssid\":\"$WIFI_SSID\""
    fi
    if [ x$WIFI_PSK != x ]; then
	RESPONSE_OT_CONFIG="$RESPONSE_OT_CONFIG,\"password\":\"$WIFI_PSK\""
    fi
	if [ x$uid != x ]; then
	RESPONSE_OT_CONFIG="$RESPONSE_OT_CONFIG,\"uid\":$uid"
    fi
	RESPONSE_OT_CONFIG="$RESPONSE_OT_CONFIG}}"
}

update_dtoken(){                                                                                                                                                       
    update_token_string=$1                                                                                                                                                                            
    update_dtoken=${update_token_string##*ntoken\":\"}                                                                                                                                                
    update_token=${update_dtoken%%\"*}                                                                                                                                                                
                                                                                                                                                         
    if [ -e ${MIIO_TOKEN_FILE} ]; then
        rm -rf ${MIIO_TOKEN_FILE}
	echo ${update_token} > ${MIIO_TOKEN_FILE}
    fi
	RESPONSE_UPDATE_TOKEN="{\"method\":\"_internal.token_updated\",\"params\":\"${update_token}\"}" 
}

request_disconnect_wifi() {
	disconnect_wifi_str=$1
	echo $disconnect_wifi_str
	
	ssid=${disconnect_wifi_str##*\"ssid\":\"}
  ssid=${ssid%%\",\"bssid\":\"*}
  ssid=$(echo "${ssid}" | sed -e 's/\\\//\//g')
  ssid=$(echo "${ssid}" | sed -e 's/\\\\/\\/g')
	
	bssid=${disconnect_wifi_str##*\"bssid\":\"}
	bssid=${bssid%%\"*}
	bssid=`echo ${bssid} | cut -d ' ' -f 1 | tr '[:lower:]' '[:upper:]'`
	
	echo "hidden_ssid: $ssid"
	echo "hidden_bssid: $bssid"
	
	RESPONSE_DISCONNECT_WIFI="{\"method\":\"_internal.wifi_disconnect_resp\",\"params\":{\"ssid\":\"$ssid\",\"bssid\":\"$bssid\"}}";
	echo $RESPONSE_DISCONNECT_WIFI
	$MIIO_SEND_LINE "$RESPONSE_DISCONNECT_WIFI"
	
	if [ x"$ssid" = x"$MIIO_NET_PROVISIONER_SSID" ]; then
		if [ -e $DEVICE_BIND_STATUS_PATH ];then
			echo 1 > ${WIFI_DISABLE_CHECK_STATUS_PATH}
			wifi_reconnect
		else
			if [ -e $WIFI_CONF_PATH ];then
			   echo 1 > ${WIFI_DISABLE_CHECK_STATUS_PATH}
			   wifi_reconnect
			fi
		fi
	fi

}

save_wifi_conf() {
    datadir=$1
    miio_ssid=$2
    miio_passwd=$3
    miio_uid=$4
    miio_country=$5
    miio_ssid_conf=$6

    if [ -f $LINK_HOSTS_FILE ]; then
	unlink $LINK_HOSTS_FILE
    fi
    if [ x"$miio_country" = x ]; then
	ln -sf $PRC_LINK_HOSTS_FILE $LINK_HOSTS_FILE
    else
	ln -sf $GLOBAL_LINK_HOSTS_FILE $LINK_HOSTS_FILE
    fi

    if [ x"$miio_ssid" = x ]; then
    echo "ssid=NONE"
    else
    echo "ssid=\"$miio_ssid\"" > $WIFI_CONF_PATH
    fi
    
    echo "miio_ssid_conf: $miio_ssid_conf"
	if [ x"$miio_ssid_conf" = x ]; then
		echo "ssid=NONE"
	else
		echo "save miio_ssid_conf to $WIFI_SSID_CONF_PATH"
		echo "ssid_conf=$miio_ssid_conf" > $WIFI_SSID_CONF_PATH
	fi
	
    if [ x"$miio_ssid_5g" = x ]; then
		echo "ssid_5g=NONE"
    else
		echo "ssid_5g=\"$miio_ssid\"" > $WIFI_CONF_PATH
    fi

    if [ x"$miio_passwd" = x ]; then
		miio_key_mgmt="NONE"
    else
		miio_key_mgmt="WPA"
		echo "key_mgmt=$miio_key_mgmt" >> $WIFI_CONF_PATH
		echo "psk=\"$miio_passwd\"" >> $WIFI_CONF_PATH
    fi
	
    if [ x"$miio_passwd_5g" = x ]; then
    miio_key_mgmt_5g="NONE"
    else
    miio_key_mgmt_5g="WPA"
    echo "key_mgmt_5g=$miio_key_mgmt_5g" >> $WIFI_CONF_PATH
    echo "psk_5g=\"$miio_passwd\"" >> $WIFI_CONF_PATH
    fi

    if [ x$miio_uid = x ]; then
    echo "uid=NONE"
    else
        echo "uid=$miio_uid" >> $WIFI_CONF_PATH
        echo "$miio_uid" > $DEVICE_UID_PATH
    fi

    if [ x"$miio_country" = x ]; then
    echo "country=NONE"
    else
        echo "$miio_country" > $DEVICE_COUNTRY_PATH

    fi
}

clear_wifi_conf() {
	rm -f $WIFI_CONF_PATH
	rm -f $DEVICE_UID_PATH
	rm -f $DEVICE_COUNTRY_PATH
	rm -f $DEVICE_BIND_STATUS_PATH
	rm -f $WIFI_SSID_CONF_PATH
}

save_tz_conf() {
	new_tz=$YOUR_TIMEZONE_DIR/$1
	echo $new_tz
	if [ -f $new_tz ]; then
		unlink $YOUR_LINK_TIMEZONE_FILE
		ln -sf  $new_tz $YOUR_LINK_TIMEZONE_FILE
		echo "timezone set success:$new_tz"
	else
		echo "timezone is not exist:$new_tz"
	fi
}

sanity_check() {
    if [ ! -e $WIFI_START_SCRIPT ]; then
	echo "Can't find wifi_start.sh: $WIFI_START_SCRIPT"
	echo 'Please change $WIFI_START_SCRIPT'
	exit 1
    fi
}

wifi_reassociate()
{
    echo "wifi_reassociate"
    # newwork_id=`wpa_cli -i $ifname list_network | grep $ssid | cut -f 1`
    # wpa_cli -i $ifname set_network $newwork_id bssid $1
    # wpa_cli -i $ifname disable_network $newwork_id
    # wpa_cli -i $ifname enable_network $newwork_id
} 


wifi_choose()
{
	reassociate_status="best bssid already connected" 
}

wifi_reload()
{
    ifconfig $ifname down
    ifconfig $ifname up
    sleep 2
}

wifi_reconnect()
{
	echo "wifi_reconnect start"
	echo 1 > ${WIFI_RECONNECT_CONF_PATH}
	while true; do
		if [ -e $WIFI_RECONNECT_CONF_PATH ];then
			usleep 10000
		else
		 break
		fi 	
	done
}

hidden_update()
{
	_ssid=$1
	_bssid=$2
	echo "hidden_update _ssid $_ssid"
	echo "hidden_update _bssid $_bssid"
	rm -rf /tmp/wpa_supplicant.conf
	cat <<EOF > $WPA_SUPPLICANT_CONFIG_FILE
ctrl_interface=/var/run/wpa_supplicant
update_config=1
network={
	ssid="$_ssid"
	bssid=$_bssid
	key_mgmt=NONE
	scan_ssid=1
}
EOF

}


curSSIDCompare()
{
	CUR_STRING=`wpa_cli -i wlan0 status`
	CUR_STAT=${CUR_STRING##*wtate=}
	CUR_STAT=`echo ${CUR_STAT} | cut -d ' ' -f 1`
	CUR_SSID=${CUR_STRING##*ssid=}
	CUR_SSID=`echo ${CUR_SSID} | cut -d ' ' -f 1`

	echo "CurSSID CUR_SSID $CUR_SSID  CUR_STAT ${CUR_STAT}"
	if [ x"$CUR_SSID" = x"$MIIO_NET_PROVISIONER_SSID" ]; then
		wifi_reconnect
		echo "CurSSID CUR_SSID $CUR_SSID  need to wifi_reconnect"
	fi
}


main() {
    while true; do
	BUF=`$MIIO_RECV_LINE`
	if [ $? -ne 0 ]; then
	    sleep 1;
	    continue
	fi
	if contains "$BUF" "_internal.info"; then
	    STRING=`wpa_cli -i wlan0 status`
	    ifname=wlan0
	    echo "ifname: $ifname"

		if [ -e $WIFI_SSID_CONF_PATH ]; then
			STRING_SSID_CONFIG=`cat $WIFI_SSID_CONF_PATH | grep -v ^#`
			echo "STRING_SSID_CONFIG: $STRING_SSID_CONFIG"
			ssid=${STRING_SSID_CONFIG##*ssid_conf=}
		else
			if [ -e $WIFI_CONF_PATH ]; then
				STRING_CONFIG=`cat $WIFI_CONF_PATH | grep -v ^#`
				ssid=${STRING_CONFIG##*ssid=\"}
				ssid=${ssid%%\"*}
				ssid=$(echo "${ssid}" | sed -e 's/\\/\\\\/g')
				ssid=$(echo "${ssid}" | sed -e 's/\//\\\//g')
				ssid=$(echo "${ssid}" | sed -e 's/\\"/\"/g')
			fi
		fi 
		
		echo "ssid: $ssid"

	    bssid=${STRING##*bssid=}
	    bssid=`echo ${bssid} | cut -d ' ' -f 1 | tr '[:lower:]' '[:upper:]'`
	    if [ x"$bssid" = x"SELECTED" ]; then
	   	bssid=
	    fi
	    echo "bssid: $bssid"

	    freq=${STRING##*freq=}
	    freq=`echo ${freq} | cut -d ' ' -f 1`
	    if [ x"$freq" = x"Selected" ]; then
		freq=0
	    fi
	    echo "freq: $freq"

		rssi=`iw dev wlan0 station get $bssid`
		rssi=${rssi#*signal:}
		rssi=`echo $rssi | cut -d ' ' -f 1`
		if [ "x$rssi" = "x" ]; then
			rssi=0
		fi
		echo "rssi: $rssi"
	    ip=${STRING##*ip_address=}
	    ip=`echo ${ip} | cut -d ' ' -f 1`
	    if [ x"$ip" = x"Selected" ]; then
		ip=
	    fi
	    echo "ip: $ip"

	    STRING=`ifconfig ${ifname}`

	    netmask=${STRING##*Mask:}
	    netmask=`echo ${netmask} | cut -d ' ' -f 1`
	    if [ x"$netmask" = x"wlan0" ]; then
	    	netmask=
	    fi
	    echo "netmask: $netmask"

	    gw=`route -n|grep 'UG'|tr -s ' ' | cut -f 2 -d ' '`
	    echo "gw: $gw"

	    # get vendor and then version
        vendor=`grep "vendor" /etc/miio/device.conf | cut -f 2 -d '=' | tr '[:lower:]' '[:upper:]'`
	    sw_version=`grep "${vendor}_VERSION" /etc/miio/os-release | cut -f 2 -d '='`
	    if [ -z $sw_version ]; then
		sw_version="unknown"
	    fi
	    # sw_version="4.3.2_9999"

	    msg="{\"method\":\"_internal.info\",\"partner_id\":\"\",\"params\":{\
\"hw_ver\":\"Linux\",\"fw_ver\":\"$sw_version\",\"auto_ota\":false,\
\"ap\":{\
 \"ssid\":\"$ssid\",\"bssid\":\"$bssid\",\"rssi\":\"$rssi\",\"freq\":$freq\
},\
\"netif\":{\
 \"localIp\":\"$ip\",\"mask\":\"$netmask\",\"gw\":\"$gw\"\
}}}"

	    echo "$msg"
	    $MIIO_SEND_LINE "$msg"
	elif contains "$BUF" "_internal.req_wifi_conf_status"; then
	    echo "Got _internal.req_wifi_conf_status"
	    req_wifi_conf_status "$BUF"
	    echo $REQ_WIFI_CONF_STATUS_RESPONSE
	    $MIIO_SEND_LINE "$REQ_WIFI_CONF_STATUS_RESPONSE"
	elif contains "$BUF" "_internal.wifi_start"; then

		echo "$BUF"

        wificonf_dir2=${BUF##*\"datadir\":\"}
        wificonf_dir2=${wificonf_dir2%%\"*}
        wificonf_dir2=${wificonf_dir2//\\\//\/}
        wificonf_dir2=${wificonf_dir2%\/*}
        miio_ssid=${BUF##*\"ssid\":\"}
        miio_ssid=${miio_ssid%%\",\"passwd\":\"*}
        miio_conf_ssid=$miio_ssid
        echo "miio_conf_ssid:$miio_conf_ssid"
        
        miio_ssid=$(echo "${miio_ssid}" | sed -e 's/\\\//\//g')
        miio_ssid=$(echo "${miio_ssid}" | sed -e 's/\\\\/\\/g')
        miio_ssid=$(echo "${miio_ssid}" | sed -e 's/\\"/\"/g')

        miio_passwd=${BUF##*\",\"passwd\":\"}
        has_5g=$(echo $BUF | grep "ssid_5g")
				has_wifi=$(echo $BUF | grep "wifi_config")
				has_bssid=$(echo $BUF | grep "bssid")
        if [ -n "$has_5g" ]; then
            miio_passwd=${miio_passwd%%\",\"ssid_5g\":\"*}
        elif [ -n "$has_bssid" ]; then
            miio_passwd=${miio_passwd%%\",\"bssid\":*}
        elif [ -n "$has_wifi" ]; then
            miio_passwd=${miio_passwd%%\",\"wifi_config\":*}        		
        else
            miio_passwd=${miio_passwd%%\",\"uid\":\"*}
        fi
        miio_passwd=$(echo "${miio_passwd}" | sed -e 's/\\\//\//g')
        miio_passwd=$(echo "${miio_passwd}" | sed -e 's/\\\\/\\/g')
        # miio_passwd=$(echo "${miio_passwd}" | sed -e 's/\$\$/g')
        
        if [ -n "$has_bssid" ]; then
			miio_bssid=${BUF##*\"bssid\":\"}
			miio_bssid=${miio_bssid%%\",\"uid\":\"*}
			miio_bssid=`echo ${miio_bssid} | cut -d ' ' -f 1 | tr '[:lower:]' '[:upper:]'`
			miio_bssid=${miio_bssid%%\"*}
        fi

        miio_uid=${BUF##*\"uid\":\"}
        miio_uid=${miio_uid%%\",\"country_domain\":\"*}
				miio_uid=$(echo "${miio_uid}" | sed -e 's/\\\//\//g')
        miio_uid=$(echo "${miio_uid}" | sed -e 's/\\\\/\\/g')
        miio_country=${BUF##*\",\"country_domain\":\"}
        miio_country=${miio_country%%\",\"tz\":\"*}
        
        miio_tz=${BUF##*\",\"tz\":\"}    
        miio_tz=${miio_tz//\\}
        miio_tz=${miio_tz%%\"*}        

        echo "wificonf_dir: $wificonf_dir2"
        echo "miio_ssid: $miio_ssid"
        echo "miio_uid: $miio_uid"
        echo "miio_passwd: $miio_passwd"
        echo "miio_country: $miio_country"
        echo "miio_tz: $miio_tz"
        if [ -n "$has_bssid" ]; then
        echo "miio_bssid: $miio_bssid"
        fi
        
		
		if [ x"$miio_ssid" != x"$MIIO_NET_PROVISIONER_SSID" ] && [ x"$miio_ssid_5g" != x"$MIIO_NET_PROVISIONER_SSID" ]; then
            if [ ! -f "/etc/miio/wifi.conf" ];then
                echo "recv app config info connect start"
                rm -f $WIFI_SSID_CONF_PATH
                save_wifi_conf "$wificonf_dir2" "$miio_ssid" "$miio_passwd" "$miio_uid" "$miio_country" "$miio_conf_ssid"
                save_tz_conf "$miio_tz"
            else
                echo "wifi change passwd need to reconnect"
                # 读取 /etc/miio/wifi.conf，有不同再写
                file_ssid=$(grep "ssid=" /etc/miio/wifi.conf | awk -F "[\"\"]" '{print $2}')
                fild_psk=$(grep "psk=" /etc/miio/wifi.conf | awk -F "[\"\"]" '{print $2}')
                fild_uid=$(grep "uid=" /etc/miio/wifi.conf | awk -F "[=]" '{print $2}')
                file_new=false
					
                
                if [ x"$file_ssid" != x ]; then
                    if [ x"$file_ssid" != x"$miio_ssid" ]; then
                        file_new=true
                    fi
                fi
                if [ x"$fild_psk" != x ]; then
                    if [ x"$fild_psk" != x"$miio_passwd" ]; then
                        file_new=true
                    fi
                fi
                if [ x"$miio_uid" != x ]; then
                    if [ x"$fild_uid" != x ]; then
                        if [ x"$fild_uid" != x"$miio_uid" ]; then
                            file_new=true
                        fi
                    fi
                fi

                if [ x$file_new = xtrue ]; then
                      rm -f $WIFI_SSID_CONF_PATH
                      save_wifi_conf "$wificonf_dir2" "$miio_ssid" "$miio_passwd" "$miio_uid" "$miio_country" "$miio_conf_ssid"
                      save_tz_conf "$miio_tz"
                      wifi_reconnect
		else
		     if [ x"$MIIO_AP_MODE" = xtrue ]; then
			 file_new=true
			 MIIO_AP_MODE=false
			 wifi_reconnect
			 echo "mode change need to reconnect"
		     else
			curSSIDCompare
		     fi					
                fi
            fi
        fi

		CMD=$WIFI_START_SCRIPT
		RETRY=1
		WIFI_SUCC=1
		if [ x"$miio_ssid" = x"$MIIO_NET_PROVISIONER_SSID" ]; then
			RETRY=1
			WIFI_MAX_RETRY=3
			MIIO_AP_MODE=true
			until [ $RETRY -gt $WIFI_MAX_RETRY ]
			do
				echo "${CMD} SELECT_HIDDEN"
				hidden_update "$miio_ssid" "$miio_bssid"
				echo 1 > ${WIFI_SELECT_HIDDEN_CONF_PATH}
				while true; do
					if [ -e $WIFI_SELECT_HIDDEN_CONF_PATH ];then
						usleep 10000
					else
					 break
					fi 	
				done
				
				_RETRY=1
				until [ $_RETRY -gt 10 ]
				do
					`wpa_cli -iwlan0 status | grep -q "wpa_state=COMPLETED"`
					if [ $? -e 0 ] ; then
						echo "COMPLETED"
						break
					fi	
					let _RETRY=$_RETRY+1
					sleep 1
				done
				
				`wpa_cli -iwlan0 status | grep -q "wpa_state=COMPLETED"`
				if [ $? -ne 0 ] ; then
						WIFI_SUCC=1
				else
					STRING=`wpa_cli -iwlan0 status`
					bssid=${STRING##*bssid=}
					bssid=`echo ${bssid} | cut -d ' ' -f 1 | tr '[:lower:]' '[:upper:]'`
					rm /tmp/wifi_disable_check_status -rf
					RESPONSE_WIFI_START="{\"method\":\"_internal.wifi_connected\",\"params\":{\"ssid\":\"$MIIO_NET_PROVISIONER_SSID\",\"bssid\":\"$bssid\",\"result\":\"ok\"}}"
					echo $RESPONSE_WIFI_START
					$MIIO_SEND_LINE "$RESPONSE_WIFI_START"
					
					break	
				fi
				
				let RETRY=$RETRY+1
				sleep $WIFI_RETRY_INTERVAL
			done				
		else
			RETRY=1
			WIFI_MAX_RETRY=10
			MIIO_AP_MODE=false
			until [ $RETRY -gt $WIFI_MAX_RETRY ]
			do
				if [ -f "/tmp/wifi_ap_config" ];then
					echo "check /tmp/wifi_ap_config"
					rm -rf /tmp/wifi_ap_config
					STRING=`wpa_cli -iwlan0 status`
					bssid=${STRING##*bssid=}
					bssid=`echo ${bssid} | cut -d ' ' -f 1 | tr '[:lower:]' '[:upper:]'`
					RESPONSE_WIFI_START="{\"method\":\"_internal.wifi_connected\",\"params\":{\"ssid\":\"$miio_conf_ssid\",\"bssid\":\"$bssid\",\"result\":\"ok\"}}"
					rm /tmp/wifi_disable_check_status -rf
					echo $RESPONSE_WIFI_START
					$MIIO_SEND_LINE "$RESPONSE_WIFI_START"					
					break
				else
					echo "will check waite net connnect ok"
				fi

				let RETRY=$RETRY+1
				sleep $WIFI_RETRY_INTERVAL
			done
		fi
		
		rm /tmp/wifi_disable_check_status -rf
		
	elif contains "$BUF" "_internal.wifi_reconnect"; then
	    echo "Got _internal.wifi_reconnect"
	    rm /tmp/wifi_disable_check_status -rf
		wifi_reconnect
	elif contains "$BUF" "_internal.wifi_reload"; then
	    echo "Got _internal.wifi_reload"
	    wifi_reload 
	    wifi_choose
	    REQ_WIFI_RELOAD_RESPONSE="{\"method\":\"_internal.res_wifi_reload\",\"params\":{\"wifi_reload_result\":\"$reassociate_status\",\
\"bssid\":\"$bbssid\"}}"
	    echo $REQ_WIFI_RELOAD_RESPONSE
	    $MIIO_SEND_LINE "$REQ_WIFI_RELOAD_RESPONSE"
	elif contains "$BUF" "_internal.wifi_disconnect_req"; then
	    echo "Got _internal.wifi_disconnect_req"
		MIIO_AP_MODE=false
	    request_disconnect_wifi "$BUF"
	elif contains "$BUF" "_internal.request_dinfo"; then
	    echo "Got _internal.request_dinfo"
	    request_dinfo "$BUF"
	    echo $RESPONSE_DINFO
	    $MIIO_SEND_LINE "$RESPONSE_DINFO"
	elif contains "$BUF" "_internal.request_dtoken"; then
	    echo "Got _internal.request_dtoken"
	    request_dtoken "$BUF"
	    echo $RESPONSE_DCOUNTRY
	    $MIIO_SEND_LINE "$RESPONSE_DCOUNTRY"
	    echo $RESPONSE_OFFLINE
	    $MIIO_SEND_LINE "$RESPONSE_OFFLINE"
	    # echo $RESPONSE_DTOKEN
	    $MIIO_SEND_LINE "$RESPONSE_DTOKEN"
	elif contains "$BUF" "_internal.request_ot_config"; then
	    echo "Got _internal.request_ot_config"
	    request_ot_config "$BUF"
	    echo $RESPONSE_OT_CONFIG
	    $MIIO_SEND_LINE "$RESPONSE_OT_CONFIG"
	elif contains "$BUF" "_internal.update_dtoken"; then
	    update_dtoken "$BUF"
	    $MIIO_SEND_LINE "$RESPONSE_UPDATE_TOKEN"
	elif contains "$BUF" "_internal.config_tz"; then
	    echo "Got _internal.config_tz"
		miio_tz=${BUF##*\",\"tz\":\"}    
        miio_tz=${miio_tz//\\}
        miio_tz=${miio_tz%%\"*} 
	    save_tz_conf "$miio_tz"
	else
	    echo "Unknown cmd: $BUF"
	fi
    done
}

sanity_check
send_helper_ready
main
