#!/bin/sh
if [ -d "/root/.ssh" ];then
	if [ ! -d "/userdata/.ssh" ];then
		mkdir -p /userdata/.ssh
	fi
	mount /userdata/.ssh /root/.ssh
	if [ ! -f "/root/.ssh/id_rsa" ];then
		ssh-keygen -t rsa -P "" -f /root/.ssh/id_rsa
	fi
fi

if [ -f "/oem/bin/robotClient" ];then
	echo "start robotClient ..."
	/oem/bin/robotClient > /dev/null &
fi

