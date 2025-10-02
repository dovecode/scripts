targetUser="nicolai"
targetServer="bananas"
targetScriptDir="/volume1/homes/nicolai/scripts/movies/"
targetMediaDir="/volume1/video/"
rsync_params="-v -aP --size-only --chmod=ug+rwX,o=rX,Dg+s"
caffeine="/mnt/c/Tools/Caffeine/Caffeine.exe"
caffeine_start="${caffeine} -replace -useshift &"
caffeine_exit="${caffeine} -appexit"

if [[ ! -f ${caffeine} ]]; then
	echo "${caffeine} not found"
	exit -1
fi

if [ "$1" == "-n" ]; then
	rsync_params="${rsync_params} --dry-run"
fi

synchronize() {
	local num=$#
	local count=$#
	local src="$1"
	while [ $count -gt 2 ]; do
		shift
		src="$src $1"
		let count=count-1
	done
	local dst="$2"

	echo "Synchronizing $src to ${targetUser}@${targetServer}:$dst..."
	if [ $num -gt 2 ]; then
		rsync ${rsync_params} $src ${targetUser}@${targetServer}:"$dst" 2>&1 |tee -a "${log}"
	else
		rsync ${rsync_params} "$src" ${targetUser}@${targetServer}:"$dst" 2>&1 |tee -a "${log}"
	fi
}

${caffeine_start} &
log=${0%.*}.log
echo ========================================================== |tee -a "${log}"
date |tee -a "${log}"

synchronize *.sh "${targetScriptDir}"

for dir in Movies "TV Shows"; do
        if [ -d "${dir}" ]; then
                synchronize "${dir}" "${targetMediaDir}"
        fi
done

echo ========================================================== |tee -a "${log}"

${caffeine_exit} &

if [ "$1" == "pause" ]; then
        echo Press Enter to close
        read
fi

