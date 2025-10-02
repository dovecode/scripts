files="$(find -L . -type f -name \*.sha256)"
echo "Count: $(echo -n "$files" | wc -l)"
echo "$files" | while read shafile; do

        #echo Fixing ${shafile}

        # sed chain explained:
        #       1. Get rid of double spaced (an earlier version of the script inserted double spaced in the file names!)
        #       2. Get rid of any directory names from the file name
        #       3. Ensure that there are always two spaces between checksum and file name
        newsha="$(cat "${shafile}" | sed 's/  / /' | sed 's#\([0-9a-f]*\).*/\([^/]*\)#\1 *\2#' | sed 's/\([0-9a-f]*\)[ *]*\([^*]*\)/\1  \2/')"

        echo "${newsha}">"${shafile}"

        mkvfile="${shafile%.sha256}"
        mkvname="${mkvfile##*/}"
        result="$(grep "${mkvname}" "${shafile}")"
        if [ $? != 0 ]; then
                echo ${shafile} does not contain sum for ${mkvname}!
        fi


done

