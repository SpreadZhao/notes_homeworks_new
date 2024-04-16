---
title: KDE Store & add cursor packs
date: 2024-04-16
tags:
  - softwareqa/linux
mtrace:
  - 2024-04-16
---

# KDE Store & add cursor packs

kde store: [KDE Store](https://store.kde.org/browse/)

miku cursor as sample: [supermariofps/hatsune-miku-windows-linux-cursors: Hatsune Miku Cursors for Windows/Linux!](https://github.com/supermariofps/hatsune-miku-windows-linux-cursors)

1. Copy the `miku-cursor-linux/` dir to `/usr/share/icons/` (system-wide) or `~/.local/share/icons/` (per-user).
2. [Select the theme through your DE's settings manager.](https://wiki.archlinux.org/title/Cursor_themes#Desktop_environments)
3. On KDE, the desktop and some apps may default back to a different cursor set that isn't the one you chose. To fix this, add the following to `/usr/share/icons/default/index.theme` or `~/.local/share/icons/default/index.theme`:

	```ini
	[Icon Theme]
	Inherits=miku-cursor-linux
	```