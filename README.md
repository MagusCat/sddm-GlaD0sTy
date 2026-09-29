```
 █████╗ ██████╗ ███████╗██████╗ ████████╗██╗   ██╗██████╗ ███████╗
██╔══██╗██╔══██╗██╔════╝██╔══██╗╚══██╔══╝██║   ██║██╔══██╗██╔════╝
███████║██████╔╝█████╗  ██████╔╝   ██║   ██║   ██║██████╔╝█████╗
██╔══██║██╔═══╝ ██╔══╝  ██╔══██╗   ██║   ██║   ██║██╔══██╗██╔══╝
██║  ██║██║     ███████╗██║  ██║   ██║   ╚██████╔╝██║  ██║███████╗
╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝
          S C I E N C E   ·   E N R I C H M E N T   C E N T E R
```

# GlaD0sTy — Secure Terminal Access Module

**Document AS-TRM-1998-GLaDOS** · Classification: *Test Subject Eyes Only* · Revision 2.0

> *"Hello, and again, welcome to the Aperture Science computer-aided enrichment center.
> This document will guide you through the installation of your new login terminal.
> Reading it is mandatory. Failure to read it will be noted in your permanent file."*

GlaD0sTy is a login theme for SDDM. It turns your login screen into an Aperture Science
terminal: orange-phosphor CRT, scanlines, glitches, and a resident artificial intelligence who
comments on your typing.

---

## §1 · Pre-Test Requirements

Before testing can begin, confirm that your test chamber (computer) contains the following
equipment. Missing equipment will result in a black screen, which is also a valid test outcome.

| Equipment                          | Debian / Ubuntu package                      |
|------------------------------------|----------------------------------------------|
| SDDM 0.21 or newer, Qt6 greeter    | `sddm` (provides `sddm-greeter-qt6`)         |
| Qt5Compat graphical effects module | `qml6-module-qt5compat-graphicaleffects`     |

```bash
sudo apt install sddm qml6-module-qt5compat-graphicaleffects
```

---

## §2 · Installation Procedure

Follow the steps in order. Do not skip steps. The last test subject who skipped steps is now
part of the chamber floor.

**Step 1.** Place the theme folder anywhere and run the installer as root:

```bash
sudo bash install.sh
```

The installer will:

1. Copy the theme to `/usr/share/sddm/themes/GlaD0sTy` (if it isn't already there).
2. Verify that all files are present and warn about missing equipment (§1).
3. Set `Current=GlaD0sTy` in **every** SDDM config file that selects a theme.
   Originals are stored in `/var/backups/GlaD0sTy/`, for science.
4. Deliver a brief message from GLaDOS. This message is not optional.

**Step 1 (manual alternative).** For subjects who distrust automated systems. Correctly.

```ini
# /etc/sddm.conf  (or any file in /etc/sddm.conf.d/)
[Theme]
Current=GlaD0sTy
```

**Step 2.** Run a supervised simulation before the real test. This does not log you out:

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/GlaD0sTy
```

**Step 3.** Log out or reboot. The terminal will be waiting. It is always waiting.

---

## §3 · Terminal Operation

| Input         | Result                                                          |
|---------------|-----------------------------------------------------------------|
| `Enter`/`Tab` | Advance to next field / submit credentials                      |
| `F1`          | Cycle desktop session                                           |
| `F2`          | Reboot. GLaDOS says goodbye first. You will listen.             |
| `F3`          | Shut down. Same farewell, followed by CRT power-off.            |


---

## §4 · Calibration (`theme.conf`)

All calibration happens in `theme.conf`. Editing `Main.qml` is not required and is
not covered by the Aperture Science warranty (Aperture Science offers no warranty).

| Parameter          | Default                  | Function                                                  |
|--------------------|--------------------------|-----------------------------------------------------------|
| `accent`           | `#d4953d`                | Phosphor color: text, glow, scan band                     |
| `alert`            | `#ff3333`                | ACCESS DENIED color                                       |
| `highlight`        | `#ffcc99`                | Hovered buttons                                           |
| `background`       | `#0a0a0a`                | Behind the background image                               |
| `backgroundImage`  | `assets/background.png`  | Base image. Relative to the theme folder, or absolute     |
| `gladosImage`      | `assets/glados.png`      | Portrait of the facility supervisor                       |
| `font`             | *(empty → `Dot.ttf`)*    | Font family. Must be installed in `/usr/share/fonts`: SDDM cannot see `~/.local/share/fonts` |
| `typeSpeed`        | `90`                     | Milliseconds per letter when GLaDOS types                 |
| `effects`          | `true`                   | `false` disables scanlines, glow, flicker, glitch, power-on |

Changes take effect the next time the login screen opens.

### §4.1 · Personality Core Dialogue

GLaDOS's lines live in the `[GLaDOS]` section of `theme.conf`. One line per key; the key
**prefix** decides when she says it. The number of lines is unlimited.

| Prefix  | Occasion                                   |
|---------|--------------------------------------------|
| `greet` | Terminal power-on                          |
| `idle`  | Every 20–45 seconds of silence             |
| `login` | Credentials submitted                      |
| `fail`  | Incorrect password                         |
| `bye`   | Before reboot or shutdown                  |

```ini
[GLaDOS]
greet1="Oh. It's you."
idle1="Are you still there?"
idle_cake="The cake is not a lie. Probably."
bye1="Goodbye. I'll be here. Thinking about all the testing we could have done."
```

Regulations:

- Every key must be **unique**. Duplicates are silently incinerated; only the last one survives.
- Numbers need not be consecutive. `idle1`, `idle7`, `idle_potato` are all valid.
- Wrap each line in `"double quotes"`. Escape inner quotes as `\"`.
- An empty category means silence. An empty `bye` still shuts down, just without closure.

---

## §5 · Facility Layout

```
GlaD0sTy/
├── Main.qml          # the terminal itself. Do not touch
├── theme.conf        # calibration and dialogue (§4)
├── metadata.desktop  # SDDM registration form
├── install.sh        # installation procedure (§2)
└── assets/
    ├── background.png
    ├── glados.png
    └── Dot.ttf       # 5x7 dot-matrix font
```

---

## §6 · Emergency Procedures

**Black screen / theme not loading.** Check the greeter log:

```bash
journalctl -b -u sddm
```

The most common cause is missing equipment from §1.

**Another theme appears.** Some other config file is overriding this one. SDDM reads every file
in `/etc/sddm.conf.d/`, then `/etc/sddm.conf`, and the last `Current=` wins:

```bash
grep -r '^Current=' /etc/sddm.conf /etc/sddm.conf.d/
```

**Revert to your previous theme.** Restore the originals from `/var/backups/GlaD0sTy/`,
or set `Current=` to the theme you want. GLaDOS will not take it personally.
She will simply remember.

---

<sub>Aperture Science is not responsible for lost keystrokes, lost sessions, or lost test subjects.
GLaDOS, Portal and Aperture Science are property of Valve Corporation. This is an unofficial fan
theme. The cake is a lie.</sub>

<sub>THE ART, FONTS, AND REFERENCED ELEMENTS USED ARE NOT MY INTELLECTUAL PROPERTY. USE AT YOUR OWN RISK. She is watching you.</sub>
<sub>You are free to edit, copy, and modify the code. Enjoy!</sub>
