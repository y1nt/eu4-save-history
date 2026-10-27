# EU4 Save History — User Guide

This Windows tool watches your Europa Universalis IV save folder and keeps up to three versions of each save: **the latest version and the two previous versions**. It copies save files without modifying the originals.

## Getting started

1. Double-click **Start.cmd** in the `EU4Backup` folder.
2. Monitoring starts automatically. The default save folder is:
   `Documents\Paradox Interactive\Europa Universalis IV\save games`
3. Keep the tool running while you play. You can minimize its window. Closing the window stops backups.

No Python or additional software is required. The tool uses Windows PowerShell 5.1, included with Windows.

## Interface labels

The application interface is in Chinese:

| Label | Meaning |
| --- | --- |
| 存档目录 | Save folder |
| 选择… | Browse… |
| 暂停备份 | Pause backups |
| 开始备份 | Start backups |
| 打开备份文件夹 | Open backup folder |

To change the save folder, click **Pause backups**, select a folder with **Browse…**, then click **Start backups**. The selected folder is remembered for the next launch.

## How backups work

- On the first run, the tool saves a copy of every existing `.eu4` file directly inside the selected folder. It does not scan subfolders.
- When a file changes, the tool waits until its size and modification time have remained unchanged for four seconds, then attempts to copy it while preventing concurrent writes. If the file is busy or copying fails, it retries automatically.
- Each original file has its own backup subfolder under `EU4Backup\Backups`.
- Each file keeps up to three versions with distinct content from the immediately preceding backup. Rewriting identical content does not use another backup slot.
- After a new backup is saved successfully, versions older than the latest three are removed.
- EU4's own `_Backup.eu4` files are tracked separately from their corresponding main saves.

For example, after saves **A → B → C → D**, the tool keeps **B, C, and D**. The game file contains D, and you can restore either C or B.

Backup filenames contain the time the copy was created, in **UTC**. Hong Kong time is UTC + 8 hours. Sort filenames in descending order to see the newest backup first.

## Restoring a previous save

1. Exit EU4 and pause this tool.
2. Click **Open backup folder**.
3. Open the subfolder corresponding to the original save filename. The suffix in the folder name is an identifier used by the tool.
4. Sort backup filenames in descending order:
   - First: latest captured version.
   - Second: previous captured version.
   - Third: version from two backups ago.
5. Keep a separate copy of the current game save before replacing it.
6. Copy the chosen backup into the game's save folder and rename it to the original filename, for example `spa.eu4`.
7. Launch EU4 and load the restored save. Resume monitoring when you are ready to capture subsequent changes.

Restoring a save changes its content, so resuming monitoring may create a new backup and rotate the retained versions. Keep a separate copy of any version you want to preserve indefinitely.

The tool makes byte-for-byte copies. Save compatibility and achievement eligibility remain subject to the game's checks.

## Limitations and troubleshooting

- Start the tool before playing. It cannot recover versions that were overwritten before monitoring began.
- Changes made while the tool is closed, paused, or the computer is asleep cannot be captured individually.
- If a file is overwritten several times before it remains stable for four seconds, only the final stable version can be captured.
- The tool does not start automatically when Windows starts. Launch **Start.cmd** before each gaming session.
- If backups are not appearing, check the selected save folder and the status/log area. The tool retries temporary errors automatically. Diagnostic messages are also written to `activity.log` in the tool folder.
- You may move the entire `EU4Backup` folder to another writable location while the tool is closed. Keep the scripts and `Backups` folder together.

## Files in the tool folder

| File or folder | Purpose |
| --- | --- |
| `Start.cmd` | Launches the application |
| `EU4Backup.ps1` | Application interface |
| `Engine.ps1` | Backup and retention logic |
| `Backups` | Saved versions, grouped by original file |
| `settings.json` | Selected save folder; created when settings are saved |
| `activity.log` | Activity and diagnostic messages |
