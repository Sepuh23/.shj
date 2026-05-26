Berikut versi yang sudah saya ubah semuanya ke IP server **192.168.1.10** dan menyesuaikan DNS + gateway jaringan **192.168.1.1/24**.

# 🖥️ DHCP SERVER — Windows Server 2019

```powershell
# ① Install DHCP Role
Install-WindowsFeature DHCP -IncludeManagementTools

# ② Authorize DHCP di Active Directory
# (skip jika standalone / bukan domain)
Add-DhcpServerInDC -DnsName "192.168.1.10" -IPAddress 192.168.1.10

# ③ Buat Scope (IP client)
Add-DhcpServerv4Scope `
  -Name "UKK_Scope" `
  -StartRange 192.168.1.20 `
  -EndRange 192.168.1.100 `
  -SubnetMask 255.255.255.0 `
  -State Active

# ④ Set Gateway & DNS
Set-DhcpServerv4OptionValue `
  -ScopeId 192.168.1.0 `
  -Router 192.168.1.1 `
  -DnsServer 192.168.1.10

# ⑤ Exclude IP Server
Add-DhcpServerv4ExclusionRange `
  -ScopeId 192.168.1.0 `
  -StartRange 192.168.1.10 `
  -EndRange 192.168.1.10

# ⑥ Firewall DHCP
New-NetFirewallRule `
  -Name "DHCP" `
  -Protocol UDP `
  -LocalPort 67 `
  -Direction Inbound `
  -Action Allow
```

Cek DHCP:

```powershell
Get-DhcpServerv4Scope
Get-DhcpServerv4Lease -ScopeId 192.168.1.0
```

---

# 🌐 DNS SERVER

```powershell
# Install DNS
Install-WindowsFeature DNS -IncludeManagementTools

# Forward Lookup Zone
Add-DnsServerPrimaryZone `
-Name "tjkt-smk3.sch.id" `
-ZoneFile "tjkt-smk3.sch.id.dns"

# A Record
Add-DnsServerResourceRecordA `
-ZoneName "tjkt-smk3.sch.id" `
-Name "@" `
-IPv4Address 192.168.1.10

Add-DnsServerResourceRecordA `
-ZoneName "tjkt-smk3.sch.id" `
-Name "www" `
-IPv4Address 192.168.1.10

Add-DnsServerResourceRecordA `
-ZoneName "tjkt-smk3.sch.id" `
-Name "ftp" `
-IPv4Address 192.168.1.10

Add-DnsServerResourceRecordA `
-ZoneName "tjkt-smk3.sch.id" `
-Name "mail" `
-IPv4Address 192.168.1.10


# Reverse Lookup Zone
Add-DnsServerPrimaryZone `
-NetworkId "192.168.1.0/24" `
-ZoneFile "1.168.192.in-addr.arpa.dns"

# PTR Record
Add-DnsServerResourceRecordPtr `
-ZoneName "1.168.192.in-addr.arpa" `
-Name "10" `
-PtrDomainName "tjkt-smk3.sch.id"
```

Cek DNS:

```powershell
nslookup www.tjkt-smk3.sch.id 192.168.1.10

nslookup mail.tjkt-smk3.sch.id 192.168.1.10
```

---

# 🌍 WEB SERVER (IIS)

```powershell
# Install IIS
Install-WindowsFeature Web-Server -IncludeManagementTools

# Buat folder website
New-Item `
-Path "C:\inetpub\wwwroot\sekolah" `
-ItemType Directory `
-Force

# Import module IIS
Import-Module WebAdministration

# Buat website
New-Website `
-Name "SEKOLAH" `
-Port 80 `
-PhysicalPath "C:\inetpub\wwwroot\sekolah" `
-HostHeader "www.tjkt-smk3.sch.id" `
-Force

# Firewall HTTP
New-NetFirewallRule `
-Name "HTTP" `
-Protocol TCP `
-LocalPort 80 `
-Direction Inbound `
-Action Allow

# Restart IIS
iisreset
```

Cek web:

```text
http://192.168.1.10

http://www.tjkt-smk3.sch.id
```

---

# ✅ Checklist PC Client

```cmd
REM Cek dapat IP dari DHCP
ipconfig /all

REM Test DNS
nslookup www.tjkt-smk3.sch.id

REM Test koneksi
ping www.tjkt-smk3.sch.id

REM Test Web
start http://www.tjkt-smk3.sch.id
```

Catatan penting UKK: karena server memakai **192.168.1.10**, jangan sampai DHCP membagikan IP itu ke client. Makanya IP `.10` sudah di-*exclude* dan DNS client diarahkan ke `192.168.1.10`.
