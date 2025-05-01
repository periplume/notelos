#!/usr/bin/env bash
# Test script for the TUI shell implementation

# Source paths
SOURCE_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
TUI_SHELL_PATH="${SOURCE_DIR}/tui-shell.sh"
NOTELOS_LIB_PATH="${SOURCE_DIR}/notelos-lib.sh"

# Check if the TUI shell script exists
if [[ ! -f "$TUI_SHELL_PATH" ]]; then
    echo "Error: TUI shell script not found at $TUI_SHELL_PATH"
    exit 1
fi

# Source the TUI shell script
source "$TUI_SHELL_PATH"

# Check for necessary environment variables
if [[ -z "$_notelosHOME" ]]; then
    echo "Warning: _notelosHOME not set, using fallback value"
    export _notelosHOME="$HOME/notelos"
fi

if [[ -z "$_notelosNAME" ]]; then
    export _notelosNAME="notelos"
fi

if [[ -z "$_notelosUSERNAME" ]]; then
    export _notelosUSERNAME="$(whoami)"
fi

# Echo some information
echo "Starting TUI shell test..."
echo "Press 'q' to quit, 'h' for help"
echo "Starting in 2 seconds..."
sleep 2

# Start the TUI shell
_tui_shell

# Echo when done
echo "TUI shell exited"