/cygdrive/c/tools/caffeine/caffeine -replace &
LOG=${0%.*}.log
echo ========================================================== |tee -a "${LOG}"
date |tee -a "${LOG}"
rsync -aP --size-only --no-perms *.sh nicolai@dufvaduobook:"/shares/Public/DufvaScripts/" 2>&1 |tee -a "${LOG}"
rsync -aP --size-only --no-perms Movies nicolai@dufvaduobook:"/shares/Public/Shared\ Videos/" 2>&1 |tee -a "${LOG}"
rsync -aP --size-only --no-perms "TV Shows" nicolai@dufvaduobook:"/shares/Public/Shared\ Videos/" 2>&1 |tee -a "${LOG}"
echo ========================================================== |tee -a "${LOG}"

/cygdrive/c/tools/caffeine/caffeine -appexit &

if [ "$1" == "pause" ]; then
	echo Press Enter to close
	read
fi
