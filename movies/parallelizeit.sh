#!/usr/bin/bash

scriptdir="."

# first off, reorg the files
${scriptdir}/reorg.sh

${scriptdir}/mkshasum.sh &
${scriptdir}/syncFromDufva.sh &

# Wait for both processes to complete...
failures=0
for job in $(jobs -p); do
	wait ${job} || let "failures+=1"
done

if [ "$failures" == "0" ]; then
	# run a final sync to ensure that all checksums were transferred
	${scriptdir}/syncFromDufva.sh

	# finally, check if everything was transferred fine
	${scriptdir}/remotecheck.sh
else
	echo "One or more failures detected!"
fi

