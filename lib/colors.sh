#!/usr/bin/env bash
# lib/colors.sh — ANSI color + formatting helpers shared across all commands

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

header()   { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; echo -e "${BOLD}${CYAN}  $1${RESET}"; echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; }
section()  { echo -e "\n${YELLOW}▶ $1${RESET}"; }
success()  { echo -e "${GREEN}✓ $1${RESET}"; }
error()    { echo -e "${RED}✗ $1${RESET}" >&2; }
dim()      { echo -e "${DIM}  $1${RESET}"; }
none()     { echo -e "${DIM}  (none)${RESET}"; }

# Print a two-column key/value line
kv() { printf "  ${BOLD}%-20s${RESET} %s\n" "$1" "$2"; }
