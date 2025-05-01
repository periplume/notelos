# TUI Shell for notelos

This is a Terminal User Interface (TUI) implementation for the notelos application, replacing the current CLI-like shell with a more modern, interactive, and visually appealing interface.

## Features

- **Full-screen TUI**: Utilizes the entire terminal screen efficiently
- **Terminal-aware**: Automatically adjusts to terminal dimensions
- **Dynamic updates**: Shows background process status in real-time
- **Message area**: Dedicated area for displaying system messages, errors, and information
- **Colorized UI**: Simple and clear color scheme that's easy to modify
- **Preserves functionality**: All existing commands and features from the original shell are maintained

## Integration with notelos

To integrate the TUI shell with the main notelos application:

1. Add the `tui-shell.sh` file to your notelos bin directory
2. In the main `notelos` script, source the TUI shell file:
   ```bash
   source "$(dirname "$0")/tui-shell.sh"
   ```
3. Replace or modify the current `_shell` function to use the TUI shell:
   ```bash
   _shell() {
       # You can either replace this with _tui_shell directly
       _tui_shell
       # Or add a feature flag to toggle between the two
       if [[ ${_notelosTUI:-false} == "true" ]]; then
           _tui_shell
       else
           # Original shell implementation
           # ...
       fi
   }
   ```

## Customization

### Color Scheme

The color scheme is defined using standard terminal color codes and can be easily modified:

```bash
# Edit these variables in tui-shell.sh to change the colors
reset=$'\001\e[0m\002'
_cH=$'\001\e[00;45m\002'    # Purple background for home
_cG=$'\001\e[00;7m\002'     # Reverse video for germ
_cU=$'\001\e[00;32m\002'    # Green for username
_cS=$'\001\e[00;33m\002'    # Yellow for source
```

### Message Area

You can adjust the size of the message area by changing the `_tui_max_messages` variable:

```bash
_tui_max_messages=5   # Number of message lines to display
```

### Status Monitoring

The TUI includes a status monitoring function that checks for active background processes:

```bash
_tui_check_background_process() {
    # Customize this function to monitor different processes
    # ...
}
```

## Testing

You can test the TUI shell independently using the included test script:

```bash
./bin/test-tui.sh
```

## Components

The TUI is composed of several main components:

1. **Header**: Displays the application name and current status
2. **Content Area**: The main display area that adapts based on the current function
3. **Message Area**: Shows system messages and command output
4. **Footer**: Contains the command prompt and help text

## Key Commands

All existing commands are preserved:

- `h/?: Help
- `a`: Add a new note
- `e`: Edit a note
- `b`: Browse notes
- `s`: Search
- `c`: Change notebook
- `q`: Quit

Additionally, Alt-key combinations are supported:
- `Alt+x`: Toggle bash debug mode
- `Alt+d`: Toggle application debug mode
- `Alt+g`: Show git status

## Architecture

The TUI shell is implemented as a set of functions that handle:

1. Screen rendering and layout
2. Input processing
3. Command execution
4. Message display and management
5. Background process monitoring

The implementation uses standard terminal control sequences via `tput` to create an interactive interface without requiring external libraries.

## Notes on Terminal Compatibility

This TUI should work on most modern terminal emulators, but might have issues with some less common terminals. It has been tested with:

- xterm
- GNOME Terminal
- Konsole
- iTerm2

If you encounter display issues, ensure your terminal supports:
- ANSI color codes
- Terminal cursor positioning
- Screen saving/restoring