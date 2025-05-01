#!/usr/bin/env bash
# TUI implementation of the notelos shell
# This function will replace _shell with a terminal-aware, dynamic UI

# Define TUI-specific variables
_tui_buffer=""        # Screen buffer for redrawing
_tui_messages=()      # Array to hold messages for the message area
_tui_max_messages=5   # Maximum number of messages to show
_tui_cursor_pos=0     # Current cursor position for input
_tui_input=""         # Current input buffer
_tui_term_width=0     # Terminal width
_tui_term_height=0    # Terminal height
_tui_status=()        # Array to hold status information
_tui_active_process="" # Currently active background process
_tui_refresh_rate=1   # Refresh rate in seconds

# TUI-specific helpers
_tui_init() {
    # Save terminal state
    tput smcup
    # Hide cursor
    tput civis
    # Clear screen
    clear
    # Get terminal dimensions
    _tui_update_dimensions
    # Initialize message buffer
    _tui_add_message "TUI Shell initialized"
    # Trap window resize
    trap _tui_handle_resize WINCH
    # Trap exit to restore terminal
    trap _tui_cleanup EXIT
}

_tui_cleanup() {
    # Show cursor
    tput cnorm
    # Restore terminal state
    tput rmcup
    # Remove traps
    trap - WINCH EXIT
}

_tui_handle_resize() {
    _tui_update_dimensions
    _tui_render
}

_tui_update_dimensions() {
    _tui_term_width=$(tput cols)
    _tui_term_height=$(tput lines)
}

_tui_clear_screen() {
    # Clear screen and move to home position
    tput clear
    tput cup 0 0
}

