# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
notelos is a digital writer's studio providing a distraction-free writing environment with automatic version control. The project uses bash scripts to create an "appliance-like" experience with built-in data redundancy.

## Build/Test Commands
- Installation: `notelos.installer`
- No formal build system or tests
- Run scripts directly: `./bin/notelos`, `./bin/germ`, `./bin/epistle`, etc.

## Code Style Guidelines
- Shell scripts use `set -o errexit`, `set -o nounset`, `set -o pipefail`
- Functions are prefixed with underscore (_functionName)
- Global variables declared and exported explicitly
- Error handling through return codes and logging functions
- Logging functions: _debug, _info, _warn, _error, _ask
- Variable names are descriptive and prefixed with _notelos (e.g., _notelosDEBUG)
- Documentation in function headers and key sections

## Default Values
- Default working directory: $HOME/notelos
- Default development directory: $HOME/lab/notelos