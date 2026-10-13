# deploy_agent_mangenera11

`deploy_agent.sh` is a shell script that **deploys**, **runs** and **archives the logs** of the Student Attendance Tracker (`attendance_checker.py`, which I did not modify). It also handles Ctrl+C and Ctrl+Z safely while a deployment is in progress.

**Video walkthrough:** <PASTE YOUR VIDEO LINK HERE>

## Repository contents
```
deploy_agent_mangenera11/
├── deploy_agent.sh
├── README.md
└── templates/
    ├── attendance_checker.py   (unmodified)
    ├── assets.csv              (unmodified, 10 students with 4 prior sessions each)
    └── config.json             (unmodified)
```

## Requirements
`bash`, `python3` and `zip`.

## How to run the script and select a feature
```bash
chmod +x deploy_agent.sh
./deploy_agent.sh
```
I chose an **interactive menu**. The script shows:
```
1) Deploy
2) Run
3) Archive
4) Exit
Choose:
```
Type the number and press Enter. Each run performs one feature and then exits. Run the script again for the next feature.

## Feature 1: Deploy
1. **Pre-flight checks:** the script checks that `python3` and `zip` are installed using `command -v`. It prints the python3 version, or exits with a message if either tool is missing.
2. **Project name:** it asks for a project title and creates `attendance_tracker_<title>/`. An empty title is rejected. If the folder already exists, the script asks `Overwrite? (y/n)`. Answering `y` deletes and rebuilds it. Anything else aborts and keeps the existing folder, so nothing is overwritten silently.
3. **Structure and files:** it creates `Helpers/` and `reports/`, then copies `attendance_checker.py` and `config.json` unmodified from `templates/`.
4. **Roster:** it asks how to build `Helpers/assets.csv`:
   - **A: copy from the template.** It asks how many students to copy and copies the header plus that many rows with `head -n`.
   - **B: generate a fresh roster.** It asks how many students (1-10) and builds that many rows directly in the script from arrays of names and emails that I defined. Attendance Count and Absence Count start at `0`.
5. **Permissions:** `chmod +x` makes `attendance_checker.py` executable, and `chmod 600` restricts `Helpers/config.json` to owner read/write because it holds the grading-sensitive thresholds. The script prints the result with `ls -l`.
6. **Threshold update:** it asks `Update attendance alert thresholds? (y/n)`. If yes, it reads a new warning value (default 75) and a new failure value (default 50). Both must be whole numbers. Otherwise the script prints `Invalid number. Keeping default thresholds.` and leaves the file as it is. If valid, it uses `sed -i` to change only the `"warning":` and `"failure":` lines of the deployed `config.json`. Nothing is reformatted or reordered.
7. **Verification:** the script finishes by running the application (Feature 2). A successful startup shows that the structure, roster and config work together.

### How `total_sessions` relates to the roster
`total_sessions` is the total number of sessions including today, so it must always be one more than the prior sessions in the roster.
- **Option A:** the template rows carry 4 prior sessions, so `"total_sessions": 5` from the template is already correct and is left as it is.
- **Option B:** the fresh roster has no prior sessions, so the script sets `"total_sessions": 1` with `sed -i`.

No prompt is needed because the script picks the correct value automatically.

## Feature 2: Run
Choose option 2 and enter the project title. The script runs:
```bash
cd attendance_tracker_<title>
python3 attendance_checker.py
```
This hands the terminal to the instructor for the interactive marking session (Present or Absent for each student). The `cd` happens inside a subshell, so the script stays in its own folder afterwards. If the project does not exist, the script prints an error and returns.

## Feature 3: Archive the log files
Choose option 3 and enter the project title. For each of `reports/attendance.log` and `reports/absent.log`:
- If the log exists, it is **moved** into its own archive directory with a timestamp (`YYYYMMDD_HHMMSS`) in the filename:
  ```
  attendance_tracker_<title>/archives/attendance/attendance_20261011_215154.log
  attendance_tracker_<title>/archives/absent/absent_20261011_215154.log
  ```
- A confirmation line shows each archived log and its final path.
- If a log does not exist (for example nobody was absent, so `absent.log` was never created), the script prints `No <name>.log found skipping` and carries on without crashing.

Both logs from one run share the same timestamp, so every archived copy is unique and traceable.

## Signal handling (Ctrl+C and Ctrl+Z)
While a deployment is in progress, the script traps `SIGINT` (Ctrl+C) and `SIGTSTP` (Ctrl+Z). The trap is set at the start of the deploy feature and removed just before the application is started, so it never interferes with a marking session. It is for the shell script only, not for `attendance_checker.py`.

When either key is pressed, `handle_interrupt`:
1. prints `Deployment stopped by user!`,
2. zips the incomplete project with `zip -rq attendance_tracker_<title>_archive.zip attendance_tracker_<title>` (a real `.zip` file),
3. deletes the half-built directory,
4. prints `Deployment session closed.` and exits.

If the signal arrives before the project directory exists, it prints that there is nothing to archive and exits.

### How to test it
1. Run `./deploy_agent.sh`, choose `1` and enter a title such as `cc`.
2. At the roster prompt (`Choose A or B:`), press **Ctrl+C**. Repeat with another title and press **Ctrl+Z**.
3. Check the result:
   ```bash
   ls
   unzip -l attendance_tracker_cc_archive.zip
   ```
   The zip should exist, and the folder `attendance_tracker_cc` should be gone.

### What the `.zip` archive contains
It contains whatever had been created at the moment of the interrupt. When I pressed Ctrl+Z at the roster prompt, `unzip -l` showed:
```
attendance_tracker_ztest/
attendance_tracker_ztest/Helpers/
attendance_tracker_ztest/Helpers/config.json
attendance_tracker_ztest/reports/
attendance_tracker_ztest/attendance_checker.py
```
There was no `Helpers/assets.csv` because the roster had not been built yet. If the interrupt happens later (for example at the threshold question), the zip also contains `assets.csv`.

## How I tested
| Test | What I checked | Result |
|---|---|---|
| Deploy, Option A (3 students) | `cat Helpers/assets.csv`, `grep total Helpers/config.json` | Header plus 3 rows with prior sessions; `total_sessions` stayed 5 |
| Deploy, Option B (4 students) | same commands | 4 rows with `0,0`; `total_sessions` became 1 |
| Overwrite an existing project | answered `y`, then `n` | `y` rebuilt the folder; `n` aborted and kept it |
| Permissions | `ls -l` | `config.json` is `-rw-------`; `attendance_checker.py` is `-rwxr-xr-x` |
| Threshold update (80 / 40) | `cat Helpers/config.json` | Only the two values changed; layout and other keys unchanged |
| Non-numeric threshold (`abc`) | `cat Helpers/config.json` | Defaults kept, error message shown |
| Run / verification | marked students, some absent | App started after deployment; `reports/attendance.log` and `reports/absent.log` created |
| Archive | `find <project>/archives` | Both logs in their own folders with timestamped names; `reports/` empty |
| Archive again with no logs | ran option 3 twice | `No ... found skipping` for both logs; no crash |
| Ctrl+C mid-deploy | pressed at the roster prompt | `_archive.zip` created, half-built folder removed |
| Ctrl+Z mid-deploy | pressed at the roster prompt | Same result; `unzip -l` lists the partial project |
| Deployed structure | `ls -R attendance_tracker_<title>` | Matches the required tree (`Helpers/`, `reports/`, `attendance_checker.py`) |
