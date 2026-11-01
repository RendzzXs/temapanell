cat > /root/install-rendzz.sh <<'BASH'
#!/usr/bin/env bash
set -Eeuo pipefail

PANEL="/var/www/pterodactyl"
RAW="https://raw.githubusercontent.com/RendzzXs/temapanell/main"
WORK="/tmp/rendzz-install"
BACKUP="/root/rendzz-backup-$(date +%Y%m%d-%H%M%S)"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log(){ echo -e "${BLUE}[RENDZZ]${NC} $*"; }
ok(){ echo -e "${GREEN}[OK]${NC} $*"; }
fail(){ echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

[[ $EUID -eq 0 ]] || fail "Jalankan sebagai root."
[[ -d "$PANEL" ]] || fail "Folder Pterodactyl tidak ditemukan: $PANEL"
[[ -f "$PANEL/package.json" ]] || fail "package.json tidak ditemukan."

command -v curl >/dev/null || {
    apt-get update
    apt-get install -y curl
}

command -v tar >/dev/null || apt-get install -y tar

mkdir -p "$WORK" "$BACKUP"

rollback(){
    log "Terjadi kegagalan. Memulai rollback..."
    if [[ -f "$BACKUP/index.tsx" ]]; then
        cp -a "$BACKUP/index.tsx" "$PANEL/resources/scripts/index.tsx"
    fi
    if [[ -f "$BACKUP/theme.css" ]]; then
        cp -a "$BACKUP/theme.css" "$PANEL/resources/scripts/theme.css"
    elif [[ -f "$PANEL/resources/scripts/theme.css" ]]; then
        rm -f "$PANEL/resources/scripts/theme.css"
    fi
    if [[ -f "$BACKUP/assets.tar.gz" ]]; then
        tar -xzf "$BACKUP/assets.tar.gz" -C "$PANEL"
    fi
    chown -R www-data:www-data "$PANEL/resources/scripts" "$PANEL/public/assets" 2>/dev/null || true
    fail "Rollback selesai. Backup tersimpan di $BACKUP"
}

trap rollback ERR

log "Memeriksa dependensi..."
command -v node >/dev/null || fail "Node.js belum terpasang."
command -v yarn >/dev/null || fail "Yarn belum terpasang."
command -v php >/dev/null || fail "PHP belum terpasang."

NODE_VERSION="$(node -p 'Number(process.versions.node.split(".")[0])')"
(( NODE_VERSION >= 22 )) || fail "Butuh Node.js 22 atau lebih baru."

ENTRY="$PANEL/resources/scripts/index.tsx"
[[ -f "$ENTRY" ]] || fail "index.tsx tidak ditemukan."

log "Membuat backup..."
cp -a "$ENTRY" "$BACKUP/index.tsx"

if [[ -f "$PANEL/resources/scripts/theme.css" ]]; then
    cp -a "$PANEL/resources/scripts/theme.css" "$BACKUP/theme.css"
fi

if [[ -d "$PANEL/public/assets" ]]; then
    tar -czf "$BACKUP/assets.tar.gz" -C "$PANEL" public/assets
fi

log "Mengunduh tema dari GitHub Raw..."
curl -fLsS "$RAW/theme.css" -o "$WORK/theme.css" ||
curl -fLsS "$RAW/rendzz.css" -o "$WORK/theme.css" ||
fail "File theme.css atau rendzz.css tidak ditemukan di repository."

[[ -s "$WORK/theme.css" ]] || fail "CSS kosong."

log "Memasang stylesheet..."
install -m 644 "$WORK/theme.css" "$PANEL/resources/scripts/theme.css"

if ! grep -Fq "import './theme.css';" "$ENTRY"; then
    sed -i "/import '.\\/i18n';/a import './theme.css';" "$ENTRY"
fi

grep -Fq "import './theme.css';" "$ENTRY" ||
    fail "Import tema gagal dipasang."

log "Memperbaiki permission..."
mkdir -p /var/www/.cache/yarn
touch /var/www/.yarnrc
chown -R www-data:www-data /var/www/.cache
chown www-data:www-data /var/www/.yarnrc
chmod 755 /var/www
chmod 755 "$PANEL"
chown -R www-data:www-data "$PANEL/resources/scripts"

log "Membangun frontend production..."
su -s /bin/bash www-data -c \
    "cd '$PANEL' && export HOME=/var/www YARN_CACHE_FOLDER=/var/www/.cache/yarn && yarn build:production"

log "Membersihkan cache Laravel..."
cd "$PANEL"
php artisan view:clear
php artisan cache:clear
php artisan config:clear

log "Memperbaiki permission aset..."
chown -R www-data:www-data "$PANEL/public/assets"

systemctl reload nginx || true
systemctl restart php8.3-fpm 2>/dev/null ||
systemctl restart php8.2-fpm 2>/dev/null ||
systemctl restart php8.1-fpm 2>/dev/null || true

trap - ERR

ok "RENDZZ OFFICIAL THEME BERHASIL DIPASANG!"
echo "Backup: $BACKUP"
echo "Panel: $PANEL"
BASH

chmod +x /root/install-rendzz.sh
bash /root/install-rendzz.sh