_tui_add_message() {
    # Add a message to the message queue
    local message="$1"
    local level="${2:-info}" # Default level is info
    local timestamp=$(date +"%H:%M:%S")
    
    # Add timestamp and color based on level
    case "$level" in
        info)
            message="${green}${timestamp}${reset} ${message}"
            ;;
        warn)
            message="${yellow}${timestamp}${reset} ${message}"
            ;;
        error)
            message="${red}${timestamp}${reset} ${message}"
            ;;
        debug)
            message="${cyan}${timestamp}${reset} ${message}"
            ;;
    esac
    
    # Add message to array
    _tui_messages=("$message" "${_tui_messages[@]}")
    
    # Trim array to max size
    if [[ ${#_tui_messages[@]} -gt $_tui_max_messages ]]; then
        _tui_messages=("${_tui_messages[@]:0:$_tui_max_messages}")
    fi
    
    # Force a render
    _tui_render
}

_tui_draw_header() {
    local header_width=$((_tui_term_width - 2))
    local title="noΤΈΛΟΣ : ${_MASTER} : NOτέλος"
    local title_len=${#title}
    local padding=$(( (header_width - title_len) / 2 ))
    
    # Print top border
    printf '┌%s┐\n' "$(printf '─%.0s' $(seq 1 $header_width))"
    
    # Print title
    printf '│%*s%s%*s│\n' "$padding" "" "${cyan}${title}${reset}" "$padding" ""
    
    # Print status line with notebook info
    local status="Current notebook: ${yellow}${_currentSource}${reset}"
    local entry_count="Entries: ${green}$(_getSourceCount ${_currentSource})${reset}"
    local status_line="${status} | ${entry_count}"
    
    # If there's an active process, show it
    if [[ -n "$_tui_active_process" ]]; then
        status_line+=" | Process: ${red}${_tui_active_process}${reset}"
    fi
    
    # Check git status
    if _isIndexClean; then
        status_line+=" | Git: ${green}clean${reset}"
    else
        status_line+=" | Git: ${red}uncommitted changes${reset}"
    fi
    
    printf '│ %-*s│\n' "$header_width" "$status_line"
    
    # Print bottom border of header
    printf '├%s┤\n' "$(printf '─%.0s' $(seq 1 $header_width))"
}

_tui_draw_footer() {
    local footer_width=$((_tui_term_width - 2))
    
    # Print top border of footer
    printf '├%s┤\n' "$(printf '─%.0s' $(seq 1 $footer_width))"
    
    # Print help text
    local help_text="h:Help | a:Add | e:Edit | b:Browse | s:Search | c:Change | q:Quit"
    printf '│ %-*s│\n' "$footer_width" "$help_text"
    
    # Print prompt and bottom border
    local prompt_text="${_cH}${_MASTER}${reset}:${_cG}${_NAME}${reset} ${_cU}${_USERNAME}${reset} [${_cS}${_currentSource}${reset}] > $_tui_input"
    printf '│ %-*s│\n' "$footer_width" "$prompt_text"
    printf '└%s┘\n' "$(printf '─%.0s' $(seq 1 $footer_width))"
}

_tui_draw_message_area() {
    local message_area_height=$((_tui_max_messages + 2))
    local message_area_width=$((_tui_term_width - 2))
    
    # Print header for message area
    printf '├%s┤\n' "$(printf '─%.0s' $(seq 1 $message_area_width))"
    printf '│ %-*s│\n' "$message_area_width" "Message Log"
    printf '├%s┤\n' "$(printf '─%.0s' $(seq 1 $message_area_width))"
    
    # Print messages
    for ((i=0; i<$_tui_max_messages; i++)); do
        if [[ $i -lt ${#_tui_messages[@]} ]]; then
            printf '│ %-*s│\n' "$message_area_width" "${_tui_messages[$i]}"
        else
            printf '│ %-*s│\n' "$message_area_width" ""
        fi
    done
}

_tui_draw_content() {
    local content_height=$((_tui_term_height - _tui_max_messages - 7))
    local content_width=$((_tui_term_width - 2))
    
    # Calculate available space
    if [[ $content_height -lt 1 ]]; then
        content_height=1
    fi
    
    # Display main content
    for ((i=0; i<$content_height; i++)); do
        printf '│ %-*s│\n' "$content_width" ""
    done
}

_tui_render() {
    # Store cursor position
    local cursor_pos="$_tui_cursor_pos"
    
    # Clear screen
    _tui_clear_screen
    
    # Draw UI components
    _tui_draw_header
    _tui_draw_content
    _tui_draw_message_area
    _tui_draw_footer
    
    # Restore cursor position - at the prompt line
    tput cup $((_tui_term_height - 2)) $(( 3 + ${#_cH} + ${#_MASTER} + ${#_cG} + ${#_NAME} + ${#_cU} + ${#_USERNAME} + ${#_cS} + ${#_currentSource} + 7 + cursor_pos ))
    
    # Show cursor
    tput cnorm
}

_tui_handle_keypress() {
    local key="$1"
    local keycode="$2"
    
    # Debug key info
    #_tui_add_message "Key: '$key' (${keycode})" "debug"
    
    case "$key" in
        h|\?)
            _tui_show_help
            ;;
        a)
            _tui_cleanup
            _add
            _tui_init
            _tui_render
            ;;
        f)
            _tui_add_fast_note
            ;;
        e)
            _tui_cleanup
            _edit
            _tui_init
            _tui_render
            ;;
        b)
            _tui_cleanup
            _browse
            _tui_init
            _tui_render
            ;;
        s)
            _tui_cleanup
            _search
            _tui_init
            _tui_render
            ;;
        c|C)
            _tui_cleanup
            _changeSource
            _tui_init
            _tui_render
            ;;
        N)
            _tui_cleanup
            _newSource
            _tui_init
            _tui_render
            ;;
        R)
            _tui_cleanup
            _renameSource
            _tui_init
            _tui_render
            ;;
        M)
            _tui_cleanup
            _mergeSource
            _tui_init
            _tui_render
            ;;
        D)
            _tui_cleanup
            _deleteSource
            _tui_init
            _tui_render
            ;;
        E)
            _tui_cleanup
            ${_EDITOR} "${_HOME}/${_currentSource}/.description"
            git -C "${_HOME}" --git-dir="${_GITDIR}" add "${_HOME}/${_currentSource}/.description"
            git -C "${_HOME}" --git-dir="${_GITDIR}" commit -q -m "[source] updated '${_currentSource}' description"
            _tui_init
            _tui_render
            ;;
        P)
            _tui_show_source_info
            ;;
        t)
            _tui_cleanup
            _inspect
            _tui_init
            _tui_render
            ;;
        q)
            return 1
            ;;
        *)
            # Unknown command
            _tui_add_message "Unknown command: $key" "warn"
            ;;
    esac
    
    return 0
}

