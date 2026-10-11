#!/bin/bash

handle_interrupt() {
    trap '' INT TSTP
    echo
    echo "Deployment interrupted!"
    if [ -d "$dir_title" ]; then
        echo "Archiving the incomplete project..."
        zip -rq "${dir_title}_archive.zip" "$dir_title"
        echo "Saved to ${dir_title}_archive.zip"
        rm -rf "$dir_title"
    else
        echo "No project directory yet, nothing to archive."
    fi
    echo "Session closed."
    exit 130
}

deploy() {
    trap handle_interrupt INT TSTP

    if ! command -v python3 > /dev/null; then
        echo "Python3 is not installed"
        exit 1
    fi
    echo "Python verified: $(python3 --version)"

    if ! command -v zip > /dev/null; then
        echo "Zip is not installed"
        exit 1
    fi

    read -p "Enter project title: " title
    if [ -z "$title" ]; then
        echo "Project title can't be empty" >&2
        return
    fi

    dir_title="attendance_tracker_$title"
    echo "Creating project: $dir_title"

    if [ -d "$dir_title" ]; then
        read -p "Overwrite? (y/n): " reply
        if [ "$reply" = "y" ]; then
            rm -rf "$dir_title"
        else
            echo "Aborted: $dir_title kept"
            return
        fi
    fi

    mkdir -p "$dir_title/Helpers" "$dir_title/reports"
    cp templates/attendance_checker.py "$dir_title/"
    cp templates/config.json "$dir_title/Helpers/"

    echo "How do you want to build the roster?"
    echo "A) Copy from template"
    echo "B) Generate a fresh roster"
    read -p "Choose A or B: " roster_choice

    if [ "$roster_choice" = "A" ] || [ "$roster_choice" = "a" ]; then
        read -p "How many students to copy? " n
        head -n $((n + 1)) templates/assets.csv > "$dir_title/Helpers/assets.csv"
        echo "Copied $n students from the template"
    elif [ "$roster_choice" = "B" ] || [ "$roster_choice" = "b" ]; then
        names=("Alice Johnson" "Bob Smith" "Carol Williams" "David Brown" "Emma Davis" "Frank Miller" "Grace Wilson" "Henry Moore" "Isabella Taylor" "Jack Anderson")
        emails=("alice@example.com" "bob@example.com" "carol@example.com" "david@example.com" "emma@example.com" "frank@example.com" "grace@example.com" "henry@example.com" "isabella@example.com" "jack@example.com")
        read -p "How many students (1-10)? " n
        echo "Email,Names,Attendance Count,Absence Count" > "$dir_title/Helpers/assets.csv"
        for ((i = 0; i < n; i++)); do
            echo "${emails[$i]},${names[$i]},0,0" >> "$dir_title/Helpers/assets.csv"
        done
        sed -i 's/"total_sessions": [0-9]*/"total_sessions": 1/' "$dir_title/Helpers/config.json"
        echo "Generated $n students (total_sessions set to 1)"
    else
        echo "Invalid choice"
        trap - INT TSTP
        return
    fi

    chmod +x "$dir_title/attendance_checker.py"
    chmod 600 "$dir_title/Helpers/config.json"
    echo "Permissions set:"
    ls -l "$dir_title/attendance_checker.py" "$dir_title/Helpers/config.json"

    read -p "Update attendance alert thresholds? (y/n): " upd
    if [ "$upd" = "y" ]; then
        read -p "New warning threshold (default 75): " warn_val
        read -p "New failure threshold (default 50): " fail_val
        if [[ "$warn_val" =~ ^[0-9]+$ && "$fail_val" =~ ^[0-9]+$ ]]; then
            sed -i 's/"warning": [0-9]*/"warning": '"$warn_val"'/' "$dir_title/Helpers/config.json"
            sed -i 's/"failure": [0-9]*/"failure": '"$fail_val"'/' "$dir_title/Helpers/config.json"
            echo "Thresholds updated: warning=$warn_val, failure=$fail_val"
        else
            echo "Invalid numeric input. Keeping default thresholds."
        fi
    fi

    echo "Created $dir_title with app and config"
    echo "Verifying deployment by running the application..."
    trap - INT TSTP
    run_app "$dir_title"
}

run_app() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        echo "Project $dir does not exist. Deploy it first." >&2
        return 1
    fi
    echo "Starting the attendance checker..."
    ( cd "$dir" && python3 attendance_checker.py )
}

archive_logs() {
    read -p "Project title: " t
    local dir="attendance_tracker_$t"
    if [ ! -d "$dir" ]; then
        echo "Project $dir does not exist." >&2
        return 1
    fi

    local ts
    ts=$(date +%Y%m%d_%H%M%S)

    for name in attendance absent; do
        local src="$dir/reports/$name.log"
        if [ -f "$src" ]; then
            mkdir -p "$dir/archives/$name"
            mv "$src" "$dir/archives/$name/${name}_$ts.log"
            echo "Archived $name.log -> $dir/archives/$name/${name}_$ts.log"
        else
            echo "No $name.log found, skipping"
        fi
    done
}

echo "1) Deploy"
echo "2) Run"
echo "3) Archive"
echo "4) Exit"
read -p "Choose: " target

case "$target" in
    1) deploy ;;
    2) read -p "Project title: " t; run_app "attendance_tracker_$t" ;;
    3) archive_logs ;;
    4) exit 0 ;;
    *) echo "Invalid option" ;;
esac