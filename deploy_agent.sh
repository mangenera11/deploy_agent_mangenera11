deploy() {
    echo "Checking dependencies..."
    
    if ! command -v python3 >/dev/null 2>&1; then
        echo "ERROR: python3 not found"
        return 1
    fi
    python3 --version

    if ! command -v zip >/dev/null 2>&1; then
        echo "ERROR: zip not found"
        return 1
    fi

    read -p "Enter project name: " proj_name
    if [ -z "$proj_name" ]; then
        echo "Project name cannot be empty"
        return 1
    fi

    PROJECT_DIR="attendance_tracker_${proj_name}"
    echo "Project will be: $PROJECT_DIR"
    
    # You will add mkdir, cp, roster, chmod, sed after this
}