_tui_handle_escape_sequence() {
    # Read more bytes to determine the escape sequence
    read -rsn 2 -t 0.01 escapeseq
    
    case "$escapeseq" in
        "[A") # Up arrow
            _tui_add_message "Up arrow - history navigation not implemented yet" "info"
            ;;
        "[B") # Down arrow
            _tui_add_message "Down arrow - history navigation not implemented yet" "info"
            ;;
        "[C") # Right arrow
            ((_tui_cursor_pos < ${#_tui_input})) && ((_tui_cursor_pos++))
            ;;
        "[D") # Left arrow
            ((_tui_cursor_pos > 0)) && ((_tui_cursor_pos--))
            ;;
        *)
            # Handle Alt+key combinations
            if [[ ${#escapeseq} -eq 1 ]]; then
                case "$escapeseq" in
                    x|X)
                        # Toggle bash debug
                        [[ $- == *x* ]] && set +x || set -x
                        _tui_add_message "Bash debug mode toggled" "debug"
                        ;;
                    d|D)
                        # Toggle app debug
                        [ $_DEBUG = "true" ] && _DEBUG=false || _DEBUG=true
                        _tui_add_message "Debug mode: $_DEBUG" "debug"
                        ;;
                    g|G)
                        _tui_cleanup
                        git -C "${_HOME}" --git-dir="${_GITDIR}" status
                        read -n 1 -p "Press any key to continue..."
                        _tui_init
                        _tui_render
                        ;;
                    *)
                        _tui_add_message "Unknown Alt+key: $escapeseq" "debug"
                        ;;
                esac
            else
                _tui_add_message "Unknown escape sequence: $escapeseq" "debug"
            fi
            ;;
    esac
}

_tui_show_help() {
    # Clear content area
    _tui_clear_screen
    
    # Draw header
    _tui_draw_header
    
    # Show help content
    local content_width=$((_tui_term_width - 4))
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" " ${yellow}Help${reset}"
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" "───────────────────────────────────────────"
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" " ${green}h/?${reset} - Show this help"
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" " ${green}a${reset}   - Add new note (editor)"
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" " ${green}f${reset}   - Fast add (one line, no editor)"
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" " ${green}e${reset}   - Edit note"
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" " ${green}b${reset}   - Browse notes"
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" " ${green}s${reset}   - Search"
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" " ${green}p${reset}   - Export to PDF"
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" ""
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" " ${green}C${reset}   - Change notebook"
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" " ${green}N${reset}   - Create new notebook"
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" " ${green}R${reset}   - Rename current notebook"
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" " ${green}M${reset}   - Merge notebooks"
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" " ${green}D${reset}   - Delete current notebook"
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" " ${green}P${reset}   - Show notebook info"
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" " ${green}E${reset}   - Edit notebook description"
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" ""
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" " ${green}Alt+x${reset} - Toggle bash debug"
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" " ${green}Alt+d${reset} - Toggle app debug"
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" " ${green}Alt+g${reset} - Git status"
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" ""
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" " ${green}q${reset}   - Quit"
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" ""
    printf '│ %-*s│\n' "$((_tui_term_width - 2))" " Press any key to return..."
    
    # Fill remaining space
    local content_height=$((_tui_term_height - _tui_max_messages - 7 - 22))
    for ((i=0; i<$content_height; i++)); do
        printf '│ %-*s│\n' "$((_tui_term_width - 2))" ""
    done
    
    # Draw message area and footer
    _tui_draw_message_area
    _tui_draw_footer
    
    # Wait for key press
    read -rsn1
    
    # Re-render
    _tui_render
}

