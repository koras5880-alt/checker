chcp 65001 > $null
Clear-Host
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

# БАННЕР С АНИМАЦИЕЙ (ускорена до 3 секунд)
$bannerLines = @(
    "███████╗███████╗     ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗███████╗██████╗ ",
    "██╔════╝██╔════╝    ██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝██╔════╝██╔══██╗",
    "█████╗  ███████╗    ██║     ███████║█████╗  ██║     █████╔╝ █████╗  ██████╔╝",
    "██╔══╝  ╚════██║    ██║     ██╔══██║██╔══╝  ██║     ██╔═██╗ ██╔══╝  ██╔══██╗",
    "██║     ███████║    ╚██████╗██║  ██║███████╗╚██████╗██║  ██╗███████╗██║  ██║",
    "╚═╝     ╚══════╝     ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝"
)

Write-Host ""
Write-Host ""

$totalLines = $bannerLines.Count
$totalDuration = 3
$delayPerLine = ($totalDuration / $totalLines) * 1000

for ($i = 0; $i -lt $bannerLines.Count; $i++) {
    $line = $bannerLines[$i]
    for ($j = 1; $j -le $line.Length; $j++) {
        Write-Host -NoNewline $line.Substring(0, $j) -ForegroundColor Magenta
        Start-Sleep -Milliseconds 1
        $host.UI.RawUI.CursorPosition = @{ X = 0; Y = $host.UI.RawUI.CursorPosition.Y }
    }
    Write-Host $line -ForegroundColor Magenta
    Start-Sleep -Milliseconds ($delayPerLine / 2)
}

Write-Host ""
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor DarkMagenta
Write-Host "║                                                     FUNSKY CHECKER v1.0                                                 ║" -ForegroundColor DarkMagenta
Write-Host "║                                    Developers: fracturesdecora | net_dobra | op4ox                                      ║" -ForegroundColor DarkMagenta
Write-Host "╚══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor DarkMagenta
Write-Host ""
Write-Host ""

