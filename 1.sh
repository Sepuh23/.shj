cat > /mnt/user-data/outputs/ukk.sh << 'ENDOFSCRIPT'
#!/bin/bash

# =====================================
# UBAH INI SAJA — sesuai nomor absen
# =====================================
X="13"
# =====================================

IP="212.100.$X.77"
HOST="ukk-$X"
DOMAIN="tjkt-smk3.sch.id"
ROOTPASS="abc-$X"
USERPASS="abc123-$X"
SSHPORT="2$X"
FTPUSER="ukk-$X"
FTPPASS="ukk-$X"
MAILPASS="usertkj"
RCPASS="rcpass123"

export PATH=$PATH:/usr/sbin:/sbin
export DEBIAN_FRONTEND=noninteractive

LOG="/var/log/ukk-install.log"
exec > >(tee -a $LOG) 2>&1
trap 'echo "[ERROR] Gagal di baris $LINENO — cek $LOG"' ERR

echo "====== UKK ASJ 2026 — Nomor $X ======"
echo "Mulai: $(date)"

# =====================================
# REPO DVD OFFLINE
# =====================================
cat > /etc/apt/sources.list << 'SRCEOF'
deb cdrom:[Debian GNU/Linux 11 _Bullseye_ - Official amd64 DVD Binary-1]/ bullseye contrib main
deb cdrom:[Debian GNU/Linux 11 _Bullseye_ - Official amd64 DVD Binary-2]/ bullseye contrib main
deb cdrom:[Debian GNU/Linux 11 _Bullseye_ - Official amd64 DVD Binary-3]/ bullseye contrib main
SRCEOF

echo ">>> Masukkan DVD 1 lalu tekan ENTER..."
read -r
apt-cdrom add

echo ">>> Masukkan DVD 2 lalu tekan ENTER..."
read -r
apt-cdrom add

echo ">>> Masukkan DVD 3 lalu tekan ENTER..."
read -r
apt-cdrom add

apt install -y \
  openssh-server \
  vsftpd \
  bind9 bind9utils dnsutils \
  apache2 \
  php libapache2-mod-php php-mysql php-mbstring php-xml php-intl \
  postfix dovecot-imapd dovecot-pop3d mailutils \
  mariadb-server \
  roundcube roundcube-mysql

# =====================================
# HOSTNAME
# =====================================
hostnamectl set-hostname "$HOST"

cat > /etc/hosts << EOF
127.0.0.1       localhost
$IP             $HOST.$DOMAIN $HOST
212.100.$X.76   client.$DOMAIN client
EOF

# =====================================
# USER SISTEM
# =====================================
id user &>/dev/null || useradd -m user
echo "root:$ROOTPASS" | chpasswd
echo "user:$USERPASS" | chpasswd

# =====================================
# SSH — Port 2X
# =====================================
cat > /etc/ssh/sshd_config.d/ukk.conf << EOF
Port $SSHPORT
PermitRootLogin yes
EOF
systemctl restart ssh || systemctl restart sshd
systemctl enable ssh

# =====================================
# FTP SERVER
# =====================================
id $FTPUSER &>/dev/null || useradd -m $FTPUSER
echo "$FTPUSER:$FTPPASS" | chpasswd
mkdir -p /home/$FTPUSER/UKK2026

for i in 1 2 3; do
  touch /home/$FTPUSER/UKK2026/file$i.docx
  touch /home/$FTPUSER/UKK2026/file$i.xlsx
  touch /home/$FTPUSER/UKK2026/file$i.ppt
  touch /home/$FTPUSER/UKK2026/file$i.jpg
done

chown -R $FTPUSER:$FTPUSER /home/$FTPUSER

cat > /etc/vsftpd.conf << EOF
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
chroot_local_user=YES
allow_writeable_chroot=YES
xferlog_enable=YES
pasv_min_port=40000
pasv_max_port=50000
EOF

systemctl restart vsftpd
systemctl enable vsftpd

# =====================================
# DNS SERVER
# =====================================
cat > /etc/bind/named.conf.local << EOF
zone "$DOMAIN" {
    type master;
    file "/etc/bind/db.tjkt";
};
EOF

cat > /etc/bind/db.tjkt << 'ZONE'
$TTL 86400
@   IN  SOA  ns1.tjkt-smk3.sch.id. root.tjkt-smk3.sch.id. (
            2026052201
            3600
            1800
            604800
            86400 )

@       IN  NS  ns1.tjkt-smk3.sch.id.
ZONE

