#!/usr/bin/env bash
FULL_PATH_TO_SCRIPT="$(realpath "${BASH_SOURCE[-1]}")"
SCRIPT_DIRECTORY="$(dirname "$FULL_PATH_TO_SCRIPT")"
source "$SCRIPT_DIRECTORY/util-progress.sh" no-init-term

export LANG=C

# Specify LINES and COLUMNS for the remote shell, as this is not an interactive shell, so it won't be set automatically.
# Also specify the characters for the progress bar to be non-unicode, as unicode seems to break everything over ssh.
# ssh bananas "LEFT_CHAR='[' COMPLETED_CHAR='x' TODO_CHAR='ü' RIGHT_CHAR=']' LINES=$LINES COLUMNS=$COLUMNS /volume1/homes/nicolai/scripts/movies/checkshasum.sh $* -d /volume1/video/Movies -d /volume1/video/TV\ Shows"
ssh bananas "LINES=$LINES COLUMNS=$COLUMNS /volume1/homes/nicolai/scripts/movies/checkshasum.sh $* -d /volume1/video/Movies -d /volume1/video/TV\ Shows"
