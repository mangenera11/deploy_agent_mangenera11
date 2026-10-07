deploy() {
    echo "Checking dependencies..."
    if ! command -v python3 >/dev/null 2>&1; then
        echo "ERROR: python3 not found"; return 1; fi
    python3 --version
    if ! command -v zip >/dev/null 2>&1; then
        echo "ERROR: zip not found"; return 1; fi

    read -p "Enter project name: " proj_name
    if [ -z "$proj_name" ]; then echo "Project name cannot be empty"; return 1; fi
    PROJECT_DIR="attendance_tracker_${proj_name}"
    
    if [ -d "$PROJECT_DIR" ]; then
        read -p "Directory $PROJECT_DIR exists. Overwrite? (y/n): " ow
        if [ "$ow" = "y" ] || [ "$ow" = "Y" ]; then
            rm -rf "$PROJECT_DIR"
        else
            echo "Aborted"; return 1; fi
    fi

    mkdir -p "$PROJECT_DIR/Helpers" "$PROJECT_DIR/reports"
    if [ $? -ne 0 ]; then echo "Failed to create directories"; return 1; fi

    cp templates/attendance_checker.py "$PROJECT_DIR/"
    cp templates/config.json "$PROJECT_DIR/Helpers/"
    echo "Copied fixed files"

    read -p "Choose roster option A(copy) or B(generate) [A/B]: " roster_opt
    read -p "How many students (1-10)?: " num_students
    if ! [[ "$num_students" =~ ^[0-9]+$ ]] || [ "$num_students" -lt 1 ] || [ "$num_students" -gt 10 ]; then
        echo "Invalid number. Must be 1-10"; return 1; fi

    if [ "$roster_opt" = "A" ] || [ "$roster_opt" = "a" ]; then
        head -n $((num_students+1)) templates/assets.csv > "$PROJECT_DIR/assets.csv"
        sed -i 's/"total_sessions":.*/\"total_sessions\": 5,/' "$PROJECT_DIR/Helpers/config.json"
    elif [ "$roster_opt" = "B" ] || [ "$roster_opt" = "b" ]; then
        echo "email,name,present,absent" > "$PROJECT_DIR/assets.csv"
        names=("Alice" "Bob" "Charlie" "David" "Eva" "Frank" "Grace" "Henry" "Ivy" "Jack")
        emails=("alice@example.com" "bob@example.com" "charlie@example.com" "david@example.com" "eva@example.com" "frank@example.com" "grace@example.com" "henry@example.com" "ivy@example.com" "jack@example.com")
        for ((i=0; i<num_students; i++)); do
            idx=$((i % 10))
            echo "${emails[$idx]},${names[$idx]},0,0" >> "$PROJECT_DIR/assets.csv"
        done
        sed -i 's/"total_sessions":.*/\"total_sessions\": 1,/' "$PROJECT_DIR/Helpers/config.json"
    else
        echo "Invalid roster option"; return 1; fi

    chmod +x "$PROJECT_DIR/attendance_checker.py"
    chmod 600 "$PROJECT_DIR/Helpers/config.json"
    ls -l "$PROJECT_DIR/attendance_checker.py" "$PROJECT_DIR/Helpers/config.json"
    
    echo "Deploy completed: $PROJECT_DIR"
    echo "Contents:"
    cat "$PROJECT_DIR/assets.csv"
    cat "$PROJECT_DIR/Helpers/config.json"
}
