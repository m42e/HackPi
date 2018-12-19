#!/bin/sh
#
# HackPi
#  by wismna
#  http://github.com/wismna/raspberry-pi/hackpi
#  14/01/2017
#

cd /sys/kernel/config/usb_gadget/
mkdir -p hackpi
cd hackpi

OS=`cat /home/pi/os.txt`
HOST="48:6f:73:74:50:43"
SELF0="42:61:64:55:53:42"
SELF1="42:61:64:55:53:43"
SERIALNMBR=$(cat /proc/cpuinfo | grep ^Serial | cut -d":" -f2)

echo 0x04b3 > idVendor
echo 0x4010 > idProduct

echo 0x0100 > bcdDevice # v1.0.0
mkdir -p strings/0x409

echo $SERIALNMBR > strings/0x409/serialnumber
echo "m42e" > strings/0x409/manufacturer
echo "PiZero" > strings/0x409/product

if [ "$OS" != "MacOs" ]; then
	# Config 1: RNDIS
	mkdir -p configs/c.1/strings/0x409
	echo "0x80" > configs/c.1/bmAttributes
	echo 250 > configs/c.1/MaxPower
	echo "Config 1: RNDIS network" > configs/c.1/strings/0x409/configuration

	echo "1" > os_desc/use
	echo "0xcd" > os_desc/b_vendor_code
	echo "MSFT100" > os_desc/qw_sign

	mkdir -p functions/rndis.usb0
	echo $SELF0 > functions/rndis.usb0/dev_addr
	echo $HOST > functions/rndis.usb0/host_addr
	echo "RNDIS" > functions/rndis.usb0/os_desc/interface.rndis/compatible_id
	echo "5162001" > functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id
fi

# Config 2: CDC ECM
mkdir -p configs/c.2/strings/0x409
echo "Config 2: ECM network" > configs/c.2/strings/0x409/configuration
echo 250 > configs/c.2/MaxPower

mkdir -p functions/ecm.usb0
# first byte of address must be even
echo $HOST > functions/ecm.usb0/host_addr
echo $SELF1 > functions/ecm.usb0/dev_addr

# Create the CDC ACM function
mkdir -p functions/acm.gs0

# Link everything and bind the USB device
if [ "$OS" != "MacOs" ]; then
	ln -s configs/c.1 os_desc
	ln -s functions/rndis.usb0 configs/c.1
fi

ln -s functions/ecm.usb0 configs/c.2
ln -s functions/acm.gs0 configs/c.2
# End functions
ls /sys/class/udc > UDC
