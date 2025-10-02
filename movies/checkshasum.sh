#!/usr/bin/env bash

# Get the path to the directory this script is in.
FULL_PATH_TO_SCRIPT="$(realpath "${BASH_SOURCE[-1]}")"
SCRIPT_DIRECTORY="$(dirname "$FULL_PATH_TO_SCRIPT")"

# Now, source shared libraries
. "$SCRIPT_DIRECTORY/util-progress.sh"
. "$SCRIPT_DIRECTORY/util-videos.sh"

root="${PWD}"
verbose=false
force=false
retry=false
printprefailed=false

declare -a override_exts=()
declare -a override_dirs=()

while [[ $# -gt 0 ]]; do
        key="$1"

        case $key in
                -v|--verbose)
                        verbose=true
                        ;;
                -p|--printprefailed)
                        printprefailed=true
                        ;;
                -f|--force)
                        force=true
                        ;;
                -r|--retry)
                        retry=true
                        ;;
                -d|--directory)
                        override_dirs+=("$2")
                        shift # past argument
                        ;;
                -e|--extension)
                        override_exts+=("$2")
                        shift # past argument
                        ;;

                -h|--help)
                        SHOW_HELP=true
                        ;;
                
                *)
                        # unknown option
                        echo "Unknown option: ${key}"
                        SHOW_HELP=true
                        ;;
        esac
        shift # past argument or value
done

if [[ "${SHOW_HELP}" = true ]]; then
        echo -e "Usage:"
        echo -e "\t${0} [OPTION]"
        echo -e "Options:"
        echo -e "\t-v, --verbose"
        echo -e "\t\tVerbose run; Show all errors"
        echo -e "\t-p, --printprefailed"
        echo -e "\t\tPrint info about previously failed checksums"
        echo -e "\t-f, --force"
        echo -e "\t\tForce checksum verification for all files, even if a previous \"PASS\" or \"FAIL\" file already exists"
        echo -e "\t-r, --retry"
        echo -e "\t\tForce checksum verification for all files where \"FAIL\" file already exists (but skip \"PASS\" files)"
        echo -e "\t-d dir, --directory dir"
        echo -e "\t\tCheck files in subdirectories of \"dir\". Defaults to ${directories}"
        echo -e "\t-e ext, --extension ext"
        echo -e "\t\tOnly check for files with the specified extension. Can be specified multiple times"
        echo -e "\t\tDefault: ${video_extensions[@]}"
        echo -e "\t-h, --help"
        echo -e "\t\tShows this help"
        exit
fi

if [ ${#override_exts} -gt 0 ]; then
        video_extensions=("${override_exts[@]}")
fi

if [ ${#override_dirs} -gt 0 ]; then
        directories=("${override_dirs[@]}")
fi

extension_list=
for extension in ${video_extensions[@]}; do

        expression="-name *.${extension}"

        if [ -z "${extension_list}" ]; then
                extension_list="${expression}"
        else
                extension_list="${extension_list} -o ${expression}"
        fi
done

files="$(find -L "${directories[@]}" -type f \( ${extension_list} \) )"

totalfiles="$(echo -n "$files" | wc -l)"
if [ ! -z "${files}" ]; then
        ((totalfiles++))
fi
echo "${totalfiles} files to check on host ${HOSTNAME}"
processedfiles=0
passedfiles=0
failedfiles=0
nochecksumfiles=0

if [ ${totalfiles} -gt 0 ]; then
while read -r mkvfile; do
        ((processedfiles++))
        progress-bar "${processedfiles}" "${totalfiles}"

        mkvpath="${mkvfile%/*}"
        mkvname="${mkvfile##*/}"

        shafile="${mkvname}.sha256"
        shafile_pass="${shafile}.${HOSTNAME}.PASS"
        shafile_fail="${shafile}.${HOSTNAME}.FAIL"

        cd "${mkvpath}"

                # Determine if we should skip the file or not...
                skipfile=false
        if [[ -f "${shafile_pass}" ]]; then

                        if [[ "${force}" == "false" ]]; then
                                # File already passed once before and we're not asked to force, so skip

                                ((passedfiles++))
                                skipfile=true
                                if [[ "${verbose}" == "true" ]]; then
                                        echo -e "${COLOR_GREEN}${mkvname} already checked and passed on this host. Skipping${COLOR_NONE}"
                                fi
                        else
                                # File already passed once before, but we're asked to force, so recheck it

                                if [[ "${verbose}" == "true" ]]; then
                                        echo "${mkvname} already checked and passed on this host. Checking file anyway!"
                                fi
                        fi

        elif [[ -f "${shafile_fail}" ]]; then

                        if [[ "${force}" == "false" ]] && [[ "${retry}" == "false" ]]; then
                                # File already failed once before, and we're not asked to force or retry, so skip

                                ((failedfiles++))
                                skipfile=true
                                if [[ "$printprefailed" == "true" ]]; then
                                        echo -e "${COLOR_LIGHT_RED}${mkvname} already checked and FAILED on this host. Skipping${COLOR_NONE}"
                                fi
                                if [[ "$verbose" = true ]]; then
                                        cat "${shafile_fail}"|sed "s%^%\t%"
                                fi
                        else
                                # File already failed once before, but we're asked to force or retry, so recheck it
                                echo "${mkvname} already checked and FAILED on this host. Checking file anyway!"
                        fi

                fi

                if [[ "${skipfile}" == "false" ]]; then

                        if [[ -f "${shafile}" ]]; then

                                echo "Checking sha sum for ${mkvname}..."
                                result="$(sha256sum -c "${shafile}" 2>&1)"

                                if [[ $? == 0 ]]; then
                                        # file passed (sha256sum returns 0 on successful check)
                                        ((passedfiles++))

                                        # write result to PASS file
                                        echo "${result}">"${shafile_pass}"

                                        # if a previous FAIL file exists, delete it and announce a pass
                                        if [[ -f "${shafile_fail}" ]]; then
                                                rm -f "${shafile_fail}"
                                                echo -e "${COLOR_GREEN}${mkvname} PASSED${COLOR_NONE}"
                                        fi
                                else
                                        ((failedfiles++))
                                        echo "${result}">"${shafile_fail}"
                                        if [[ -f "${shafile_pass}" ]]; then
                                                rm -f "${shafile_pass}"
                                        fi
                                        echo -e "${COLOR_RED}${mkvname} FAILED${COLOR_NONE}"
                                        if [[ "$verbose" = true ]]; then
                                                cat "${shafile_fail}"|sed "s%^%\t%"
                                        fi
                                fi

                        else
                                ((nochecksumfiles++))
                                echo -e "${COLOR_BLUE}No sha sum found for ${mkvname}!${COLOR_NONE}"
                        fi

                fi

        cd "${root}"

done <<EOF
${files}
EOF
fi

echo -e "${totalfiles} found. ${COLOR_GREEN}${passedfiles} files passed${COLOR_NONE}, ${COLOR_RED}${failedfiles} files failed${COLOR_NONE}, ${COLOR_BLUE}${nochecksumfiles} files were missing checksums${COLOR_NONE}"


