sync
lsblk -I 8 -l
mountroot="/mnt/usb"

function runtest() {
        device=$1
        mountpoint=${mountroot}/${device}

        umount ${mountroot}>/dev/null
        umount ${mountpoint}>/dev/null
        mkdir -p ${mountpoint}
        chmod -R 777 ${mountroot}
        mount ${device} ${mountpoint}
        f3write ${mountpoint}
        f3read ${mountpoint}
        umount ${mountpoint}>/dev/null
}

function recreate() {
        device=$1
        umount ${device}1>/dev/null

        sfdisk --delete ${device}
        echo "type=c"|sfdisk ${device}
        mkfs.vfat -F 32 -n USBTEST ${device}1
}

read -p "Enter name of device to test (e.g. 'sda')? " -r
echo    # (optional) move to a new line
if [[ ! -z "$REPLY" ]]; then
        devicename="${REPLY}"
        device="/dev/${devicename}"
        if [[ -b ${device} ]]; then
                echo "Will test ${device}"

                if [[ -b ${device}1 ]]; then
                        echo "Testing existing partition ${device}1"
                        #runtest ${device}1
                fi
                echo "Recreating and testing ${device}1..."
                recreate ${device}
                runtest ${device}1
        else
                echo "${device} is not a block device"
        fi
else
        echo "Aborting..."
fi

