root_dir="${PWD}"

function fix_utf8_string {
	local file="$1"
	local newfile="$file"
	newfile="${newfile//Ã¦/æ}"	# Replace Ã¦ with æ
	newfile="${newfile//Ã¸/ø}"	# Replace Ã¸ with ø
	newfile="${newfile//Ã¥/å}"	# Replace Ã¥ with å
	newfile="${newfile//Ã/Æ}"	# Replace Ã with Æ
	newfile="${newfile//Ã/Ø}"	# Replace Ã with Ø
	newfile="${newfile//Ã/Å}"	# Replace Ã with Å
	newfile="${newfile//Ã¤/ä}"	# Replace Ã¤ with ä


	echo "${newfile}"
	# if [ "$file" != "$newfile" ]; then
	# 	mv -v "$file" "$newfile"
	# fi
}

echo "Searching for directories with UTF-8 issues in: ${root_dir}"

# first, find all directories with UTF-8 issues
dirs="$(set +x; find -L "${root_dir}" -type d \( -name '*Ã*' \))"

totaldirs="$(echo "$dirs" | wc -l)"

if [ $totaldirs -gt 0 ]; then
	typeset -i processeddirs=0
	echo "$dirs" | while read olddir; do
		if [ -z "${olddir}" ]; then
			echo "No directories with UTF-8 issues found."
			continue
		fi
		# Perform your processing here
		newdir="$(fix_utf8_string "$olddir")"
		if [ "$olddir" != "$newdir" ]; then
			# Check if the new directory name already exists
			if [ -d "$newdir" ]; then
				echo "Directory $newdir already exists, skipping rename."
				continue
			fi

			echo "Renaming: $olddir -> $newdir"
			mv -n "$olddir" "$newdir"
			if [ $? -ne 0 ]; then
				echo "Error renaming $olddir to $newdir"
			fi
		else
			echo "No change needed for: $olddir"
		fi
		processeddirs+=1
	done
fi

echo "Processed $processeddirs directories with UTF-8 issues."

# Now, find all files with UTF-8 issues
files="$(set +x; find -L "${root_dir}" -type f \( -name '*Ã*' \))"
totalfiles="$(echo "$files" | wc -l)"

if [ $totalfiles -gt 0 ]; then
	typeset -i processedfiles=0
	echo "$files" | while read oldfile; do
		if [ -z "${oldfile}" ]; then
			echo "No files with UTF-8 issues found."
			continue
		fi
		# Perform your processing here
		newfile="$(fix_utf8_string "$oldfile")"
		if [ "$oldfile" != "$newfile" ]; then
			# Check if the new file name already exists
			if [ -e "$newfile" ]; then
				echo "File $newfile already exists, skipping rename."
				continue
			fi

			echo "Renaming: $oldfile -> $newfile"
			mv -n "$oldfile" "$newfile"
			if [ $? -ne 0 ]; then
				echo "Error renaming $oldfile to $newfile"
			else
				echo "Successfully renamed: $oldfile -> $newfile"

				# If the old file has a checksum file, update its name inside sha256 file
				if [ -f "${oldfile}.sha256" ]; then
					echo "Updating name in checksum file for renamed file: ${newfile}.sha256"
					sed -i "s|${oldfile}|${newfile}|g" "${oldfile}.sha256"
				fi

				# If the new file has a checksum file (we've already renamed it!), update its name inside sha256 file
				if [ -f "${newfile}.sha256" ]; then
					echo "Updating name in checksum file for renamed file: ${newfile}.sha256"
					sed -i "s|${oldfile}|${newfile}|g" "${newfile}.sha256"
				fi
			fi
		else
			echo "No change needed for: $oldfile"
		fi
		processedfiles+=1
	done
fi

echo "Processed $processedfiles files with UTF-8 issues."

# Find any already renamed sha256 files and update the embedded names
sha_files="$(set +x; find -L "${root_dir}" -type f -name '*.sha256')"
if [ -n "$sha_files" ]; then
	echo "Updating names in existing checksum files..."
	echo "$sha_files" | while read sha_file; do
		if [ -z "${sha_file}" ]; then
			continue
		fi
		# Extract the original file name from the checksum file
		original_file="$(basename "${sha_file}" .sha256)"
		# Check if the original file exists
		if [ -f "${sha_file}" ]; then
			# Read the checksum line
			checksum_line="$(cat "${sha_file}")"
			# Replace the original file name with the new file name
			new_checksum_line="$(fix_utf8_string "${checksum_line}")"
			# Write the updated checksum line back to the file
			echo "${new_checksum_line}" > "${sha_file}"
			echo "Updated checksum file: ${sha_file}"
		else
			echo "Original file for checksum ${sha_file} does not exist, skipping update."
		fi
	done
else
	echo "No checksum files found to update."
fi

