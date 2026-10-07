deploy() {
    echo "Checking dependencies..."
    if ! command -v python3 >/dev/null 2>&1; then
        echo "ERROR: python3 not found"; return 1; fi
    python3 --version
    if ! command -v zip >/dev/null 2>&1; then
        echo "ERROR: zip not found"; return 1; fi

    read -p "Enter project name: " proj_name
    if [ -z "$proj_name" ]; then echo "cannot be empty"; return 1; fi
    PROJECT_DIR="attendance_tracker_${proj_name}"
    echo "Project will be: $PROJECT_DIR"

    # --- NEW PART STARTS HERE ---
    if [ -d "$PROJECT_DIR" ]; then
        read -p "Directory $PROJECT_DIR exists. Overwrite? (y/n): " ow
        if [ "$ow" = "y" ] || [ "$ow" = "Y" ]; then
            rm -rf "$PROJECT_DIR"
        else
            echo "Aborted"
            return 1
        fi
    fi

    mkdir -p "$PROJECT_DIR/Helpers" "$PROJECT_DIR/reports"
    if [ $? -ne 0 ]; then
        echo "Failed to create directories"
        return 1
    fi

    cp templates/attendance_checker.py "$PROJECT_DIR/"
    cp templates/config.json "$PROJECT_DIR/Helpers/"
    
    echo "Copied files:"
    ls -R "$PROJECT_DIR"
    # --- NEW PART ENDS HERE ---
}
