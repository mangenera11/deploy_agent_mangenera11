# deploy_agent_mangenera11

deploy_agent.sh is a shell script that deploys, runs and archives the logs of the Student Attendance Tracker (attendance_checker.py, which I did not modify). It also handles Ctrl+C and Ctrl+Z safely while a deployment is running.

Video walkthrough: <PASTE YOUR VIDEO LINK HERE>

## Requirements
bash, python3 and zip.

## How to run it and select a feature
```
chmod +x deploy_agent.sh
./deploy_agent.sh
```
I used an interactive menu. Type a number and press Enter:
```
1) Deploy
2) Run
3) Archive
4) Exit
```
Each run performs one feature and then exits.

## Feature 1: Deploy
1. The script checks that python3 and zip are installed (and prints the python3 version). If one is missing it exits with a message.
2. It asks for a project title and creates attendance_tracker_<title>/ with Helpers/ and reports/. An empty title is rejected. If the folder already exists it asks "Overwrite? (y/n)": y rebuilds it, anything else aborts and keeps the old folder.
3. attendance_checker.py and config.json are copied unmodified from templates/.
4. It asks how to build the roster (Helpers/assets.csv):
   - **A (copy from template):** asks how many students (a whole number from 1 to 10) and copies the header plus that many rows using head.
   - **B (generate fresh):** asks how many students (1 to 10) and builds the rows from arrays of names and emails, with Attendance Count and Absence Count at 0.
   
   The student count is validated by a helper function, ask_number, which keeps asking until the input is a whole number inside the allowed range.
5. Permissions: attendance_checker.py is made executable (chmod +x) and Helpers/config.json is set to 600 (owner read/write only). The script prints them with ls -l.
6. Threshold update: it asks whether to update the alert thresholds. If yes, it reads a new warning value (1-100, default 75) and a new failure value (0-100, default 50). The failure value must be lower than the warning value. It then uses sed -i to change only the "warning" and "failure" lines in the deployed config.json. Nothing else in the file is reformatted.
7. Verification: the script finishes by running the application. A successful startup shows the structure, roster and config work together.

### total_sessions and the roster
total_sessions must be one more than the prior sessions in the roster.
- Option A: the template rows carry 4 prior sessions, so total_sessions stays at 5.
- Option B: the fresh roster has no prior sessions, so the script sets total_sessions to 1 with sed.

## Feature 2: Run
Asks for the project title, then runs:
```
cd attendance_tracker_<title>
python3 attendance_checker.py
```
The instructor marks each student Present or Absent. If the project folder does not exist, the script prints an error.

## Feature 3: Archive the logs
After a run, option 3 asks for the project title. For reports/attendance.log and reports/absent.log:
- If the log exists, it is moved into its own folder with a timestamp (YYYYMMDD_HHMMSS) in the name:
```
  attendance_tracker_<title>/archives/attendance/attendance_20261011_215154.log
  attendance_tracker_<title>/archives/absent/absent_20261011_215154.log
```
- A message shows each archived log and its final path.
- If a log does not exist (for example nobody was absent), the script prints "No <name>.log found, skipping" and carries on without crashing.

## Ctrl+C and Ctrl+Z handling
The script traps SIGINT (Ctrl+C) and SIGTSTP (Ctrl+Z) during deployment. The trap is turned off before the application runs, so it does not affect a marking session.

When either key is pressed, the script:
1. prints "Deployment interrupted!",
2. zips what exists so far into attendance_tracker_<title>_archive.zip,
3. deletes the half-built folder,
4. prints "Session closed." and exits.

**What the .zip contains** depends on when the interrupt happens. When I pressed Ctrl+Z at the roster prompt, `unzip -l` showed:
```
attendance_tracker_ztest/
attendance_tracker_ztest/Helpers/
attendance_tracker_ztest/Helpers/config.json
attendance_tracker_ztest/reports/
attendance_tracker_ztest/attendance_checker.py
```
There was no assets.csv because the roster step had not run yet.

**How to test it:** run ./deploy_agent.sh, choose 1, enter a title, and press Ctrl+C or Ctrl+Z at the roster prompt. Then run ls and unzip -l attendance_tracker_<title>_archive.zip.

## How I tested
- Deploy with Option A (3 students): assets.csv had the header and 3 rows, and total_sessions stayed 5.
- Deploy with Option B (4 students): the rows had 0,0 and total_sessions became 1.
- Invalid input: typing abc, 0 and 15 for the student count made the script ask again.
- Thresholds: 80 and 40 were accepted and only those two values changed; a failure value higher than the warning value was refused.
- Overwrite: answering y rebuilt the existing folder.
- Permissions: ls -l showed config.json as -rw------- and attendance_checker.py as -rwxr-xr-x.
- Run: the app started after deployment, I marked students (some absent), and both logs were created in reports/.
- Archive: both logs ended up in their own folders with timestamped names. Running archive again printed "skipping" and did not crash.
- Ctrl+C and Ctrl+Z: both created the _archive.zip and removed the half-built folder.
- Deployed structure: ls -R matched the required tree.