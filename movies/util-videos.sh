#!/usr/bin/env bash

# Common definition for video file management scripts. Include like this:
#
#       FULL_PATH_TO_SCRIPT="$(realpath "${BASH_SOURCE[-1]}")"
#       SCRIPT_DIRECTORY="$(dirname "$FULL_PATH_TO_SCRIPT")"
#       source "$SCRIPT_DIRECTORY/util-videos.sh"

# Supported video file extensions and directories to scan.
declare -a video_extensions=('mkv' 'avi' 'flv' 'mp4' 'webm' 'mpg')

# Directories to scan for video files.
declare -a directories=('Movies' 'TV Shows')