# ПРОВЕРКА ПРАВ АДМИНИСТРАТОРА
try {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) { throw "Not admin" }
    Write-Host "[+] Administrator rights: OK" -ForegroundColor Magenta
}
catch {
    Write-Host "[!] ERROR: Administrator rights required! Run PowerShell as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# СОЗДАНИЕ РАБОЧЕЙ ДИРЕКТОРИИ
$workPath = "C:\FSChecker"
if (-not (Test-Path $workPath)) { New-Item -ItemType Directory -Path $workPath -Force | Out-Null }
Set-Location $workPath
Write-Host "[+] Working directory: $workPath" -ForegroundColor Magenta

# ОСТАНОВКА МЕШАЮЩИХ ПРОЦЕССОВ
Write-Host "[*] Stopping interfering processes..." -ForegroundColor Magenta
$processesToStop = @("obs64", "obs32", "obs", "ayugram", "telegram", "nvcontainer", "gamebar", "wallpaper32", "wallpaper64", "steam", "lively")
foreach ($proc in $processesToStop) {
    Get-Process -Name $proc -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue | Out-Null
}
Write-Host "[*] Stopping clipboard history service..." -ForegroundColor Magenta
Get-Service -Name "*cbdhsvc*" -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue | Out-Null

# ============================================
# 1. СБОР СИСТЕМНОЙ ИНФОРМАЦИИ
# ============================================
Write-Host "`n[1/6] COLLECTING SYSTEM INFORMATION..." -ForegroundColor Magenta
$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$disk = Get-Disk | Select-Object -First 1
$SystemUID = (Get-CimInstance -ClassName Win32_ComputerSystemProduct).UUID
$SystemHWID = $cpu.ProcessorId.Trim() + $disk.SerialNumber.Trim()

Write-Host "`n[+] SYSTEM INFORMATION:" -ForegroundColor Magenta
Write-Host "    Username: $env:USERNAME" -ForegroundColor White
Write-Host "    Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "    OS: $($os.Caption)" -ForegroundColor White
Write-Host "    CPU: $($cpu.Name.Trim())" -ForegroundColor White
Write-Host "    CPU Serial: $($cpu.ProcessorId.Trim())" -ForegroundColor White
Write-Host "    Disk Serial: $($disk.SerialNumber.Trim())" -ForegroundColor White
Write-Host "    UUID: $SystemUID" -ForegroundColor White
Write-Host "    HWID: $SystemHWID" -ForegroundColor White
Write-Host "    Boot Time: $($os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
Write-Host "    Current Time: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')" -ForegroundColor White

Start-Sleep -Seconds 2

# ============================================
# 2. BAM ПАРСЕР
# ============================================
Write-Host "`n[2/6] RUNNING BAM ANALYZER (Background Activity Moderator)..." -ForegroundColor Magenta

function Get-Signature {
    param ([string[]]$FilePath)
    $Existence = Test-Path -PathType "Leaf" -Path $FilePath
    $Authenticode = (Get-AuthenticodeSignature -FilePath $FilePath -ErrorAction SilentlyContinue).Status
    if ($Existence) {
        if ($Authenticode -eq "Valid") { return "Valid Signature" }
        elseif ($Authenticode -eq "NotSigned") { return "Invalid Signature (NotSigned)" }
        else { return "Invalid Signature" }
    } else {
        return "File Was Not Found"
    }
}

try {
    $Users = foreach($ii in ("bam", "bam\State")) {
        Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$($ii)\UserSettings\" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty PSChildName
    }
}
catch {
    Write-Host "    Error reading BAM registry keys" -ForegroundColor Magenta
    $Users = @()
}

if ($Users) {
    $rpath = @("HKLM:\SYSTEM\CurrentControlSet\Services\bam\","HKLM:\SYSTEM\CurrentControlSet\Services\bam\state\")
    $Bam = @()

    foreach ($Sid in $Users) {
        foreach($rp in $rpath) {
            $BamItems = Get-Item -Path "$($rp)UserSettings\$Sid" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Property
            ForEach ($Item in $BamItems) {
                $Key = Get-ItemProperty -Path "$($rp)UserSettings\$Sid" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $Item
                If($key.length -eq 24) {
                    $Hex = [System.BitConverter]::ToString($key[7..0]) -replace "-",""
                    $TimeUTC = Get-Date ([DateTime]::FromFileTimeUtc([Convert]::ToInt64($Hex, 16))) -Format "dd.MM.yy HH:mm"
                    $SortDate = [DateTime]::FromFileTimeUtc([Convert]::ToInt64($Hex, 16))
                    if((((split-path -path $item) | ConvertFrom-String -Delimiter "\\").P3)-match '\d{1}') {
                        $path = Join-Path -Path "C:" -ChildPath ($item).Remove(1,23)
                        $sig = Get-Signature -FilePath $path
                        $app = Split-path -leaf ($item).TrimStart()
                    } else {
                        $path = ""
                        $sig = "N/A"
                        $app = $item
                    }
                    $Bam += [PSCustomObject]@{
                        'Time' = $TimeUTC
                        'Application' = $app
                        'Signature' = $sig
                        'Path' = $path
                        'SortDate' = $SortDate
                    }
                }
            }
        }
    }

    $FilteredBam = $Bam | Where-Object {
        $_.Signature -eq "Invalid Signature (NotSigned)" -or
        $_.Signature -eq "File Was Not Found"
    } | Sort-Object SortDate -Descending

    if ($FilteredBam) {
        Write-Host "`n    Suspicious BAM entries found (newest to oldest):" -ForegroundColor Magenta
        Write-Host "    " + ("─" * 70) -ForegroundColor Gray
        
        $FilteredBam | ForEach-Object {
            if ($_.Signature -eq "File Was Not Found") {
                Write-Host "    [$($_.Time)] $($_.Application)" -ForegroundColor Magenta
                Write-Host "        └─ Status: $($_.Signature)" -ForegroundColor Magenta
                if ($_.Path) { Write-Host "        └─ Path: $($_.Path)" -ForegroundColor Gray }
            } elseif ($_.Signature -match "Invalid Signature") {
                Write-Host "    [$($_.Time)] $($_.Application)" -ForegroundColor Red
                Write-Host "        └─ Status: $($_.Signature)" -ForegroundColor Red
                if ($_.Path) { Write-Host "        └─ Path: $($_.Path)" -ForegroundColor Gray }
            }
            Write-Host "    " + ("─" * 70) -ForegroundColor Gray
        }
        
        Write-Host "`n    Total found: $($FilteredBam.Count) entries" -ForegroundColor Magenta
    } else {
        Write-Host "    No suspicious BAM entries found" -ForegroundColor Green
    }
} else {
    Write-Host "    Failed to get BAM data" -ForegroundColor Gray
}

Start-Sleep -Seconds 2

# ============================================
# 3. СКАЧИВАНИЕ И ЗАПУСК InjGen
# ============================================
Write-Host "`n[3/6] DOWNLOADING AND RUNNING InjGen.exe..." -ForegroundColor Magenta
$injGenPath = "InjGen.exe"
if (-not (Test-Path $injGenPath)) {
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/koras5880-alt/injgen/refs/heads/main/InjGen.exe" -OutFile $injGenPath
        Write-Host "[+] InjGen.exe successfully downloaded" -ForegroundColor DarkMagenta
    }
    catch {
        Write-Host "[!] Error downloading InjGen.exe" -ForegroundColor Red
    }
}

if (Test-Path $injGenPath) {
    Write-Host "[*] Running InjGen.exe..." -ForegroundColor DarkMagenta
    try {
        .\InjGen.exe
        Write-Host "[+] InjGen.exe started" -ForegroundColor DarkMagenta
    }
    catch {
        Write-Host "[!] Error running InjGen.exe" -ForegroundColor Red
    }
}
else {
    Write-Host "[!] InjGen.exe not found, skipping..." -ForegroundColor Red
}

Start-Sleep -Seconds 2

# ============================================
# 4. СКАЧИВАНИЕ И ЗАПУСК USBDriveLog
# ============================================
Write-Host "`n[4/6] DOWNLOADING AND RUNNING USBDriveLog.exe..." -ForegroundColor Magenta
$usbDriveLogPath = "USBDriveLog.exe"
if (-not (Test-Path $usbDriveLogPath)) {
    try {
        Invoke-WebRequest -Uri "https://cdn.discordapp.com/attachments/1491468384255086634/1491511410050728096/USBDriveLog.exe?ex=69d7f5bf&is=69d6a43f&hm=a56985b67e7087ab58cc410904871346dda6d04dec8bd12bfdc82e7207365605&" -OutFile $usbDriveLogPath
        Write-Host "[+] USBDriveLog.exe successfully downloaded" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Error downloading USBDriveLog.exe: $_" -ForegroundColor Red
    }
}

if (Test-Path $usbDriveLogPath) {
    Write-Host "[*] Running USBDriveLog.exe..." -ForegroundColor Magenta
    try {
        Start-Process -FilePath ".\USBDriveLog.exe"
        Write-Host "[+] USBDriveLog.exe started" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Error running USBDriveLog.exe: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "[!] USBDriveLog.exe not found, skipping..." -ForegroundColor Red
}

Start-Sleep -Seconds 2

# ============================================
# 5. СКАЧИВАНИЕ И ЗАПУСК JournalTrace
# ============================================
Write-Host "`n[5/6] DOWNLOADING AND RUNNING JournalTrace.exe..." -ForegroundColor Magenta
$journalTracePath = "JournalTrace.exe"
if (-not (Test-Path $journalTracePath)) {
    try {
        Invoke-WebRequest -Uri "https://github.com/ponei/JournalTrace/releases/download/1.0/JournalTrace.exe" -OutFile $journalTracePath
        Write-Host "[+] JournalTrace.exe successfully downloaded" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Error downloading JournalTrace.exe: $_" -ForegroundColor Red
    }
}

if (Test-Path $journalTracePath) {
    Write-Host "[*] Running JournalTrace.exe..." -ForegroundColor Magenta
    try {
        Start-Process -FilePath ".\JournalTrace.exe"
        Write-Host "[+] JournalTrace.exe started" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Error running JournalTrace.exe: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "[!] JournalTrace.exe not found, skipping..." -ForegroundColor Red
}

Start-Sleep -Seconds 2

# ============================================
# 6. СКАЧИВАНИЕ И ЗАПУСК Everything + конфиг
# ============================================
Write-Host "`n[6/6] DOWNLOADING AND RUNNING Everything.exe..." -ForegroundColor Magenta

# Скачивание конфига
$everythingIniPath = "Everything-1.5a.ini"
if (-not (Test-Path $everythingIniPath)) {
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/koras5880-alt/everything/refs/heads/main/Everything-1.5a.ini" -OutFile $everythingIniPath
        Write-Host "[+] Everything-1.5a.ini successfully downloaded" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Error downloading Everything-1.5a.ini: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "[+] Everything-1.5a.ini already exists" -ForegroundColor Green
}

# Скачивание и запуск Everything
$everythingPath = "Everything.exe"
if (-not (Test-Path $everythingPath)) {
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/koras5880-alt/everything/refs/heads/main/Everything.exe" -OutFile $everythingPath
        Write-Host "[+] Everything.exe successfully downloaded" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Error downloading Everything.exe: $_" -ForegroundColor Red
    }
}

if (Test-Path $everythingPath) {
    Write-Host "[*] Running Everything.exe..." -ForegroundColor Magenta
    try {
        Start-Process -FilePath ".\Everything.exe"
        Write-Host "[+] Everything.exe started" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Error running Everything.exe: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "[!] Everything.exe not found, skipping..." -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "   SCRIPT COMPLETED SUCCESSFULLY" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Press any key to continue..." -ForegroundColor Magenta
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
