
scriptdir=.
scripts="reorg.sh mkshasum.sh syncFromDufva.sh remotecheck.sh"

for script in $scripts; do
	${scriptdir}/${script}
done
