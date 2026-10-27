# EU4 Save History / EU4 存档时光机

A lightweight Windows backup tool for Europa Universalis IV. Keeps the latest save and two previous versions of each save file.

一个轻量的 Windows EU4 存档备份工具，为每个存档保留 **最新版本 + 前一次 + 前两次**，方便在铁人模式自动存档被覆盖后回退。

[中文说明](#中文说明) · [English](#english) · [Detailed English guide](README-English.md)

## 中文说明

### 快速开始

1. 下载本仓库并解压，或使用 Git 克隆仓库。
2. 双击 `Start.cmd`，工具立即开始监视存档目录。
3. 玩游戏时保持工具运行，可以最小化。关闭窗口即停止备份。

默认监视 Windows“文档”中的 `Paradox Interactive\Europa Universalis IV\save games` 文件夹。修改路径时，先点击“暂停备份”，再选择目录，最后点击“开始备份”。

运行环境：Windows 和系统自带的 Windows PowerShell 5.1，无需安装 Python。界面目前为中文。

### 备份规则

- 首次运行先保存现有 `.eu4` 文件，仅监视所选目录第一层。
- 文件大小和修改时间稳定 4 秒后，尝试锁定读取并复制；文件占用或失败时自动重试。
- 每个原始文件独立保留最多三份备份，位于工具目录的 `Backups` 文件夹。
- 与最近一次备份内容相同的写入不会新增版本。
- 先写好新备份，再移除最旧版本；原游戏存档不被修改。
- 游戏自带的 `_Backup.eu4` 文件也会单独备份。

例如先后保存 **A → B → C → D** 后，保留 **B、C、D**，可回退到 C 或 B。备份文件名为 UTC 时间，香港时间需加 8 小时；按文件名降序排列即可从新到旧查看。

### 恢复存档

1. 退出 EU4，并暂停工具。
2. 点击“打开备份文件夹”，进入对应原存档名称的子文件夹。
3. 按文件名降序排列：第一个为最新版本，第二个为前一次，第三个为前两次。
4. 先另行保留游戏目录中的当前存档，再把所选备份复制回游戏存档目录，改成原来的文件名，例如 `spa.eu4`。
5. 启动游戏加载存档；需要继续捕捉后续变化时恢复监视。

恢复监视后，恢复的存档可能被识别为新版本并触发轮换。需要永久保留的版本请单独复制到其他目录。工具逐字节复制文件，能否加载以及成就资格由游戏判断。

### 注意事项

- 无法找回工具启动之前已被覆盖的版本。
- 工具关闭、暂停或电脑休眠期间，不能逐次留存存档变化。
- 同一文件在稳定等待期间连续覆盖多次，只会捕捉最后一个稳定版本。
- 不自动开机启动，每次游戏前请运行 `Start.cmd`。
- 备份失败时查看窗口日志或 `activity.log`，并确认目录存在且可写。
- 存档、备份、个人路径配置和日志已通过 `.gitignore` 排除，不应提交到仓库。

## English

### Quick start

1. Download and extract this repository, or clone it with Git.
2. Double-click `Start.cmd`. Monitoring starts automatically.
3. Keep the tool running while you play. You may minimize it; closing its window stops backups.

The default location is `Paradox Interactive\Europa Universalis IV\save games` inside your Windows Documents folder. To change it, pause monitoring, select a folder, and start monitoring again.

Requirements: Windows with its built-in Windows PowerShell 5.1. No Python installation is needed. The application interface is currently in Chinese.

| Interface label | Meaning |
| --- | --- |
| 暂停备份 | Pause backups |
| 开始备份 | Start backups |
| 选择… | Browse… |
| 打开备份文件夹 | Open backup folder |

### Backup behavior

- Captures existing `.eu4` files on startup; only watches the selected folder's top level.
- Waits for four seconds of unchanged file size and modification time before attempting a copy that prevents concurrent writes. Busy files and failures are retried.
- Keeps up to three versions per original file in separate subfolders under `Backups`.
- Skips writes whose content matches the most recent backup.
- Publishes each new backup before removing older versions. Original game saves are never modified.
- Tracks EU4's own `_Backup.eu4` files independently.

After saves **A → B → C → D**, the retained versions are **B, C, and D**, allowing rollback to C or B. Backup filenames use UTC; sort names in descending order to see the newest first.

### Restore a save

1. Exit EU4 and pause this tool.
2. Open the backup folder and find the subfolder for the original save.
3. Sort filenames in descending order. The first file is the latest captured version, the second is the previous version, and the third is two backups ago.
4. Preserve a separate copy of the current game save. Copy your chosen backup into the game's save folder and rename it to the original filename, such as `spa.eu4`.
5. Launch EU4 and load the save. Resume monitoring when you want to capture subsequent changes.

Resuming monitoring after restoration can create a new version and rotate backups. Keep any version you want to preserve permanently in a separate folder. Copies are byte-for-byte; compatibility and achievement eligibility remain subject to the game's checks.

### Limitations

- Versions overwritten before monitoring began cannot be recovered.
- Changes while the tool is closed, paused, or the computer is asleep cannot be captured individually.
- Multiple rapid overwrites before the file becomes stable may produce only one captured version.
- Automatic startup is not configured. Launch `Start.cmd` before playing.
- Check the window log or `activity.log` if backups fail, and verify folder access.
- Saves, backups, local configuration, and logs are excluded through `.gitignore` and should not be committed.

See [the detailed English guide](README-English.md) for further instructions and file descriptions.