cat >> /etc/bind/db.tjkt << EOF
ns1      IN  A    $IP

@        IN  A    $IP
www      IN  A    $IP
ftp      IN  A    $IP
ftp.www  IN  A    $IP
mail     IN  A    $IP
mail.www IN  A    $IP

@        IN  MX  10  mail.$DOMAIN.
EOF

named-checkconf
named-checkzone $DOMAIN /etc/bind/db.tjkt
systemctl restart bind9
systemctl enable bind9
echo "nameserver 127.0.0.1" > /etc/resolv.conf

# =====================================
# WEB SERVER — 6 halaman
# =====================================

cat > /etc/apache2/sites-available/000-default.conf << 'VHOSTEOF'
<VirtualHost *:80>
    DocumentRoot /var/www/html
    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
VHOSTEOF

cat > /var/www/html/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>SMK TJKT - Home</title>
<style>
*{margin:0;padding:0;box-sizing:border-box;font-family:'Segoe UI',Arial,sans-serif}
body{background:#f0f2f5}
.topbar{background:#1a237e;color:#fff;padding:8px 20px;font-size:13px;text-align:right}
.header{background:linear-gradient(135deg,#1a237e,#283593,#1565c0);color:#fff;padding:30px 20px;text-align:center}
.header h1{font-size:2.8em;margin-bottom:5px}
.header p{font-size:1.1em;opacity:.9}
nav{background:#fff;text-align:center;position:sticky;top:0;z-index:100;box-shadow:0 2px 10px rgba(0,0,0,.1)}
nav a{display:inline-block;color:#1a237e;text-decoration:none;padding:18px 22px;font-weight:600;transition:.3s;border-bottom:3px solid transparent}
nav a:hover{background:#f5f5f5;border-bottom-color:#1565c0;color:#1565c0}
.container{max-width:1200px;margin:30px auto;padding:0 20px}
.hero{background:#fff;padding:50px;border-radius:15px;text-align:center;margin-bottom:30px;box-shadow:0 5px 20px rgba(0,0,0,.08)}
.hero h2{color:#1a237e;margin-bottom:15px;font-size:2.2em}
.hero p{color:#555;line-height:1.8;font-size:1.05em;max-width:800px;margin:0 auto}
.btn{display:inline-block;background:#1565c0;color:#fff;padding:12px 30px;border-radius:30px;text-decoration:none;margin-top:20px;font-weight:bold;transition:.3s}
.btn:hover{background:#0d47a1;transform:translateY(-2px)}
.stats{display:grid;grid-template-columns:repeat(4,1fr);gap:20px;margin:30px 0}
.stat{background:#fff;padding:25px;border-radius:15px;text-align:center;box-shadow:0 5px 20px rgba(0,0,0,.08)}
.stat h3{color:#1565c0;font-size:2em}
.stat p{color:#777;margin-top:5px}
.features{display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:25px;margin-top:30px}
.card{background:#fff;padding:30px;border-radius:15px;box-shadow:0 5px 20px rgba(0,0,0,.08);transition:.3s;text-align:center}
.card:hover{transform:translateY(-8px)}
.card .icon{font-size:50px;margin-bottom:15px}
.card h3{color:#1565c0;margin-bottom:10px}
.card p{color:#666;line-height:1.6}
footer{background:#1a237e;color:#fff;text-align:center;padding:30px 20px;margin-top:50px}
</style>
</head>
<body>
<div class="topbar"><span>📞 (021) 1234-5678</span> &nbsp; <span>📧 info@tjkt-smk3.sch.id</span></div>
<div class="header">
  <h1>SMK TJKT UNGGULAN</h1>
  <p>Teknik Jaringan Komputer dan Telekomunikasi | Akreditasi A</p>
</div>
<nav>
  <a href="index.html">Home</a>
  <a href="profil.html">Profil</a>
  <a href="program.html">Program Kerja</a>
  <a href="berita.html">Berita</a>
  <a href="galeri.html">Gallery</a>
  <a href="kontak.html">Kontak</a>
</nav>
<div class="container">
  <div class="hero">
    <h2>Selamat Datang di SMK TJKT</h2>
    <p>Sekolah unggulan yang mencetak generasi siap kerja di bidang Teknik Jaringan Komputer dan Telekomunikasi. Berkomitmen menghasilkan lulusan kompeten, berkarakter, dan siap bersaing di era industri 4.0.</p>
    <a href="profil.html" class="btn">Selengkapnya</a>
  </div>
  <div class="stats">
    <div class="stat"><h3>1200+</h3><p>Siswa Aktif</p></div>
    <div class="stat"><h3>85</h3><p>Guru Profesional</p></div>
    <div class="stat"><h3>50+</h3><p>Mitra Industri</p></div>
    <div class="stat"><h3>15</h3><p>Laboratorium</p></div>
  </div>
  <div class="features">
    <div class="card"><div class="icon">🔧</div><h3>Laboratorium Lengkap</h3><p>Lab komputer, jaringan, fiber optic, dan server terkini untuk praktik siswa.</p></div>
    <div class="card"><div class="icon">👨‍🏫</div><h3>Pengajar Profesional</h3><p>Tenaga pengajar bersertifikasi nasional dan internasional di bidang IT.</p></div>
    <div class="card"><div class="icon">🏢</div><h3>Kerjasama Industri</h3><p>Bermitra dengan 50+ perusahaan IT untuk magang dan penempatan kerja.</p></div>
    <div class="card"><div class="icon">🏆</div><h3>Prestasi Gemilang</h3><p>Juara LKS tingkat provinsi dan nasional bidang Networking dan Cybersecurity.</p></div>
    <div class="card"><div class="icon">💻</div><h3>Kurikulum Industri</h3><p>MikroTik, Cisco, AWS Cloud, dan DevOps — selalu diperbarui sesuai industri.</p></div>
    <div class="card"><div class="icon">🎓</div><h3>Lulusan Terserap</h3><p>95% lulusan terserap di dunia kerja dalam 6 bulan setelah kelulusan.</p></div>
  </div>
</div>
<footer><p><strong>SMK TJKT UNGGULAN</strong></p><p>Jl. Pendidikan No. 123, Jakarta Selatan &nbsp;|&nbsp; 📞 (021) 1234-5678 &nbsp;|&nbsp; 📧 info@tjkt-smk3.sch.id</p><p>© 2026 SMK TJKT Unggulan</p></footer>
</body></html>
HTMLEOF

cat > /var/www/html/profil.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Profil - SMK TJKT</title>
<style>
*{margin:0;padding:0;box-sizing:border-box;font-family:'Segoe UI',Arial,sans-serif}
body{background:#f0f2f5}
.header{background:linear-gradient(135deg,#1a237e,#283593,#1565c0);color:#fff;padding:30px 20px;text-align:center}
.header h1{font-size:2.5em}.header p{opacity:.9;margin-top:5px}
nav{background:#fff;text-align:center;position:sticky;top:0;z-index:100;box-shadow:0 2px 10px rgba(0,0,0,.1)}
nav a{display:inline-block;color:#1a237e;text-decoration:none;padding:18px 22px;font-weight:600;transition:.3s;border-bottom:3px solid transparent}
nav a:hover{background:#f5f5f5;border-bottom-color:#1565c0;color:#1565c0}
.container{max-width:1100px;margin:30px auto;padding:20px}
h2{color:#1a237e;margin-bottom:30px;text-align:center;font-size:2em}
.box{background:#fff;padding:30px;border-radius:15px;margin-bottom:25px;box-shadow:0 5px 20px rgba(0,0,0,.08)}
.box h3{color:#1565c0;margin-bottom:15px;font-size:1.3em;border-bottom:2px solid #e0e0e0;padding-bottom:10px}
.box p,.box li{color:#555;line-height:1.8}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:25px}
.visi{background:#e3f2fd;padding:30px;border-radius:15px}
.misi{background:#e8f5e9;padding:30px;border-radius:15px}
.visi h3,.misi h3{color:#1565c0;margin-bottom:12px;font-size:1.2em}
.misi ul{padding-left:20px}.misi li{margin-bottom:8px}
footer{background:#1a237e;color:#fff;text-align:center;padding:25px;margin-top:40px}
</style>
</head>
<body>
<div class="header"><h1>SMK TJKT UNGGULAN</h1><p>Teknik Jaringan Komputer dan Telekomunikasi</p></div>
<nav><a href="index.html">Home</a><a href="profil.html">Profil</a><a href="program.html">Program Kerja</a><a href="berita.html">Berita</a><a href="galeri.html">Gallery</a><a href="kontak.html">Kontak</a></nav>
<div class="container">
  <h2>Profil Sekolah</h2>
  <div class="box">
    <h3>Sejarah Singkat</h3>
    <p>SMK TJKT berdiri sejak 2010 dengan fokus pada Teknik Jaringan Komputer dan Telekomunikasi. Kini telah berkembang menjadi sekolah unggulan dengan ribuan lulusan profesional di bidang IT.</p>
  </div>
  <div class="grid">
    <div class="visi"><h3>Visi</h3><p>Menjadi sekolah unggulan yang menghasilkan lulusan kompeten, berdaya saing global, dan berakhlak mulia.</p></div>
    <div class="misi"><h3>Misi</h3><ul>
      <li>Pendidikan vokasi berbasis industri</li>
      <li>Praktik langsung di laboratorium modern</li>
      <li>Kerjasama strategis dengan dunia usaha</li>
      <li>Karakter disiplin dan profesional</li>
      <li>Sistem manajemen mutu berkelanjutan</li>
    </ul></div>
  </div>
  <div class="box" style="margin-top:25px">
    <h3>Informasi Sekolah</h3>
    <p><strong>Akreditasi:</strong> A &nbsp;|&nbsp; <strong>Siswa:</strong> 1.200+ &nbsp;|&nbsp; <strong>Guru:</strong> 85 &nbsp;|&nbsp; <strong>Lab:</strong> 15 unit</p>
  </div>
</div>
<footer><p>© 2026 SMK TJKT Unggulan | tjkt-smk3.sch.id</p></footer>
</body></html>
HTMLEOF

cat > /var/www/html/program.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Program Kerja - SMK TJKT</title>
<style>
*{margin:0;padding:0;box-sizing:border-box;font-family:'Segoe UI',Arial,sans-serif}
body{background:#f0f2f5}
.header{background:linear-gradient(135deg,#1a237e,#283593,#1565c0);color:#fff;padding:30px 20px;text-align:center}
.header h1{font-size:2.5em}.header p{opacity:.9;margin-top:5px}
nav{background:#fff;text-align:center;position:sticky;top:0;z-index:100;box-shadow:0 2px 10px rgba(0,0,0,.1)}
nav a{display:inline-block;color:#1a237e;text-decoration:none;padding:18px 22px;font-weight:600;transition:.3s;border-bottom:3px solid transparent}
nav a:hover{background:#f5f5f5;border-bottom-color:#1565c0;color:#1565c0}
.container{max-width:1100px;margin:30px auto;padding:20px}
h2{color:#1a237e;margin-bottom:30px;text-align:center;font-size:2em}
table{width:100%;border-collapse:collapse;background:#fff;border-radius:15px;overflow:hidden;box-shadow:0 5px 20px rgba(0,0,0,.08)}
th{background:#1565c0;color:#fff;padding:15px;text-align:left}
td{padding:14px 15px;border-bottom:1px solid #eee;color:#555}
tr:hover{background:#f5f5f5}
.badge{display:inline-block;padding:4px 14px;border-radius:20px;font-size:.85em;font-weight:bold}
.done{background:#e8f5e9;color:#2e7d32}
.ongoing{background:#e3f2fd;color:#1565c0}
.soon{background:#fff3e0;color:#e65100}
footer{background:#1a237e;color:#fff;text-align:center;padding:25px;margin-top:40px}
</style>
</head>
<body>
<div class="header"><h1>SMK TJKT UNGGULAN</h1><p>Teknik Jaringan Komputer dan Telekomunikasi</p></div>
<nav><a href="index.html">Home</a><a href="profil.html">Profil</a><a href="program.html">Program Kerja</a><a href="berita.html">Berita</a><a href="galeri.html">Gallery</a><a href="kontak.html">Kontak</a></nav>
<div class="container">
  <h2>Program Kerja 2026</h2>
  <table>
    <tr><th>No</th><th>Program</th><th>Deskripsi</th><th>Waktu</th><th>Status</th></tr>
    <tr><td>1</td><td>Pelatihan MikroTik</td><td>Sertifikasi MTCNA kelas XI-XII</td><td>Jan 2026</td><td><span class="badge done">Selesai</span></td></tr>
    <tr><td>2</td><td>Workshop Fiber Optic</td><td>Splicing dan pengukuran kabel</td><td>Feb 2026</td><td><span class="badge done">Selesai</span></td></tr>
    <tr><td>3</td><td>UKK Administrasi Server</td><td>Uji kompetensi Debian & Windows Server</td><td>Mar 2026</td><td><span class="badge ongoing">Berlangsung</span></td></tr>
    <tr><td>4</td><td>Kunjungan Industri</td><td>Visit ke Data Center & ISP nasional</td><td>Apr 2026</td><td><span class="badge soon">Mendatang</span></td></tr>
    <tr><td>5</td><td>Lomba IT Nasional</td><td>LKS Networking & Cybersecurity</td><td>Mei 2026</td><td><span class="badge soon">Mendatang</span></td></tr>
    <tr><td>6</td><td>Program Magang</td><td>Magang 3 bulan di perusahaan IT mitra</td><td>Jun-Sep 2026</td><td><span class="badge soon">Mendatang</span></td></tr>
  </table>
</div>
<footer><p>© 2026 SMK TJKT Unggulan | tjkt-smk3.sch.id</p></footer>
</body></html>
HTMLEOF

cat > /var/www/html/berita.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Berita - SMK TJKT</title>
<style>
*{margin:0;padding:0;box-sizing:border-box;font-family:'Segoe UI',Arial,sans-serif}
body{background:#f0f2f5}
.header{background:linear-gradient(135deg,#1a237e,#283593,#1565c0);color:#fff;padding:30px 20px;text-align:center}
.header h1{font-size:2.5em}.header p{opacity:.9;margin-top:5px}
nav{background:#fff;text-align:center;position:sticky;top:0;z-index:100;box-shadow:0 2px 10px rgba(0,0,0,.1)}
nav a{display:inline-block;color:#1a237e;text-decoration:none;padding:18px 22px;font-weight:600;transition:.3s;border-bottom:3px solid transparent}
nav a:hover{background:#f5f5f5;border-bottom-color:#1565c0;color:#1565c0}
.container{max-width:1100px;margin:30px auto;padding:20px}
h2{color:#1a237e;margin-bottom:30px;text-align:center;font-size:2em}
.news{display:grid;gap:20px}
.item{background:#fff;padding:25px;border-radius:15px;box-shadow:0 5px 20px rgba(0,0,0,.08);border-left:5px solid #1565c0;transition:.3s}
.item:hover{transform:translateX(5px)}
.item .date{color:#999;font-size:.9em;margin-bottom:8px}
.item h3{color:#1565c0;margin-bottom:10px}
.item p{color:#555;line-height:1.6}
.tag{display:inline-block;background:#e3f2fd;color:#1565c0;padding:4px 12px;border-radius:15px;font-size:.85em;margin-top:10px}
footer{background:#1a237e;color:#fff;text-align:center;padding:25px;margin-top:40px}
</style>
</head>
<body>
<div class="header"><h1>SMK TJKT UNGGULAN</h1><p>Teknik Jaringan Komputer dan Telekomunikasi</p></div>
<nav><a href="index.html">Home</a><a href="profil.html">Profil</a><a href="program.html">Program Kerja</a><a href="berita.html">Berita</a><a href="galeri.html">Gallery</a><a href="kontak.html">Kontak</a></nav>
<div class="container">
  <h2>Berita Terbaru</h2>
  <div class="news">
    <div class="item"><div class="date">15 Mei 2026</div><h3>Siswa SMK TJKT Juara LKS Tingkat Provinsi</h3><p>Dua siswa TJKT meraih juara 1 dan 2 LKS bidang Networking tingkat provinsi dan akan lanjut ke tingkat nasional.</p><span class="tag">Prestasi</span></div>
    <div class="item"><div class="date">10 April 2026</div><h3>Kerjasama Baru dengan Cisco Academy</h3><p>SMK TJKT resmi menjadi Cisco Networking Academy, membuka akses sertifikasi CCNA tanpa biaya tambahan bagi siswa.</p><span class="tag">Kerjasama</span></div>
    <div class="item"><div class="date">1 Maret 2026</div><h3>Launching Lab Server Baru</h3><p>Peresmian laboratorium server Debian dan Windows terbaru dengan 30 unit komputer untuk mendukung UKK 2026.</p><span class="tag">Fasilitas</span></div>
  </div>
</div>
<footer><p>© 2026 SMK TJKT Unggulan | tjkt-smk3.sch.id</p></footer>
</body></html>
HTMLEOF

cat > /var/www/html/galeri.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Gallery - SMK TJKT</title>
<style>
*{margin:0;padding:0;box-sizing:border-box;font-family:'Segoe UI',Arial,sans-serif}
body{background:#f0f2f5}
.header{background:linear-gradient(135deg,#1a237e,#283593,#1565c0);color:#fff;padding:30px 20px;text-align:center}
.header h1{font-size:2.5em}.header p{opacity:.9;margin-top:5px}
nav{background:#fff;text-align:center;position:sticky;top:0;z-index:100;box-shadow:0 2px 10px rgba(0,0,0,.1)}
nav a{display:inline-block;color:#1a237e;text-decoration:none;padding:18px 22px;font-weight:600;transition:.3s;border-bottom:3px solid transparent}
nav a:hover{background:#f5f5f5;border-bottom-color:#1565c0;color:#1565c0}
.container{max-width:1100px;margin:30px auto;padding:20px}
h2{color:#1a237e;margin-bottom:30px;text-align:center;font-size:2em}
.gallery{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:20px}
.g-item{background:#fff;border-radius:15px;overflow:hidden;box-shadow:0 5px 20px rgba(0,0,0,.08);transition:.3s}
.g-item:hover{transform:translateY(-8px)}
.g-img{width:100%;height:200px;display:flex;align-items:center;justify-content:center;color:#fff;font-weight:bold;font-size:1.1em}
.g-info{padding:15px}
.g-info h3{color:#1565c0;margin-bottom:5px}
.g-info p{color:#777;font-size:.9em}
footer{background:#1a237e;color:#fff;text-align:center;padding:25px;margin-top:40px}
</style>
</head>
<body>
<div class="header"><h1>SMK TJKT UNGGULAN</h1><p>Teknik Jaringan Komputer dan Telekomunikasi</p></div>
<nav><a href="index.html">Home</a><a href="profil.html">Profil</a><a href="program.html">Program Kerja</a><a href="berita.html">Berita</a><a href="galeri.html">Gallery</a><a href="kontak.html">Kontak</a></nav>
<div class="container">
  <h2>Gallery Kegiatan</h2>
  <div class="gallery">
    <div class="g-item"><div class="g-img" style="background:linear-gradient(135deg,#1565c0,#1a237e)">Praktik Server</div><div class="g-info"><h3>Administrasi Server</h3><p>Debian & Windows Server</p></div></div>
    <div class="g-item"><div class="g-img" style="background:linear-gradient(135deg,#2e7d32,#1b5e20)">Fiber Optic</div><div class="g-info"><h3>Workshop Fiber Optic</h3><p>Splicing & Pengukuran</p></div></div>
    <div class="g-item"><div class="g-img" style="background:linear-gradient(135deg,#e65100,#bf360c)">Lomba IT</div><div class="g-info"><h3>Lomba Kompetensi Siswa</h3><p>Bidang Networking</p></div></div>
    <div class="g-item"><div class="g-img" style="background:linear-gradient(135deg,#6a1b9a,#4a148c)">Lab Jaringan</div><div class="g-info"><h3>Laboratorium Jaringan</h3><p>MikroTik & Cisco</p></div></div>
    <div class="g-item"><div class="g-img" style="background:linear-gradient(135deg,#c62828,#8e0000)">Magang</div><div class="g-info"><h3>Program Magang</h3><p>50+ Perusahaan Mitra</p></div></div>
    <div class="g-item"><div class="g-img" style="background:linear-gradient(135deg,#00838f,#006064)">UKK 2026</div><div class="g-info"><h3>UKK Administrasi Server</h3><p>Sertifikasi Kompetensi</p></div></div>
  </div>
</div>
<footer><p>© 2026 SMK TJKT Unggulan | tjkt-smk3.sch.id</p></footer>
</body></html>
HTMLEOF

cat > /var/www/html/kontak.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Kontak - SMK TJKT</title>
<style>
*{margin:0;padding:0;box-sizing:border-box;font-family:'Segoe UI',Arial,sans-serif}
body{background:#f0f2f5}
.header{background:linear-gradient(135deg,#1a237e,#283593,#1565c0);color:#fff;padding:30px 20px;text-align:center}
.header h1{font-size:2.5em}.header p{opacity:.9;margin-top:5px}
nav{background:#fff;text-align:center;position:sticky;top:0;z-index:100;box-shadow:0 2px 10px rgba(0,0,0,.1)}
nav a{display:inline-block;color:#1a237e;text-decoration:none;padding:18px 22px;font-weight:600;transition:.3s;border-bottom:3px solid transparent}
nav a:hover{background:#f5f5f5;border-bottom-color:#1565c0;color:#1565c0}
.container{max-width:1100px;margin:30px auto;padding:20px}
h2{color:#1a237e;margin-bottom:30px;text-align:center;font-size:2em}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:30px}
.info{background:#fff;padding:30px;border-radius:15px;box-shadow:0 5px 20px rgba(0,0,0,.08)}
.info h3{color:#1565c0;margin:14px 0 6px}
.info p{color:#555;line-height:1.6}
.form-box{background:#fff;padding:30px;border-radius:15px;box-shadow:0 5px 20px rgba(0,0,0,.08)}
.form-box h3{color:#e65100;margin-bottom:20px;font-size:1.2em}
input,textarea{width:100%;padding:12px;margin-bottom:14px;border:1px solid #ddd;border-radius:8px;font-size:14px}
button{background:#1565c0;color:#fff;padding:12px 30px;border:none;border-radius:30px;cursor:pointer;font-weight:bold;transition:.3s}
button:hover{background:#0d47a1;transform:translateY(-2px)}
footer{background:#1a237e;color:#fff;text-align:center;padding:25px;margin-top:40px}
</style>
</head>
<body>
<div class="header"><h1>SMK TJKT UNGGULAN</h1><p>Teknik Jaringan Komputer dan Telekomunikasi</p></div>
<nav><a href="index.html">Home</a><a href="profil.html">Profil</a><a href="program.html">Program Kerja</a><a href="berita.html">Berita</a><a href="galeri.html">Gallery</a><a href="kontak.html">Kontak</a></nav>
<div class="container">
  <h2>Hubungi Kami</h2>
  <div class="grid">
    <div class="info">
      <h3>Alamat</h3><p>Jl. Pendidikan No. 123, Jakarta Selatan 12345</p>
      <h3>Telepon</h3><p>(021) 1234-5678 &nbsp;|&nbsp; WA: 0812-3456-7890</p>
      <h3>Email</h3><p>info@tjkt-smk3.sch.id</p>
      <h3>Jam Operasional</h3><p>Senin - Jumat: 07:00 - 16:00 WIB<br>Sabtu: 07:00 - 12:00 WIB</p>
    </div>
    <div class="form-box">
      <h3>Kirim Pesan</h3>
      <form>
        <input type="text" placeholder="Nama Lengkap" required>
        <input type="email" placeholder="Email" required>
        <input type="text" placeholder="Subjek">
        <textarea rows="5" placeholder="Pesan Anda..."></textarea>
        <button type="button">Kirim Pesan</button>
      </form>
    </div>
  </div>
</div>
<footer><p><strong>SMK TJKT UNGGULAN</strong> &nbsp;|&nbsp; Jl. Pendidikan No. 123, Jakarta Selatan &nbsp;|&nbsp; © 2026</p></footer>
</body></html>
HTMLEOF

if command -v a2enmod &>/dev/null; then
  a2enmod rewrite
else
  ln -sf /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/rewrite.load 2>/dev/null || true
fi

systemctl restart apache2
systemctl enable apache2

# =====================================
# MAIL SERVER — POSTFIX
# =====================================
echo "$DOMAIN" > /etc/mailname

postconf -e "myhostname = mail.$DOMAIN"
postconf -e "mydomain = $DOMAIN"
postconf -e "myorigin = \$mydomain"
postconf -e "inet_interfaces = all"
postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain"
postconf -e "mynetworks = 127.0.0.0/8, $IP/24"
postconf -e "home_mailbox = Maildir/"

systemctl restart postfix
systemctl enable postfix

# =====================================
# MAIL SERVER — DOVECOT
# =====================================
sed -i 's|^#*mail_location.*|mail_location = maildir:~/Maildir|' /etc/dovecot/conf.d/10-mail.conf
sed -i 's|^#*disable_plaintext_auth.*|disable_plaintext_auth = no|' /etc/dovecot/conf.d/10-auth.conf
sed -i 's|^auth_mechanisms.*|auth_mechanisms = plain login|' /etc/dovecot/conf.d/10-auth.conf

systemctl restart dovecot
systemctl enable dovecot

# =====================================
# MAIL USERS — user1 s/d user5
# =====================================
for u in user1 user2 user3 user4 user5; do
  id $u &>/dev/null || useradd -m $u
  echo "$u:$MAILPASS" | chpasswd
  mkdir -p /home/$u/Maildir/{cur,new,tmp}
  chown -R $u:$u /home/$u
done

# =====================================
# ROUNDCUBE — DATABASE
# =====================================
mysql -u root << EOF
DROP DATABASE IF EXISTS roundcubemail;
CREATE DATABASE roundcubemail CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER IF NOT EXISTS 'roundcube'@'localhost' IDENTIFIED BY '$RCPASS';
GRANT ALL PRIVILEGES ON roundcubemail.* TO 'roundcube'@'localhost';
FLUSH PRIVILEGES;
EOF

mysql -u root roundcubemail < /usr/share/roundcube/SQL/mysql.initial.sql 2>/dev/null || true

# =====================================
# ROUNDCUBE — Apache config
# =====================================
cat > /etc/apache2/conf-available/roundcube.conf << 'RCAPACHE'
Alias /roundcube /var/lib/roundcube/public_html

<Directory /var/lib/roundcube/public_html>
    Options +FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>

<Directory /var/lib/roundcube/config>
    Options -FollowSymLinks
    AllowOverride None
</Directory>
RCAPACHE

# =====================================
# ROUNDCUBE — config.inc.php
# =====================================
cat > /etc/roundcube/config.inc.php << 'RCEOF'
<?php
$config['db_dsnw'] = 'mysql://roundcube:rcpass123@localhost/roundcubemail';
$config['default_host'] = 'localhost';
$config['default_port'] = 143;
$config['smtp_server'] = 'localhost';
$config['smtp_port'] = 25;
$config['smtp_user'] = '%u';
$config['smtp_pass'] = '%p';
$config['product_name'] = 'SMK TJKT Webmail';
$config['des_key'] = 'ukksmktjkt2026abcdefghij';
$config['plugins'] = array();
$config['skin'] = 'larry';
$config['enable_installer'] = false;
RCEOF

chown root:www-data /etc/roundcube/config.inc.php
chmod 640 /etc/roundcube/config.inc.php
chown -R www-data:www-data /var/lib/roundcube/ 2>/dev/null || true
mkdir -p /var/log/roundcube
chown www-data:www-data /var/log/roundcube 2>/dev/null || true

if command -v a2enconf &>/dev/null; then
  a2enconf roundcube
else
  ln -sf /etc/apache2/conf-available/roundcube.conf /etc/apache2/conf-enabled/roundcube.conf
fi

systemctl restart apache2

# =====================================
# VERIFIKASI OTOMATIS
# =====================================
echo ""
echo "======================================"
echo "  VERIFIKASI LAYANAN"
echo "======================================"

ok()   { echo "  [OK]    $1"; }
fail() { echo "  [GAGAL] $1"; }

for svc in ssh vsftpd bind9 apache2 postfix dovecot mariadb; do
  systemctl is-active --quiet $svc && ok "$svc" || fail "$svc MATI"
done

echo ""
echo "  DNS:"
for sub in "" "www." "ftp." "ftp.www." "mail." "mail.www."; do
  result=$(dig +short ${sub}${DOMAIN} @127.0.0.1 2>/dev/null | head -1)
  [ "$result" = "$IP" ] && ok "${sub}${DOMAIN} -> $result" || fail "${sub}${DOMAIN} -> '${result}' (harusnya $IP)"
done

echo ""
echo "  FTP files:"
FCOUNT=$(ls /home/$FTPUSER/UKK2026/ 2>/dev/null | wc -l)
[ "$FCOUNT" -eq 12 ] && ok "12 file ada" || fail "File: $FCOUNT/12"

echo ""
echo "  Web:"
WEB=$(curl -so /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null)
RC=$(curl -so /dev/null -w "%{http_code}" http://localhost/roundcube/ 2>/dev/null)
[ "$WEB" = "200" ] && ok "Web HTTP $WEB" || fail "Web HTTP $WEB"
{ [ "$RC" = "200" ] || [ "$RC" = "302" ]; } && ok "Roundcube HTTP $RC" || fail "Roundcube HTTP $RC"

echo ""
echo "  Port aktif:"
ss -tulnp | grep -E ":(21|$SSHPORT|25|80|110|143|53)\s" | awk '{print "    "$1,$5}' || true

echo ""
echo "======================================"
echo "  SELESAI — UKK ASJ 2026 Nomor $X"
echo "  Log: $LOG"
echo "======================================"
echo "  IP        : $IP"
echo "  SSH       : port $SSHPORT | root / $ROOTPASS"
echo "  FTP       : $FTPUSER / $FTPPASS | folder UKK2026"
echo "  Web       : http://www.$DOMAIN"
echo "  Webmail   : http://mail.$DOMAIN/roundcube"
echo "  Mail user : user1-user5 / $MAILPASS"
echo "======================================"
echo "Selesai: $(date)"
ENDOFSCRIPT

chmod +x /mnt/user-data/outputs/ukk.sh
echo "done"