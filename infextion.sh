cat > /root/rendzz-server-motion.sh <<'BASH'
#!/usr/bin/env bash
set -Eeuo pipefail

P="/var/www/pterodactyl"
F="$P/resources/scripts/components/dashboard/ServerRow.tsx"
BACKUP="/root/rendzz-motion-backup-$(date +%Y%m%d-%H%M%S)"

echo "======================================"
echo " RENDZZ OFFICIAL - SERVER MOTION"
echo "======================================"

[[ $EUID -eq 0 ]] || { echo "Jalankan sebagai root"; exit 1; }
[[ -f "$F" ]] || { echo "ServerRow.tsx tidak ditemukan"; exit 1; }

mkdir -p "$BACKUP"
cp -a "$F" "$BACKUP/ServerRow.tsx"
tar -czf "$BACKUP/assets.tar.gz" -C "$P" public/assets

rollback() {
    echo "Build gagal! Memulihkan file sebelumnya..."
    cp -a "$BACKUP/ServerRow.tsx" "$F"
    tar -xzf "$BACKUP/assets.tar.gz" -C "$P"
    chown -R www-data:www-data "$P/resources/scripts" "$P/public/assets"
    echo "Rollback selesai. Backup: $BACKUP"
}
trap rollback ERR

echo "[1/4] Memasang animasi scroll..."

python3 - "$F" <<'PY'
import sys
from pathlib import Path

p = Path(sys.argv[1])
s = p.read_text()

if 'RENDZZ_SERVER_MOTION' in s:
    raise SystemExit("Animasi Rendzz sudah terpasang.")

replacements = [
(
"""const StatusIndicatorBox = styled(GreyRowBox)<{ $status: ServerPowerState | undefined }>`
    ${tw`grid grid-cols-12 gap-4 relative`};""",
"""const StatusIndicatorBox = styled(GreyRowBox)<{
    $status: ServerPowerState | undefined;
    $visible: boolean;
>`
    ${tw`grid grid-cols-12 gap-4 relative`};

    /* RENDZZ_SERVER_MOTION */
    opacity: ${({ $visible }) => ($visible ? 1 : 0)};
    transform: ${({ $visible }) => ($visible ? 'translate3d(0, 0, 0)' : 'translate3d(64px, 0, 0)')};
    transition: opacity 550ms ease, transform 650ms cubic-bezier(0.22, 1, 0.36, 1);
    will-change: opacity, transform;

    @media (prefers-reduced-motion: reduce) {
        opacity: 1;
        transform: none;
        transition: none;
    }"""
),
(
"""    const [stats, setStats] = useState<ServerStats | null>(null);

    const getStats = () =>""",
"""    const [stats, setStats] = useState<ServerStats | null>(null);
    const rowRef = useRef<HTMLAnchorElement>(null);
    const [isVisible, setIsVisible] = useState(false);

    useEffect(() => {
        const element = rowRef.current;
        if (!element) return;

        if (!('IntersectionObserver' in window)) {
            setIsVisible(true);
            return;
        }

        const observer = new IntersectionObserver(
            (entries) => {
                entries.forEach((entry) => {
                    if (entry.isIntersecting) {
                        setIsVisible(true);
                        observer.unobserve(element);
                    }
                });
            },
            { threshold: 0.08, rootMargin: '0px 0px -30px 0px' }
        );

        observer.observe(element);
        return () => observer.disconnect();
    }, []);

    const getStats = () =>"""
),
(
"""<StatusIndicatorBox as={Link} to={`/server/${server.id}`} className={className} $status={stats?.status}>""",
"""<StatusIndicatorBox
            as={Link}
            ref={rowRef}
            to={`/server/${server.id}`}
            className={className}
            $status={stats?.status}
            $visible={isVisible}
        >"""
)
]

for old, new in replacements:
    count = s.count(old)
    if count != 1:
        raise SystemExit(f"Patch gagal: pola harus ditemukan tepat sekali, ditemukan {count}.")
    s = s.replace(old, new, 1)

p.write_text(s)
print("Animasi berhasil ditambahkan.")
PY

echo "[2/4] Memperbaiki permission..."
mkdir -p /var/www/.cache/yarn
touch /var/www/.yarnrc
chown -R www-data:www-data /var/www/.cache
chown www-data:www-data /var/www/.yarnrc
chown www-data:www-data "$F"

echo "[3/4] Build production..."
su -s /bin/bash www-data -c \
"cd '$P' && export HOME=/var/www YARN_CACHE_FOLDER=/var/www/.cache/yarn && yarn build:production"

echo "[4/4] Membersihkan cache..."
cd "$P"
php artisan view:clear
chown -R www-data:www-data "$P/public/assets"

trap - ERR

echo
echo "======================================"
echo " RENDZZ SERVER MOTION BERHASIL!"
echo "======================================"
echo "Animasi: Slide kanan ke tengah"
echo "Trigger: Scroll / viewport"
echo "Backup: $BACKUP"
echo "Silakan hard refresh dashboard."
BASH

chmod +x /root/rendzz-server-motion.sh
bash /root/rendzz-server-motion.sh
