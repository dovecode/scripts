#!/usr/bin/env bash

# Get the path to the directory this script is in.
FULL_PATH_TO_SCRIPT="$(realpath "${BASH_SOURCE[-1]}")"
SCRIPT_DIRECTORY="$(dirname "$FULL_PATH_TO_SCRIPT")"

# Now, source shared libraries
. "$SCRIPT_DIRECTORY/util-progress.sh"
. "$SCRIPT_DIRECTORY/util-videos.sh"

root="${PWD}"
mastershafile="${root}/sha256sum.txt"

extension_list=
for extension in "${video_extensions[@]}"; do

	expression="${extension}"

	if [ -z "${extension_list}" ]; then
		extension_list="${expression}"
	else
		extension_list="${extension_list}\|${expression}"
	fi
done

# change "set +x" to "set -x" to output full command
files="$(set +x; find -L "${directories[@]}" -type f -iregex ".*\.\(${extension_list}\)$")"

totalfiles="$(echo "$files" | wc -l)"

echo "${totalfiles} files to check on host ${HOSTNAME}"

if [ $totalfiles -gt 0 ]; then
	typeset -i processedfiles=0
	echo "$files" | while read mkvfile; do
		
		if [ -z "${mkvfile}" ]; then
			echo "No files"
		else
		
			let "processedfiles+=1"
	        progress-bar "${processedfiles}" "${totalfiles}"

			mkvpath="${mkvfile%/*}"
			mkvname="${mkvfile##*/}"

			if [ -f "${mkvfile}" ]; then
				cd "${mkvpath}"
					
				shafile=${mkvname}.sha256
				sha256=
			
				if [ -f "${shafile}" ]; then
					echo -e "${COLOR_GRAY}Skipping ${mkvname} - sha256 file found...${COLOR_NONE}"
				else
					
					if [ -f "${mastershafile}" ]; then
						echo "No ${shafile}, checking ${mastershafile}..."
						sha256=`grep -e "${mkvname}$" ${mastershafile}`
					fi
					
					if [ ! -z "${sha256}" ]; then
						echo "Using the one found in ${mastershafile}..."
					else
						echo "No checksum found, generating one for ${mkvname}..."
						sha256=`sha256sum "${mkvname}"`
					fi
					
					echo "${sha256}">"${shafile}"
				fi
				
				cd "${root}"
			else
				echo -e "${COLOR_RED}${mkvname} No longer exists!${COLOR_NONE}"
			fi

		
		fi
		
	done
else
	echo No files found!
fi
