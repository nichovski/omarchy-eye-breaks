# Omarchy Eye Breaks

**20-20-20 eye breaks for Omarchy, without stopping your work for long.**

Staring at a screen all day strains your eyes and gives you headaches. The
20-20-20 rule helps: every 20 minutes, look at something 20 feet (6 m) away for
20 seconds. Eye Breaks does it for you. After 20 minutes of screen time, all
your screens dim for 20 seconds with a countdown, then go back to normal by
themselves.

## Install

```bash
omarchy plugin add https://github.com/nichovski/omarchy-eye-breaks.git --enable
```

Omarchy asks where to put the bar widget. That is the whole installation.

## Remove

```bash
omarchy plugin remove nichovski.eye-breaks
```

This also removes the bar widget. To delete its status file too:

```bash
rm -rf ~/.local/state/eye-breaks
```

## Requirements

None beyond Omarchy. No packages, no network access, no sudo.

## Using it

- **The break:** after 20 minutes of screen use, every monitor dims for 20
  seconds and shows a countdown with "Look at something 6 m away and blink".
  It closes by itself. **Esc** skips it.
- **Water:** every third break (about once an hour) also says "Drink some water".
- **Away time counts as rest:** after 60 seconds without keyboard or mouse
  input, the 20-minute timer starts over.
- **Bar button:** an eye with the minutes until the next break, for example
  `20m`. Hover for details. **Click** to pause, for example during a meeting or
  screen share, and click again to resume. A pause lasts until you resume or
  the shell restarts.

## Commands

```bash
omarchy-shell eyes test     # open a break now
omarchy-shell eyes pause    # pause breaks
omarchy-shell eyes resume   # resume breaks
omarchy-shell eyes toggle   # pause or resume
omarchy-shell eyes status   # JSON: activeSeconds, secondsLeft, breaksDone, paused, breakOpen, idle
```

## How it works

- A service counts active screen time in 5-second steps and opens the
  full-screen overlay at 20 minutes.
- The service writes `~/.local/state/eye-breaks/status.json`, which the bar
  widget reads. This lets the widget work under replacement bars too (like the
  menubar manager), which do not give widgets access to plugin services.
- The times (20 minutes, 20 seconds, water every third break) are set at the
  top of `Service.qml`.

## License

MIT
