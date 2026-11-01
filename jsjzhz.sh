#!/usr/bin/env bash
set -Eeuo pipefail

# ==================================================
# RENDZZ MEMO SCREEN
# PTERODACTYL CUSTOM THEME
# Dark Blue / Glass UI
# ==================================================

PANEL="/var/www/pterodactyl"
THEME="$PANEL/public/rendzz-memo"
DATE="$(date +%Y%m%d-%H%M%S)"

if [[ $EUID -ne 0 ]]; then
    echo "Gunakan: sudo bash rendzz-memo.sh"
    exit 1
fi

if [[ ! -f "$PANEL/package.json" ]]; then
    echo "Pterodactyl tidak ditemukan di $PANEL"
    exit 1
fi

echo "========================================"
echo "       RENDZZ MEMO SCREEN INSTALLER"
echo "========================================"

mkdir -p "$THEME"

BACKUP="$PANEL/storage/rendzz-memo-backup-$DATE"
mkdir -p "$BACKUP"

echo "[1/5] Membuat stylesheet..."

cat > "$THEME/theme.css" <<'CSS'
/* =========================================
   RENDZZ MEMO SCREEN
   Pterodactyl UI Theme
========================================= */

:root {
  --memo-bg: #080e1b;
  --memo-panel: #101a2c;
  --memo-card: #14223a;
  --memo-blue: #328bff;
  --memo-light: #75b5ff;
  --memo-border: rgba(110,160,230,.17);
  --memo-text: #edf5ff;
  --memo-muted: #8da3c1;
}

html, body {
  background: var(--memo-bg) !important;
  color: var(--memo-text) !important;
}

body {
  background-image:
    radial-gradient(ellipse at 15% 0%, #173b6b 0%, transparent 35%),
    radial-gradient(ellipse at 90% 15%, #102b50 0%, transparent 35%) !important;
}

/* Panels */
[class*="bg-neutral-800"],
[class*="bg-neutral-900"] {
  background-color: var(--memo-panel) !important;
}

/* Cards */
[class*="rounded"] {
  border-color: var(--memo-border) !important;
}

/* Sidebar */
aside, nav {
  background: rgba(8,17,33,.96) !important;
  border-color: var(--memo-border) !important;
}

/* Inputs */
input, select, textarea {
  background: #0b1628 !important;
  color: white !important;
  border: 1px solid var(--memo-border) !important;
  border-radius: 10px !important;
}

input:focus, textarea:focus, select:focus {
  border-color: var(--memo-blue) !important;
  outline: none !important;
  box-shadow: 0 0 0 3px #328bff22 !important;
}

/* Buttons */
button {
  border-radius: 10px !important;
  transition: .2s ease !important;
}

button:hover {
  filter: brightness(1.15);
  transform: translateY(-1px);
}

/* Links */
a {
  transition: .2s ease;
}

a:hover {
  color: var(--memo-light) !important;
}

/* Tables */
table {
  border-color: var(--memo-border) !important;
}

th, td {
  border-color: var(--memo-border) !important;
}

/* Scrollbar */
::-webkit-scrollbar {
  width: 6px;
  height: 6px;
}

::-webkit-scrollbar-track {
  background: #080e1b;
}

::-webkit-scrollbar-thumb {
  background: #24558d;
  border-radius: 20px;
}

/* Selection */
::selection {
  background: var(--memo-blue);
  color: white;
}

/* Branding */
.rendzz-memo-brand {
  font-weight: 900;
  letter-spacing: 1.5px;
  color: var(--memo-light);
}
CSS

echo "[2/5] Membuat halaman preview..."

cat > "$THEME/index.html" <<'HTML'
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Rendzz Memo Screen</title>
<link rel="stylesheet" href="theme.css">
<style>
*{box-sizing:border-box}
body{margin:0;font-family:Arial,sans-serif}
.layout{display:flex;min-height:100vh}
.sidebar{width:245px;padding:25px;background:#0a1425;border-right:1px solid #233b5c}
.logo{font-size:21px;font-weight:900;color:#75b5ff;margin-bottom:45px}
.menu{display:block;padding:13px;margin:7px 0;border-radius:10px;color:#9db2cf;text-decoration:none}
.menu.active,.menu:hover{background:#17365c;color:white}
.content{padding:35px;width:100%;max-width:1200px;margin:auto}
.top{display:flex;justify-content:space-between;align-items:center;gap:15px}
.tag{color:#75b5ff;background:#17365c;padding:9px 14px;border-radius:20px;font-size:12px}
.cards{display:grid;grid-template-columns:repeat(3,1fr);gap:18px;margin-top:30px}
.card{padding:23px;border:1px solid #233b5c;background:#101e32;border-radius:17px}
.card p{color:#8da3c1}
.value{font-size:26px;font-weight:bold}
.server{margin-top:25px}
@media(max-width:700px){
.sidebar{width:75px;padding:15px 8px}
.logo{font-size:11px;writing-mode:vertical-rl;margin:15px auto 35px}
.menu{text-align:center;font-size:11px;padding:12px 3px}
.content{padding:20px 13px}
.cards{grid-template-columns:1fr}
}
</style>
</head>
<body>
<div class="layout">
<aside class="sidebar">
<div class="logo">REN DZZ</div>
<a class="menu active" href="#">⌂ Dashboard</a>
<a class="menu" href="#">▣ Servers</a>
<a class="menu" href="#">◈ Account</a>
<a class="menu" href="#">⚙ Settings</a>
</aside>
<main class="content">
<div class="top">
<div>
<span class="tag">RENDZZ MEMO SCREEN</span>
<h1>Dashboard</h1>
<p style="color:#8da3c1">Welcome back to your server panel.</p>
</div>
<span class="tag">ONLINE</span>
</div>
<div class="cards">
<div class="card"><p>CPU USAGE</p><div class="value">24%</div></div>
<div class="card"><p>MEMORY</p><div class="value">2.4 GB</div></div>
<div class="card"><p>DISK</p><div class="value">12 GB</div></div>
</div>
<div class="card server">
<h2>My Server</h2>
<p>Server management preview</p>
<span class="tag">RUNNING</span>
</div>
</main>
</div>
</body>
</html>
HTML

echo "[3/5] Membuat informasi theme..."

cat > "$THEME/README.txt" <<'TXT'
RENDZZ MEMO SCREEN
==================

Theme stylesheet:
theme.css

Preview:
index.html

PENTING:
Theme ini belum otomatis diintegrasikan ke React frontend.
Gunakan mekanisme custom theme yang kompatibel dengan
versi Pterodactyl yang terpasang.

Jangan mengganti file inti panel secara manual.
TXT

echo "[4/5] Mengatur permission..."

chown -R www-data:www-data "$THEME"
find "$THEME" -type d -exec chmod 755 {} \;
find "$THEME" -type f -exec chmod 644 {} \;

echo "[5/5] Selesai!"

echo
echo "========================================"
echo "       RENDZZ MEMO SCREEN READY"
echo "========================================"
echo "Theme : $THEME"
echo "CSS   : $THEME/theme.css"
echo "Demo  : $THEME/index.html"
echo
echo "Theme sudah dibuat."
echo "Integrasi ke frontend membutuhkan"
echo "penyesuaian sesuai versi Pterodactyl."
echo "========================================"
