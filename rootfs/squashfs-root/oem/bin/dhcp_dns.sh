#!/bin/sh

grep nameserver /tmp/resolv.conf
if [ $? == 0 ]; then
    echo "nameserver is ok" 
else
    echo "nameserver not set default dns"
    sed -i '3i nameserver 8.8.8.8' /tmp/resolv.conf    
fi

