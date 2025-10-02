root_dir="./TV Shows"

old_show_name="$1"
new_show_name="$2"

if [ -z "$new_show_name" ]; then
	echo "Usage: $0 <old_show_name> <new_show_name>"
	exit 1
fi

declare -a video_extensions=('mkv' 'avi' 'flv' 'mp4' 'webm' 'mpg')
extension_list=
for extension in ${video_extensions[@]}; do

	expression="${extension}"

	if [ -z "${extension_list}" ]; then
		extension_list="${expression}"
	else
		extension_list="${extension_list}\|${expression}"
	fi
done

run_command="echo "
run_command=


# first, find all directories with a TV show named ${old_show_name}
dirs="$(set +x; find -L "${root_dir}" -type d \( -name "${old_show_name}" \))"

totaldirs="$(echo "$dirs" | wc -l)"

if [ $totaldirs -gt 0 ]; then
	typeset -i processeddirs=0
	echo "$dirs" | while read olddir; do
		if [ -z "${olddir}" ]; then
			echo "No shows matching ${old_show_name} found."
			continue
		fi

		newdir="${olddir//${old_show_name}/${new_show_name}}"
		if [ -d "$newdir" ]; then
			echo "Directory $newdir already exists, skipping rename."
			continue
		else
			# find all episodes in the show directory and rename them
			episodes="$(set +x; find -L "${olddir}" -type f -type f -name "${old_show_name}.*" -iregex ".*\.\(${extension_list}\)$")"
			if [ -n "$episodes" ]; then
				echo "$episodes" | while read oldepisode; do
					if [ -z "${oldepisode}" ]; then
						echo "No episodes found in ${olddir}."
						continue
					fi

					echo "Processing episode: $oldepisode"
					oldepisode_dir="$(dirname "${oldepisode}")"
					oldepisode_name="$(basename "${oldepisode}")"
					newepisode_name="${new_show_name}${oldepisode_name#${old_show_name}}"
					newepisode="${oldepisode_dir}/${newepisode_name}"

					# oldepisode: "rootdir/NewName/Season 01/OldName.S01E01.ext"
					# newepisode: "rootdir/NewName/Season 01/NewName.S01E01.ext"

					if [ -f "${newepisode}" ]; then
						echo "File $newepisode already exists, skipping rename."
						continue
					else
						echo "Renaming: $oldepisode -> $newepisode"
						$run_command mv -n "$oldepisode" "$newepisode"
						if [ $? -ne 0 ]; then
							echo "Error renaming $oldepisode to $newepisode"
						else
							# If the old episode has a checksum file, rename it and update its name inside sha256 file
							if [ -f "${oldepisode}.sha256" ]; then
								echo "Renaming checksum file: ${oldepisode}.sha256 -> ${newepisode}.sha256"
								$run_command mv -n "${oldepisode}.sha256" "${newepisode}.sha256"
								if [ $? -ne 0 ]; then
									echo "Error renaming checksum file ${oldepisode}.sha256 to ${newepisode}.sha256"
								else
									echo "Updating name in checksum file for renamed episode: ${newepisode}.sha256"

									# file contents will be something like:
									# "d41d8cd98f00b204e9800998ecf8427e *OldName.S01E01.ext"
									# We will replace "OldName.S01E01.ext" with "NewName.S01E01.ext"
									# and also replace any asterisk (*) with a space (asterisk is added
									# by the sha256sum command if the file was executable when the checksum
									# was generated).

									$run_command sed -i "s|^\([a-z0-9]*\) [ *]${old_show_name}|\1  ${new_show_name}|g" "${newepisode}.sha256"
									if [ $? -ne 0 ]; then
										echo "Error updating checksum file ${newepisode}.sha256"
									fi

									echo "Renaming checksum logs if they exist"
									for log_file in "${oldepisode}.sha256."*; do
										oldlogfile_dir="$(dirname "${log_file}")"
										oldlogfile_name="$(basename "${log_file}")"
										newlogfile_name="${new_show_name}${oldlogfile_name#${old_show_name}}"
										newlogfile="${oldlogfile_dir}/${newlogfile_name}"
										if [ -f "${newlogfile}" ]; then
											echo "Log file $newlogfile already exists, skipping rename."
										else
											echo "Renaming log file: $log_file -> $newlogfile"
											$run_command mv -n "$log_file" "$newlogfile"
											if [ $? -ne 0 ]; then
												echo "Error renaming log file $log_file to $newlogfile"
											fi

											# file contents will be something like:
											# "OldName.S01E01.ext: OK"
											# We will replace "OldName.S01E01.ext" with "NewName.S01E01.ext"

											$run_command sed -i "s|^${old_show_name}|${new_show_name}|g" "${newlogfile}"
											if [ $? -ne 0 ]; then
												echo "Error updating checksum log file ${newlogfile}"
											fi

										fi
									done
								fi
							fi

						fi
					fi
				done
			fi

			echo "Renaming: $olddir -> $newdir"
			$run_command mv -n "$olddir" "$newdir"
			if [ $? -ne 0 ]; then
				echo "Error renaming $olddir to $newdir"
				continue
			fi
		fi
		processeddirs+=1
	done
fi

