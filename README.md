# atnow

Store and view you own murmur.

# Dependency

* Ruby
* Yad
* Zenity
* `xdg-user-dir`

# Configuration File

atnow uses `${XDG_CONFIG_HOME:-$HOME/.config}/reasonset/diary.yaml`.

It takes those keys:

|`atnow_dir`|Base directory for atnow entries (must be exist.)|
|`diary_dir`|Base directory for diary entries (must be exist.)|
|`pid_dir`|Temporaryr directory for put pid file. Used `/var/run/user/$UID` by default.|
|`atnow2diary`|If true, atnow outputs entry even today's diary file.|
|`editor`|Editor program used by diary.rb.|

# Usage

## atnow

1. Start `atnow.rb`
2. Icon will be in systray.
3. Click icon.
4. Murmuring.
5. Right click icon.
6. Click long murmur.

## diary

```bash
diary.rb <date_expression>
```

`date_expression` use through date(1) option, so you can use like `today`.

If `date_expression` is omitted, show calendar for choosing date.

# Advanced

* You can open murmuring window with HUPping to atnow process.