_tui_add_fast_note() {
    _tui_add_message "Enter note text (press Enter when done):" "info"
    
    # Save terminal state
    tput smcup
    
    # Get the note
    read -r _newEntry
    
    # If input not empty, add the note
    if [[ -n "$_newEntry" ]]; then
        _key=$(_getNewKey)
        _commitMsg=$(_buildCommitMsg "${_newEntry}")
        echo "${_newEntry}" > "${_HOME}/${_currentSource}/${_key}"
        _doCommit "${_HOME}/${_currentSource}/${_key}" "[add to ${_currentSource}] ${_commitMsg}"
        _tui_add_message "Note added successfully" "info"
    else
        _tui_add_message "Note creation canceled" "warn"
    fi
    
    # Restore terminal state and re-render
    tput rmcup
    _tui_render
}

_tui_show_source_info() {
    _tui_add_message "Source: ${_currentSource}" "info"
    _tui_add_message "Entries: $(_getSourceCount ${_currentSource})" "info"
    
    # Get description
    if [[ -f "${_HOME}/${_currentSource}/.description" ]]; then
        _tui_add_message "Description: $(cat ${_HOME}/${_currentSource}/.description)" "info"
    else
        _tui_add_message "No description available" "warn"
    fi
}

# Function to check for background processes
_tui_check_background_process() {
    # Check for dsink backup status
    if [[ -f "${_notelosHOME}/.dsink/state/changemonitorPID/"* ]]; then
        _tui_active_process="dsink backup"
    else
        _tui_active_process=""
    fi
}

# Main TUI shell function
_tui_shell() {
    cd "${_HOME}" || { _error "cannot enter ${_NAME}"; return 1; }
    
    # Set up shell history
    HISTFILE="${_HOME}/.${_NAME}_history"
    HISTSIZE=1000
    HISTFILESIZE=10000
    HISTTIMEFORMAT="%s %F %T "
    HISTCONTROL=ignoreboth
    shopt -s histappend
    set -o history
    
    # Set the current source
    export _currentSource=$(_getSource)
    
    # Set up colors for the prompt
    reset=$'\001\e[0m\002'
    _cH=$'\001\e[00;45m\002'    # home
    _cG=$'\001\e[00;7m\002'     # germ
    _cU=$'\001\e[00;32m\002'    # user
    _cS=$'\001\e[00;33m\002'    # source
    
    # Initialize TUI
    _tui_init
    
    # Display welcome message
    _tui_add_message "Welcome to noΤΈΛΟΣ: ${_notelosNAME}" "info"
    _tui_add_message "Type 'h' for help, 'q' to quit" "info"
    
    # Main input loop
    while true; do
        # Check background processes
        _tui_check_background_process
        
        # Render screen
        _tui_render
        
        # Read a single character
        read -rsn1 char
        
        # Process the character
        case "$char" in
            $'\e')  # Escape sequence
                _tui_handle_escape_sequence
                ;;
            $'\177') # Backspace
                if [[ $_tui_cursor_pos -gt 0 ]]; then
                    _tui_input="${_tui_input:0:$((_tui_cursor_pos-1))}${_tui_input:$_tui_cursor_pos}"
                    ((_tui_cursor_pos--))
                fi
                ;;
            $'\n')  # Enter key
                if [[ -n "$_tui_input" ]]; then
                    _tui_add_message "Command entered: $_tui_input" "debug"
                    _tui_input=""
                    _tui_cursor_pos=0
                else
                    # Process single character commands
                    if ! _tui_handle_keypress "$char" "$(printf '%d' "'$char")"; then
                        _tui_cleanup
                        return 0
                    fi
                fi
                ;;
            *)      # Regular input
                # Process single character commands if no input is being built
                if [[ -z "$_tui_input" ]]; then
                    if ! _tui_handle_keypress "$char" "$(printf '%d' "'$char")"; then
                        _tui_cleanup
                        return 0
                    fi
                else
                    # Add to input buffer
                    _tui_input="${_tui_input:0:$_tui_cursor_pos}$char${_tui_input:$_tui_cursor_pos}"
                    ((_tui_cursor_pos++))
                fi
                ;;
        esac
    done
}

# Replace _shell with _tui_shell
_shell() {
    _tui_shell
}
