# this script will locate all files of the format "*.{resolutions}.{video_extensions}" and
# move them in to "Movies" or "TV Shows" directories, accordingly. 
#
# TV shows are ideitified as having the pattern "SxxEyy" (where "xx" and "yy" are two-digit numbers)
# anywhere in the file name and will be moved into the directory "TV Shows/{show name}/Season {x}",
# where {show name} is identified as anything before the "SxxEyy" pattern and {x} is the season number
# with any leading zeroes stripped.
#
# Movies are identified as any found file matching the original pattern, but not matching the TV show
# pattern, and are moved into the folder "Movies/{movie name}", where {movie name} is anything before
# the resolution marker.
#
# Any additional files (i.e. files found in the same directory with an additional "extra_extensions" 
# extension will be moved into the same folder.

# list of supported vertical video resolutions
declare -a resolutions=('180p' '182p' '186p' '192p' '208p' '228p' '240p' '320p' '354p' '384p' '352p' '356p' '358p' '360p' '360i' '478p' '480p' '480i' '576i' '576p' '720p' '1080p' '2160p')

# list of supported video formats
declare -a video_extensions=('mkv' 'avi' 'flv' 'mp4' 'webm' 'mpg')

# list of additional extensions to move along with an identified vide file
declare -a extra_extensions=('sha256' 'da.vtt')

# parse parameters...
while [[ $# -gt 0 ]]; do
        key="$1"

        case $key in
                -v|--verbose)
                        verbose=true
                        ;;
                -n|--noop)
                        noop=true
                        ;;
                -h|--help)
                        show_help=true
                        ;;
                *)
                        # unknown option
                        echo "Unknown option: ${key}"
                        show_help=true
                        ;;
        esac
        shift # past argument or value
done

# show help and exit if requested, or an error was found
if [[ "${show_help}" = "true" ]]; then
        echo -e "Usage:"
        echo -e "\t${0} [OPTION]"
        echo -e "Options:"
        echo -e "\t-v, --verbose"
        echo -e "\t\tVerbose run; Show all move and directory creation commands"
        echo -e "\t-n, --noop"
        echo -e "\t\tDon't actually move files, just report what is found"
        echo -e "\t-h, --help"
        echo -e "\t\tShows this help"
        exit
fi

# determine what to show and do, depending on whether the "noop" flag was passed
if [ "${noop}" == "true" ]; then
	move_text="Identified"

	# the special command ":" evaluates to "true" and is in effect a noop
	mkdir=": mkdir"
	mv=": mv"

else
	move_text="Moving"
	mkdir=mkdir
	mv=mv
fi

# If verbose operation was requested, ensure that any subshell outputs its commands.
# Note: this requires that any logging command uses the following format:
#
#     ( ${set} ; ..other commands ... )
#
if [ "${verbose}" == "true" ]; then
	set="set -x"
else
	set="set +x"
fi

# Function to actually move files.
# Usage:
#    move_files {file} {target directory}
#
# Will create {target directory} if not found, move {file}
# into the directory, and if any additional files with the
# extensions in the ${extra_extensions} array are found 
# alongside {file}, these are also moved to {target directory}.
# 
# The {log output} string is written to the console, preceeded
# by the global variable ${move_text}.
function move_files {
	local file="$1"
	local dir="$2"

	( ${set} ; ${mkdir} -p "${dir}" )
	
	( ${set} ; ${mv} -n "${file}" "${dir}" )
	for ext in ${extra_extensions[@]}; do
		local extra_file="${file}.${ext}"
		if [ -e "${extra_file}" ]; then
			( ${set} ; ${mv} -n "${extra_file}" "${dir}" )
		fi
	done
}

# go through all video extensions
for extension in ${video_extensions[@]}; do

	# ...and all resolutions
	for resolution in ${resolutions[@]}; do

		# and look for matching files
		for file in *.${resolution}.${extension}; do

			# if a pattern isn't found, the "for file" loop will return the pattern itself
			# so we use the "exists" check to ensure we really got a file
			if [ -e "${file}" ]; then

				if [[ "${file}" =~ (.*)\.S([0-9][0-9])E([0-9][0-9]) ]]; then
					# TV Show
					# show name is the first group in the regex above
					show_name="${BASH_REMATCH[1]}"
					# season (with leading 0) is the second group
					season0="${BASH_REMATCH[2]}"
					# episode (with leading 0) is the third group
					episode0="${BASH_REMATCH[3]}"

					# strip zeroes for display
					season="${season0#0}"
					episode="${episode0#0}"

					echo "${move_text} TV Show season ${season} episode ${episode} of ${show_name}..."
					move_files "${file}" "TV Shows/${show_name}/Season ${season}"

				else
					# Movie

					# strip resolution and movie extension to get the movie name
					movie_title="${file/.$resolution.$extension}"
		
					echo "${move_text} movie ${movie_title}..."
					move_files "${file}" "Movies/${movie_title}"
				fi
			fi

		done

	done

done
