#!/bin/bash
# GlaD0sTy installer: copies the theme (when run from another folder) and makes it SDDM's current theme.
set -e

THEME=GlaD0sTy
THEME_DIR="/usr/share/sddm/themes/$THEME"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="/var/backups/$THEME"
ORANGE='\e[38;5;208m'; DIM='\e[2m'; RESET='\e[0m'

[ "$EUID" -eq 0 ] || { echo "Run as root: sudo bash $0"; exit 1; }

echo -e "${ORANGE}APERTURE SCIENCE // $THEME installer${RESET}\n"

if [ "$SRC_DIR" != "$THEME_DIR" ]; then
    mkdir -p "$THEME_DIR"
    cp -r "$SRC_DIR"/. "$THEME_DIR"/
    echo "✓ Copied to $THEME_DIR"
fi

for f in Main.qml theme.conf metadata.desktop assets/Dot.ttf assets/glados.png assets/background.png; do
    [ -f "$THEME_DIR/$f" ] || { echo "✗ Missing $f"; exit 1; }
done
echo "✓ Theme files present"

# Runtime dependencies: warn only, package names are Debian's
command -v sddm-greeter-qt6 >/dev/null || echo "⚠ sddm-greeter-qt6 not found (needs SDDM ≥ 0.21 built with Qt6)"
find /usr/lib -maxdepth 5 -path '*qt6/qml/Qt5Compat/GraphicalEffects' -print -quit | grep -q . \
    || echo "⚠ Qt5Compat.GraphicalEffects missing: apt install qml6-module-qt5compat-graphicaleffects"

# SDDM reads every file in sddm.conf.d and then sddm.conf; the last Current= wins,
# so switch all of them. Backups go outside sddm.conf.d or SDDM would read them too.
mapfile -t confs < <(grep -ls '^Current=' /etc/sddm.conf /etc/sddm.conf.d/* 2>/dev/null || true)
if [ ${#confs[@]} -eq 0 ]; then
    mkdir -p /etc/sddm.conf.d
    printf '[Theme]\nCurrent=%s\n' "$THEME" > /etc/sddm.conf.d/glad0sty.conf
    echo "✓ Created /etc/sddm.conf.d/glad0sty.conf"
else
    mkdir -p "$BACKUP_DIR"
    stamp=$(date +%Y%m%d-%H%M%S)
    for c in "${confs[@]}"; do
        cp "$c" "$BACKUP_DIR/$(basename "$c").$stamp"
        sed -i "s/^Current=.*/Current=$THEME/" "$c"
        echo "✓ $c → Current=$THEME"
    done
    echo -e "${DIM}  backups in $BACKUP_DIR${RESET}"
fi

echo -e "\n${DIM}Preview: sddm-greeter-qt6 --test-mode --theme $THEME_DIR"
echo -e "Settings, colors and GLaDOS lines: $THEME_DIR/theme.conf${RESET}\n"

# Parting words, typed like on the login screen
lines=(
    "Oh. You installed me. How thoughtful. I'll be waiting at the login screen. Watching."
    "Installation complete. This computer now belongs to Aperture Science. Please log out to begin testing."
    "Congratulations. You installed a login screen. Truly the pinnacle of your achievements."
    "Theme installed. I also disabled your safety protocols. That was a joke. Probably."
)
msg="GLaDOS: ${lines[RANDOM % ${#lines[@]}]}"
echo -ne "$ORANGE"
for ((i = 0; i < ${#msg}; i++)); do printf '%s' "${msg:i:1}"; sleep 0.04; done
echo -e "_${RESET}"
