#!/bin/sh

DIR=$(dirname $0)

GPIO_USB_SW=17
GPIO_1806_RESET_L=67
GPIO_1806_LOG_EN=113
GPIO_1806_0V8_EN=114
GPIO_1806_CPU_EN=115
GPIO_1806_1V8_EN=116
GPIO_1806_DDR_EN=117
GPIO_1806_3V3_EN=118
GPIO_1806_5V_EN=120

exportGpio()
{
	if [ ! -d "/sys/class/gpio/gpio$1" ];then
		echo $1 > /sys/class/gpio/export
		echo out > /sys/class/gpio/gpio$1/direction
	fi
}

gpioSet()
{
	echo 1 > /sys/class/gpio/gpio$1/value
}

gpioClr()
{
	echo 0 > /sys/class/gpio/gpio$1/value
}

gpioInit()
{
	echo "gpioInit..."
	exportGpio ${GPIO_1806_5V_EN}
	exportGpio ${GPIO_1806_LOG_EN}
	exportGpio ${GPIO_1806_CPU_EN}
	exportGpio ${GPIO_1806_0V8_EN}
	exportGpio ${GPIO_1806_1V8_EN}
	exportGpio ${GPIO_1806_DDR_EN}
	exportGpio ${GPIO_1806_3V3_EN}
	exportGpio ${GPIO_1806_RESET_L}
	exportGpio ${GPIO_USB_SW}
}

rk1806PowerOn()
{
	echo "rk1806PowerOn..."
	echo host > /sys/devices/platform/ff2c0000.syscon/ff2c0000.syscon:usb2-phy@100/otg_mode

	gpioSet ${GPIO_USB_SW}

	gpioClr ${GPIO_1806_RESET_L}
	gpioSet ${GPIO_1806_5V_EN}
	usleep 2000
	gpioSet ${GPIO_1806_LOG_EN}
	gpioSet ${GPIO_1806_CPU_EN}
	usleep 1000 #LOG and CPU bump up(0v -> ~1v) need 0.5ms
	gpioSet ${GPIO_1806_0V8_EN}
	usleep 2000
	gpioSet ${GPIO_1806_DDR_EN} # DDR shall not late than 1V8
	usleep 1000
	gpioSet ${GPIO_1806_1V8_EN}
	usleep 2000
	gpioSet ${GPIO_1806_3V3_EN} # Make 3V3 after 1V8, about 2ms
	usleep 15000
	gpioSet ${GPIO_1806_RESET_L}

	echo "Wait for maskrom device..."
	count=0
	while [ $count -lt 100 ]; do
		lsusb | grep 2207 && return
		sleep .1
                let i++
	done

	echo "No maskrom found, exit"
	exit -1
}

rk1806PowerOff()
{
	echo "rk1806PowerOff..."

	# TODO: Send poweroff cmd to RK1806, cut off power after RK1806 shutdown

	gpioClr ${GPIO_USB_SW}
	gpioClr ${GPIO_1806_5V_EN}
	gpioClr ${GPIO_1806_LOG_EN}
	gpioClr ${GPIO_1806_CPU_EN}
	gpioClr ${GPIO_1806_0V8_EN}
	gpioClr ${GPIO_1806_1V8_EN}
	gpioClr ${GPIO_1806_DDR_EN}
	gpioClr ${GPIO_1806_3V3_EN}
}

appStart()
{
	echo "appStart..."
	$DIR/npu_upgrade $DIR/rknpu_lion_loader_v1.04.103.bin $DIR/uboot.img $DIR/trust.img $DIR/ramboot.img
}

if [[ "$1" = "usb3326" ]]; then
	echo "set usb otg3326"	
	gpioClr ${GPIO_USB_SW}
	echo otg > /sys/devices/platform/ff2c0000.syscon/ff2c0000.syscon:usb2-phy@100/otg_mode
elif [[ "$1" = "usb1806" ]]; then
	echo "set usb 3326-1806"
	gpioSet ${GPIO_USB_SW}
	echo host > /sys/devices/platform/ff2c0000.syscon/ff2c0000.syscon:usb2-phy@100/otg_mode
elif [[ "$1" = "1806Off" ]]; then
	gpioInit
	rk1806PowerOff
elif [[ "$1" = "1806On" ]]; then
	gpioInit
	rk1806PowerOn
elif [[ "$1" = "appStart" ]]; then
	appStart
elif [[ "$1" = "auto" ]]; then
	gpioInit
	rk1806PowerOn
	appStart
elif [[ "$1" = "help" ]]; then
	echo "$0 [1806Off|1806On|appStart|usb3326|usb1806]"
else
	killall robotClient
	/oem/bin/robotClient > /dev/null &
	gpioInit
	rk1806PowerOff
	rk1806PowerOn
	appStart
fi
