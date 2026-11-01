cd /var/www/pterodactyl

cat > /root/install-rendzz-theme.sh <<'BASH'
#!/usr/bin/env bash
set -Eeuo pipefail

PANEL="/var/www/pterodactyl"
SCRIPTS="$PANEL/resources/scripts"
ENTRY="$SCRIPTS/index.tsx"
THEME="$SCRIPTS/theme.css"
BACKUP="/root/rendzz-theme-backup-$(date +%Y%m%d-%H%M%S)"

if [[ $EUID -ne 0 ]]; then
    echo "Jalankan sebagai root."
    exit 1
fi

cd "$PANEL"

for file in "$ENTRY" "$SCRIPTS/components/assets/css/GlobalStylesheet.tsx"; do
    [[ -f "$file" ]] || {
        echo "File tidak ditemukan: $file"
        exit 1
    }
done

mkdir -p "$BACKUP"
cp -a "$ENTRY" "$BACKUP/index.tsx"
[[ ! -f "$THEME" ]] || cp -a "$THEME" "$BACKUP/theme.css"

rollback() {
    echo "Build gagal. Melakukan rollback..."
    cp -a "$BACKUP/index.tsx" "$ENTRY"

    if [[ -f "$BACKUP/theme.css" ]]; then
        cp -a "$BACKUP/theme.css" "$THEME"
    else
        rm -f "$THEME"
    fi

    chown www-data:www-data "$ENTRY"
    echo "Rollback source selesai."
}

cat > "$THEME" <<'CSS'
/* RENDZZ OFFICIAL - DARK BLUE THEME */

:root {
    color-scheme: dark;
    --rz-bg: #080e1b;
    --rz-panel: #101a2d;
    --rz-panel-soft: #14213a;
    --rz-border: rgba(120, 160, 220, .14);
    --rz-blue: #398cff;
    --rz-cyan: #35c5f5;
    --rz-text: #e8f0ff;
    --rz-muted: #8b9bb5;
}

html, body, #app {
    min-height: 100%;
    background: var(--rz-bg) !important;
    color: var(--rz-text);
}

body {
    background-image:
        radial-gradient(ellipse at 15% 0%, rgba(36, 105, 210, .14), transparent 42%),
        radial-gradient(ellipse at 90% 20%, rgba(0, 180, 255, .07), transparent 35%) !important;
    background-attachment: fixed;
}

a {
    transition: color .2s ease, border-color .2s ease;
}

#app .bg-neutral-900 {
    background: rgba(9, 17, 32, .94) !important;
    border-bottom: 1px solid var(--rz-border);
    backdrop-filter: blur(16px);
}

#app .bg-neutral-800,
#app .bg-neutral-700 {
    background: var(--rz-panel) !important;
}

#app .bg-neutral-600 {
    background: var(--rz-panel-soft) !important;
}

#app .text-neutral-100,
#app .text-neutral-200 {
    color: var(--rz-text) !important;
}

#app .text-neutral-300,
#app .text-neutral-400,
#app .text-neutral-500 {
    color: var(--rz-muted) !important;
}

#app .border-neutral-700,
#app .border-neutral-800 {
    border-color: var(--rz-border) !important;
}

/* Navigation */
#app #logo a {
    font-weight: 800;
    letter-spacing: -.5px;
    color: #f3f7ff !important;
}

#app nav a:hover,
#app nav button:hover {
    color: var(--rz-cyan) !important;
}

/* Server cards */
#app a[class*="rounded"].bg-neutral-700,
#app a.bg-neutral-700 {
    border: 1px solid var(--rz-border);
    border-radius: 15px !important;
    background: linear-gradient(135deg, #14213a, #0d1729) !important;
    box-shadow: 0 8px 24px rgba(0, 0, 0, .16);
    transition: transform .2s ease, border-color .2s ease, box-shadow .2s ease;
}

#app a[class*="rounded"].bg-neutral-700:hover,
#app a.bg-neutral-700:hover {
    border-color: rgba(57, 140, 255, .55) !important;
    box-shadow: 0 12px 30px rgba(0, 0, 0, .24);
    transform: translateY(-2px);
}

#app .icon {
    background: rgba(57, 140, 255, .14) !important;
    color: var(--rz-cyan);
    border: 1px solid rgba(57, 140, 255, .2);
}

#app .status-bar {
    border-radius: 20px;
}

/* Login */
#app form > div.bg-white {
    background: linear-gradient(145deg, #14213a, #0d1729) !important;
    border: 1px solid var(--rz-border);
    border-radius: 20px !important;
    box-shadow: 0 25px 70px rgba(0, 0, 0, .3);
}

#app form input,
#app form select,
#app form textarea {
    background: #091326 !important;
    color: var(--rz-text) !important;
    border: 1px solid var(--rz-border) !important;
    border-radius: 10px !important;
}

#app form input:focus,
#app form select:focus,
#app form textarea:focus {
    border-color: var(--rz-blue) !important;
    box-shadow: 0 0 0 3px rgba(57, 140, 255, .13) !important;
    outline: none;
}

#app form button[type="submit"] {
    background: linear-gradient(110deg, #2475ed, #25a9ed) !important;
    color: white !important;
    border: 0 !important;
    border-radius: 10px !important;
    font-weight: 700;
    transition: filter .2s ease, transform .2s ease;
}

#app form button[type="submit"]:hover {
    filter: brightness(1.12);
    transform: translateY(-1px);
}

/* General panels and buttons */
#app .rounded-lg,
#app .rounded-xl {
    border-radius: 14px;
}

#app button {
    transition: filter .2s ease;
}

#app button:hover {
    filter: brightness(1.1);
}

/* Scrollbar */
* {
    scrollbar-width: thin;
    scrollbar-color: #28466e #091326;
}

*::-webkit-scrollbar {
    width: 7px;
    height: 7px;
}

*::-webkit-scrollbar-track {
    background: #091326;
}

*::-webkit-scrollbar-thumb {
    background: #28466e;
    border-radius: 20px;
}

/* Mobile */
@media (max-width: 640px) {
    #app form > div.bg-white {
        padding: 20px !important;
        margin: 0 !important;
    }

    #app #logo a {
        font-size: 17px !important;
    }

    #app a[class*="rounded"].bg-neutral-700 {
        padding: 13px !important;
    }
}

CSS

if grep -q "theme.css" "$ENTRY"; then
    echo "Theme sudah terhubung di index.tsx."
else
    sed -i "/import '.\\/i18n';/a import './theme.css';" "$ENTRY"
fi

chown www-data:www-data "$ENTRY" "$THEME"

echo "Membangun frontend production..."

if ! su -s /bin/bash www-data -c \
    'cd /var/www/pterodactyl && export HOME=/var/www YARN_CACHE_FOLDER=/var/www/.cache/yarn && yarn build:production'; then
    rollback
    exit 1
fi

php artisan view:clear
chown -R www-data:www-data "$PANEL/public/assets"
systemctl restart php8.3-fpm
systemctl reload nginx

echo
echo "======================================"
echo " RENDZZ OFFICIAL THEME BERHASIL DIPASANG"
echo "======================================"
echo "Backup: $BACKUP"
echo "Theme : $THEME"
echo "Silakan hard refresh browser."
BASH

chmod +x /root/install-rendzz-theme.sh
bash /root/install-rendzz-theme.sh
