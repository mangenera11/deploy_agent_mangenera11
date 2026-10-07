#!/bin/bash

# Global variable for trap handler to use
PROJECT_DIR=""

deploy() {
    echo "=== Deploy feature - TODO ==="
    # TODO 1: pre-flight checks - command -v python3, command -v zip, python3 --version
    # TODO 2: read -p project name, reject empty
    # TODO 3: check if directory exists [ -d ], ask overwrite
    # TODO 4: mkdir -p Helpers reports
    # TODO 5: copy templates/attendance_checker.py and templates/config.json
    # TODO 6: roster - Option A head -n or Option B loop
    # TODO 7: chmod +x and chmod 600
    # TODO 8: threshold update with sed -i
    # TODO 9: call run_app at end
}

run_app() {
    echo "=== Run feature - TODO ==="
    # TODO: ask project name, cd into it and python3 attendance_checker.py in subshell
}

archive_logs() {
    echo "=== Archive feature - TODO ==="
    # TODO: mkdir -p archives/attendance archives/absent
    # TODO: date +%Y%m%d_%H%M%S timestamp
    # TODO: check [ -f reports/attendance.log ] and move/copy with timestamp
}

# Menu loop
while true; do
    echo ""
    echo "1) Deploy  2) Run  3) Archive  4) Exit"
    read -p "Choose [1-4]: " choice
    case $choice in
        1) deploy ;;
        2) run_app ;;
        3) archive_logs ;;
        4) echo "Bye"; exit 0 ;;
        *) echo "Invalid choice" ;;
    esac
done
