nh=$1
nh_value="--nh"

if [ "$nh" = "$nh_value" ]; then
        shift
fi

device=$1
shift
patterns="$*"
timescode="$(date +%Y%m%d-%H%M%S)"
timestamp="$(date +%Y-%m-%d\ %H:%M:%S)"

print_help() {
        echo "Usage:"
        echo "  $0 <device> <patterns>"
        echo "Where:"
        echo "  <device> is the device name (without the /dev/ prefix), e.g. 'sda'"
        echo "  <patterns> is a space-delimited list of hex patterns, e.g. '00 55 aa'"
        echo "Example:"
        echo "  $0 sdb aa 55 ff 00"
}

if [ -z $device ]; then
        echo "Missing device name"
        print_help
        exit
fi

logfile="badblocks.$device.log"
pidfile="badblocks.$device.pid"

device_name="/dev/$device"

if [ ! -b $device_name ]; then
        echo "Device $device_name not found"
        print_help
        exit
fi

if [ -z "$patterns" ]; then
        echo "Missing patterns"
        print_help
        exit
fi

echo "Will test $device_name with patterns $patterns. Follow the progress in $logfile..."


if [ "$nh" = "$nh_value" ]; then
        echo "$timestamp - Starting test with patterns $patterns"
        for pattern in $patterns; do
                badblocks -wsv -b 4096 $device_name -t 0x$pattern
        done
else
        nohup $0 $nh_value $device $patterns>>$logfile 2>&1 & echo $! >$pidfile
        echo "New process ID ($(cat $pidfile)) can be found in $pidfile"
fi

