#!/usr/bin/env bash
# Build the DuoOS ISO. Run on an Arch Linux machine (or Arch container/VM) with internet.
#   sudo ./build.sh        ->  ./out/duoos-*.iso
set -euo pipefail
[ "$EUID" -eq 0 ] || exec sudo "$0" "$@"
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d /tmp/duoos-work.XXXX)"
P="$WORK/profile"

pacman -S --needed --noconfirm archiso git

# 1) Chaotic-AUR (prebuilt FireDragon + debtap): keys & mirrorlist on the build host
if ! pacman-key --list-keys 3056513887B78AEB >/dev/null 2>&1; then
  pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
  pacman-key --lsign-key 3056513887B78AEB
fi
pacman -Q chaotic-keyring chaotic-mirrorlist >/dev/null 2>&1 || pacman -U --noconfirm \
  'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
  'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

# 2) start from the official 'releng' profile (boot loaders, installer tools, etc.)
cp -r /usr/share/archiso/configs/releng "$P"

# 3) enable Chaotic-AUR in the profile and inside the ISO
grep -q '^\[chaotic-aur\]' "$P/pacman.conf" || printf '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' >> "$P/pacman.conf"
mkdir -p "$P/airootfs/etc"; cp "$P/pacman.conf" "$P/airootfs/etc/pacman.conf"

# 4) packages
grep -vE '^\s*(#|$)' "$HERE/packages.duo" >> "$P/packages.x86_64"

# 5) overlay (our configs, scripts, launchers, services)
cp -a "$HERE/overlay/airootfs/." "$P/airootfs/"
chmod +x "$P/airootfs/usr/local/bin/"*
# 'apt' and 'apt-get' on the Arch host are shims that run apt inside the Debian layer
ln -sf duo-debian "$P/airootfs/usr/local/bin/apt"
ln -sf duo-debian "$P/airootfs/usr/local/bin/apt-get"

# 6) swap releng's iwd/networkd for NetworkManager; enable our live-user service
find "$P/airootfs/etc/systemd/system" \( -lname '*iwd*' -o -lname '*systemd-networkd*' -o -lname '*systemd-resolved*' \) -delete 2>/dev/null || true
W="$P/airootfs/etc/systemd/system/multi-user.target.wants"; mkdir -p "$W"
ln -sf /usr/lib/systemd/system/NetworkManager.service "$W/NetworkManager.service"
ln -sf /etc/systemd/system/duo-live-user.service      "$W/duo-live-user.service"

# 7) branding + permissions
sed -i 's/^iso_name=.*/iso_name="duoos"/; s/^iso_label=.*/iso_label="DUOOS_$(date +%Y%m)"/; s/^iso_application=.*/iso_application="DuoOS Live\/Install"/' "$P/profiledef.sh"
cat >> "$P/profiledef.sh" <<'EOP'
file_permissions+=(
  ["/etc/sudoers.d/10-live"]="0:0:440"
  ["/usr/local/bin/duo-debian"]="0:0:755"
  ["/usr/local/bin/duo-deb-open"]="0:0:755"
)
EOP

# 8) go
mkarchiso -v -w "$WORK/work" -o "$HERE/out" "$P"
echo "Done: $(ls "$HERE"/out/duoos-*.iso | tail -1)"
