#!/bin/sh

echo 0 > /sys/class/rfkill/rfkill0/state
sleep 2
echo 1 > /sys/class/rfkill/rfkill0/state
sleep 2

brcm_patchram_plus1 --bd_addr_rand --enable_hci --no2bytes --use_baudrate_for_download  --tosleep  200000 --baudrate 1500000 --patchram  /system/etc/firmware/BCM4343B0.hcd /dev/ttyS1 &
hciconfig hci0 up
