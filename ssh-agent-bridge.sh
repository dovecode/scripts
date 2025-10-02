#!/usr/bin/env bash

# Script for creating a bridge from the Windows 10/11 OpenSSH Agent
# named pipe (//./pipe/openssh-ssh-agent) to a named socket in cygwin.
# Original script from https://gist.github.com/riedel/2002835932b073cea836fb171aa27a51
# Modified to clean processes and sockets from any previous runs.

# 
# This will use socat and PLINK (from PuTTY) to link from a UNIX domain socket:
# 
# ssh <--socket--> socat <--unnamed pipes--> PLINK <--OpenSSH pipe--> OpenSSH Agent
# 

# You can call this from your profile script (~/.profile, ~/.bashrc, ~/.zshrc, ...)
# like so:
# 	source /path/to/this/script.sh
# This script supports the standard ssh-agent syntax by emitting the configuration
# on stdout, so if you prefer, you can call this script like so instead:
#	eval $(/path/to/this/script.sh)

# Get current date/time for identifying creation time of sockets.
now_yyyymmddhhmmss=$(date +%Y%m%d%H%M%S)

# Name of the Windows OpenSSH Agent named pipe.
WIN_OPENSSH_PIPE="//./pipe/openssh-ssh-agent"
# Prefix for directories in /tmp to hold ssh-agent sockets.
SSH_AGENT_BRIDGE_DIR="/tmp/ssh-socat-plink-agent-bridge"
SSH_AGENT_BRIDGE_PREFIX="${SSH_AGENT_BRIDGE_DIR}/$now_yyyymmddhhmmss-"
# SSH_AGENT_BRIDGE_PREFIX="ssh-socat-plink-agent-bridge"
# Name of the PuTTY plink command.
PUTTY_PLINK="PLINK"
PUTTY_PLINK_EXE="${PUTTY_PLINK}.EXE"

debug() {
	if [ "$DEBUG" = "1" ]; then
		log "DEBUG: $*"
	fi
}

log() {
	echo "$*" >&2
}

# Helper function to determine if the current script is sourced or executed.
# From: https://stackoverflow.com/questions/2683279/how-to-detect-if-a-script-is-being-sourced
is_sourced() {
	if [ -n "$ZSH_VERSION" ]; then 
		case $ZSH_EVAL_CONTEXT in
			*:file:*) return 0;; 
		esac
	else  # Add additional POSIX-compatible shell names here, if needed.
		case ${0##*/} in 
			dash|-dash|bash|-bash|ksh|-ksh|sh|-sh) return 0;; 
		esac
	fi
	return 1  # NOT sourced.
}

# Check to see if the script is being sourced (or executed).
is_sourced && SCRIPT_IS_SOURCED=true || SCRIPT_IS_SOURCED=false

# Helper function to check if a command exists.
# Usage: check_command <command> <extra error message>
check_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		log "Command $1 not found. $2" >&2
		exit 1
	fi
}

# First check that required commands are available.
check_command "${PUTTY_PLINK_EXE}" "Please install PuTTY and ensure ${PUTTY_PLINK} is in your PATH."
check_command "socat" "Please install socat (e.g. 'apt-cyg install socat' or 'pacman -S socat')."
check_command "awk" "Please install awk (e.g. 'apt-cyg install awk' or 'pacman -S awk')."
check_command "mktemp.exe" "Please install mktemp (e.g. 'apt-cyg install coreutils' or 'pacman -S coreutils')."
check_command "ssh-add" "Please install ssh-add (e.g. 'apt-cyg install openssh' or 'pacman -S openssh')."
check_command "ps" "Please install ps (e.g. 'apt-cyg install procps' or 'pacman -S procps-ng')."
check_command "grep" "Please install grep (e.g. 'apt-cyg install grep' or 'pacman -S grep')."
check_command "date" "Please install date (e.g. 'apt-cyg install coreutils' or 'pacman -S coreutils')."
check_command "find" "Please install find (e.g. 'apt-cyg install findutils' or 'pacman -S findutils')."
check_command "rm" "Please install rm (e.g. 'apt-cyg install coreutils' or 'pacman -S coreutils')."
check_command "rmdir" "Please install rmdir (e.g. 'apt-cyg install coreutils' or 'pacman -S coreutils')."
check_command "kill" "Please install kill (e.g. 'apt-cyg install coreutils' or 'pacman -S coreutils')."
check_command "tail" "Please install tail (e.g. 'apt-cyg install coreutils' or 'pacman -S coreutils')."


