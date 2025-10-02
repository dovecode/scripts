#!/usr/bin/env bash

# Common utility functions for progress bars and terminal handling. Include like this:
#
#       FULL_PATH_TO_SCRIPT="$(realpath "${BASH_SOURCE[-1]}")"
#       SCRIPT_DIRECTORY="$(dirname "$FULL_PATH_TO_SCRIPT")"
#       source "$SCRIPT_DIRECTORY/util-progress.sh"
#
# If you don't want the terminal to be initialized (for example, if you
# are running in a non-interactive shell), include this file like this:
#	   source "$SCRIPT_DIRECTORY/util-progress.sh" no-init-term
# Note that in this case, the progress-bar function will not work.

# Characters used in the progress bar

#				left	done		todo		right
DARK_ON_LIGHT=(	'' 		'▓'			'░'			'')
FULL_ON_DOT=(	'' 		'█'			'·'			'')
BAR_ON_EMPTY=(	'['		'|' 		' '			']')

# DARK_ON_LIGHT=(	'' 		$'\u2593'	$'\u2591'	'')
# FULL_ON_DOT=(	'' 		$'\u2588'	$'\u00B7'	'')

DEFAULT_STYLE=("${DARK_ON_LIGHT[@]}")

# If none of the characters are set, use the default style.
if [ -z "$LEFT_CHAR$COMPLETED_CHAR$TODO_CHAR$RIGHT_CHAR" ]; then
	LEFT_CHAR=${DEFAULT_STYLE[0]}
	COMPLETED_CHAR=${DEFAULT_STYLE[1]}
	TODO_CHAR=${DEFAULT_STYLE[2]}
	RIGHT_CHAR=${DEFAULT_STYLE[3]}
fi


fatal() {
	echo -e "${COLOR_RED}[FATAL]" "$@" >&2
	exit 1
}

progress-bar() {
	local current=$1
	local len=$2

	local perc_done=$((current * 100 / len))

	local suffix=" $current/$len ($perc_done%)"

	local length=$((COLUMNS - ${#suffix} - ${#LEFT_CHAR} - ${#RIGHT_CHAR}))
	local num_bars=$((perc_done * length / 100))

	local i
	local s=$LEFT_CHAR
	for ((i = 0; i < num_bars; i++)); do
		s+="$COMPLETED_CHAR"
	done
	for ((i = num_bars; i < length; i++)); do
		s+="$TODO_CHAR"
	done
	s+="$RIGHT_CHAR"
	s+="$suffix"

	printf '\e7' # save the cursor location
	printf '\e[%d;%dH' "$LINES" 0 # move cursor to the bottom line
	# Don't clear the line, as that causes flickering
	# printf '\e[0K' # clear the line
	printf '%s' "$s" # print the progress bar
	printf '\e8' # restore the cursor location
}

init-term() {
	printf '\n' # ensure we have space for the scrollbar
	printf '\e7' # save the cursor location
	printf '\e[%d;%dr' 0 "$((LINES - 1))" # set the scrollable region (margin)
	printf '\e8' # restore the cursor location
	printf '\e[1A' # move cursor up
}

deinit-term() {
	printf '\e7' # save the cursor location
	printf '\e[%d;%dr' 0 "$LINES" # reset the scrollable region (margin)
	printf '\e[%d;%dH' "$LINES" 0 # move cursor to the bottom line
	printf '\e[0K' # clear the line
	printf '\e8' # reset the cursor location
}

export COLOR_NONE='\e[0m'
export COLOR_BLACK='\e[0;30m'
export COLOR_GRAY='\e[1;30m'
export COLOR_RED='\e[0;31m'
export COLOR_LIGHT_RED='\e[1;31m'
export COLOR_GREEN='\e[0;32m'
export COLOR_LIGHT_GREEN='\e[1;32m'
export COLOR_BROWN='\e[0;33m'
export COLOR_YELLOW='\e[1;33m'
export COLOR_BLUE='\e[0;34m'
export COLOR_LIGHT_BLUE='\e[1;34m'
export COLOR_PURPLE='\e[0;35m'
export COLOR_LIGHT_PURPLE='\e[1;35m'
export COLOR_CYAN='\e[0;36m'
export COLOR_LIGHT_CYAN='\e[1;36m'
export COLOR_LIGHT_GRAY='\e[0;37m'
export COLOR_WHITE='\e[1;37m'

shopt -s checkwinsize
# this line is to ensure LINES and COLUMNS are set
(true)

if [ -z "$LINES" ] || [ -z "$COLUMNS" ]; then
	fatal "Cannot determine terminal size (LINES=$LINES, COLUMNS=$COLUMNS)"
fi

if [ -z "$1" ] || [ "$1" != "no-init-term" ]; then
	trap deinit-term exit
	trap init-term winch
	init-term
fi
