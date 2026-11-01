cat > /root/rendzz-footer.sh <<'BASH'
#!/usr/bin/env bash
set -Eeuo pipefail

P="/var/www/pterodactyl"
F="$P/resources/scripts/components/auth/LoginFormContainer.tsx"
B="/root/LoginFormContainer.tsx.$(date +%Y%m%d-%H%M%S).backup"

[[ $EUID -eq 0 ]] || { echo "Jalankan sebagai root"; exit 1; }
[[ -f "$F" ]] || { echo "File tidak ditemukan"; exit 1; }

cp -a "$F" "$B"

python3 - "$F" <<'PY'
import sys
from pathlib import Path

p = Path(sys.argv[1])
s = p.read_text()
old = "Pterodactyl Software"
new = "Rendzz Official"

if old not in s:
    raise SystemExit("Tulisan asli tidak ditemukan. Tidak ada perubahan.")

p.write_text(s.replace(old, new))
PY

cd "$P"

if su -s /bin/bash www-data -c \
  "cd '$P' && export HOME=/var/www YARN_CACHE_FOLDER=/var/www/.cache/yarn && yarn build:production"
then
    chown -R www-data:www-data "$P/public/assets"
    php artisan view:clear
    echo "BERHASIL: Copyright diganti menjadi Rendzz Official"
    echo "Backup: $B"
else
    cp -a "$B" "$F"
    echo "Build gagal. Source dikembalikan ke kondisi semula."
    exit 1
fi
BASH

chmod +x /root/rendzz-footer.sh
bash /root/rendzz-footer.sh