# Unset any existing ssh-agent environment variables. We will set them to
# point to a working existing or our new socket below.
export SSH_AUTH_SOCK=""
export SSH_AGENT_PID=""


# First, check for any existing ssh-agent sockets in the SSH_AGENT_BRIDGE_DIR.
# If we find one, check if it is still active. If so, set the environment
# variables to connect to it and exit. If not, remove the stale socket
# and continue to create a new one.
# This allows multiple terminal sessions to share the same ssh-agent
# socket, and also cleans up any stale sockets from previous runs.
# Note that this assumes that the SSH_AGENT_BRIDGE_DIR is only used
# by this script to store ssh-agent sockets.

debug "Testing for existing ssh-agent sockets in ${SSH_AGENT_BRIDGE_DIR}"
for socket in $(find ${SSH_AGENT_BRIDGE_DIR} -type s); do
	debug "Found existing ssh-agent socket: $socket"
	debug "Checking if it is still active..."
	SSH_AUTH_SOCK=$socket ssh-add -l >/dev/null 2>&1
	if [ $? -le 1 ]; then
		debug "Socket is active."
		debug "You can connect to it by running:"
		debug "  export SSH_AUTH_SOCK=$socket"
		debug "  ssh-add -l"

		log "Found existing ssh-agent socket. Connecting to it."
		# Set the environment variables to connect to this existing socket.
		# Note that the SSH_AGENT_PID is not actually used by ssh, but some
		# tools expect it to be set to a non-empty value.
		# We set it to the PID of the socat process that created the socket,
		# which is encoded in the socket filename as the extension after the last dot.
		export SSH_AUTH_SOCK=${socket}
		export SSH_AGENT_PID=${socket##*.}

		break
	else
		debug "Socket is stale. Killing process and removing."
		# Socket is stale. Kill the associated socat process and remove the socket.
		socat_pid=${socket##*.}
		kill $socat_pid 2>/dev/null
		rm -f "$socket"
		rmdir $(dirname "$socket")
	fi
done


# If SSH_AUTH_SOCK is not set, meaning we didn't find a working existing one, create a new ssh-agent bridge.
if [[ -z "$SSH_AUTH_SOCK" ]]; then
	log "No existing SSH_AUTH_SOCK set. Creating a new ssh-agent bridge."

	# clean up any existing temp dirs with sockets
	rm -Rf "${SSH_AGENT_BRIDGE_DIR}" 2>/dev/null

	# Ensure the base directory for sockets exists.
	mkdir -p $SSH_AGENT_BRIDGE_DIR 2>/dev/null

	# Temporary directory where the ssh agent socket will be created
	SOCKDIR=$(mktemp.exe -d ${SSH_AGENT_BRIDGE_PREFIX}XXXXXXXXX)

	# clean up any existing bridges
	kill_all "socat"
	kill_all "${PUTTY_PLINK}"

	# Set ssh agent socket name
	export SSH_AUTH_SOCK=$SOCKDIR/agent.$$
	# Start socat, creating a socket in $SSH_AUTH_SOCK linked to a pair of pipes to
	# a PuTTY PLINK process that connects to the Windows OpenSSH pipe
	nohup socat UNIX-LISTEN:$SSH_AUTH_SOCK,umask=066,fork EXEC:"${PUTTY_PLINK_EXE} -serial ${WIN_OPENSSH_PIPE}",pipes >$SOCKDIR/socat.log.$$ 2>&1 &

	export SSH_AGENT_PID=$!

	# Register a cleanup process for when socat/ssh-agent-bridge.sh is killed.
	nohup bash -c "tail --pid $SSH_AGENT_PID -f /dev/null; rm -rf $SOCKDIR" >/dev/null 2>&1 &
fi


if [ "${SCRIPT_IS_SOURCED}" = false ]; then
        echo -e "\tSSH_AUTH_SOCK=$SSH_AUTH_SOCK; export SSH_AUTH_SOCK;"
        echo -e "\tSSH_AGENT_PID=$SSH_AGENT_PID; export SSH_AGENT_PID;"
        echo -e "\techo Agent pid $SSH_AGENT_PID;"
else
	keys=$(ssh-add -l)
	if [[ $? == 0 ]]; then
		log "Current keys loaded:"
		printf " - %s\n" "$keys" 2>/dev/null
	elif [[ $? == 1 ]]; then
		log "No keys loaded. Unlock KeepassXC to load keys."
	else
		log "Error connecting to SSH Agent."
	fi
fi

# End of script.