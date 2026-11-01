#!/usr/bin/env bash
set -Eeuo pipefail

PANEL="/var/www/pterodactyl"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="/root/rendzz-memo-backup-$STAMP.tar.gz"
INDEX="$PANEL/resources/scripts/index.tsx"
CSS="$PANEL/resources/scripts/rendzz-memo.css"

if [[ $EUID -ne 0 ]]; then
    echo "Jalankan dengan sudo."
    exit 1
fi

if [[ ! -f "$PANEL/package.json" || ! -f "$INDEX" ]]; then
    echo "Folder Pterodactyl tidak ditemukan."
    exit 1
fi

cd "$PANEL"

echo "======================================"
echo " RENDZZ MEMO SCREEN - FRONTEND APPLY"
echo "======================================"

echo "[1/6] Backup frontend..."
tar -czf "$BACKUP" \
    resources/scripts/index.tsx \
    public/assets

echo "Backup: $BACKUP"

rollback() {
    echo
    echo "Build gagal. Mengembalikan frontend lama..."
    tar -xzf "$BACKUP" -C "$PANEL"
    rm -f "$CSS"
    echo "Rollback selesai."
}

trap rollback ERR

echo "[2/6] Memasang Node.js 22..."

if ! command -v node >/dev/null 2>&1 ||
   [[ "$(node -p 'Number(process.versions.node.split(".")[0])')" -lt 22 ]]; then
    apt-get update
    apt-get install -y curl ca-certificates
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    apt-get install -y nodejs
fi

node --version
npm --version

echo "[3/6] Memasang Yarn..."

npm install --global yarn@1.22.22
yarn --version

echo "[4/6] Membuat theme CSS..."

cat > "$CSS" <<'CSS'
/* RENDZZ MEMO SCREEN - PTERODACTYL */

:root {
    --rz-bg: #080f1d;
    --rz-panel: #101d31;
    --rz-card: #14243c;
    --rz-blue: #328bff;
    --rz-light: #80bdff;
    --rz-border: rgba(100,160,235,.18);
}

/* Background */
html, body, #app {
    background-color: var(--rz-bg) !important;
}

/* Main surfaces */
body {
    background-image:
        radial-gradient(ellipse at 15% 0%, #17365d 0%, transparent 38%),
        radial-gradient(ellipse at 90% 15%, #102747 0%, transparent 35%);
    color: #edf5ff;
}

/* Common Pterodactyl surfaces */
.bg-neutral-800,
.bg-neutral-900 {
    background-color: var(--rz-panel) !important;
}

.bg-neutral-700 {
    background-color: var(--rz-card) !important;
}

/* Borders */
.border-neutral-700,
.border-neutral-800,
.border-neutral-600 {
    border-color: var(--rz-border) !important;
}

/* Inputs */
input, textarea, select {
    border-radius: 9px !important;
}

/* Buttons */
button {
    border-radius: 9px;
    transition: filter .2s ease, transform .2s ease;
}

button:hover {
    filter: brightness(1.12);
}

/* Links */
a {
    transition: color .2s ease;
}

a:hover {
    color: var(--rz-light);
}

/* Scrollbar */
::-webkit-scrollbar {
    width: 7px;
    height: 7px;
}

::-webkit-scrollbar-track {
    background: var(--rz-bg);
}

::-webkit-scrollbar-thumb {
    background: #28558c;
    border-radius: 20px;
}

/* Text selection */
::selection {
    background: var(--rz-blue);
    color: white;
}
CSS

echo "[5/6] Menghubungkan CSS ke React..."

if ! grep -q "rendzz-memo.css" "$INDEX"; then
    sed -i "1i import './rendzz-memo.css';" "$INDEX"
fi

echo "[6/6] Install dependency dan build frontend..."

chown -R www-data:www-data resources/scripts

su -s /bin/bash www-data -c \
    "cd '$PANEL' && yarn install --frozen-lockfile"

su -s /bin/bash www-data -c \
    "cd '$PANEL' && yarn build:production"

chown -R www-data:www-data public/assets

php artisan view:clear

trap - ERR

echo
echo "======================================"
echo " RENDZZ MEMO SCREEN BUILD BERHASIL"
echo "======================================"
echo "Backup: $BACKUP"
echo
echo "Buka panel dan lakukan hard refresh."
echo "Browser desktop: Ctrl + Shift + R"
echo "Browser HP: bersihkan cache situs."
echo "======================================"
