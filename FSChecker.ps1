chcp 65001 > $null
Clear-Host
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

# БАННЕР
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
Write-Host "║                                                     FUNSKY CHECKER v2.0                                                 ║" -ForegroundColor DarkMagenta
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

# СОЗДАНИЕ ПАПКИ ДЛЯ ЛОГОВ
$logsPath = "$workPath\Logs"
if (-not (Test-Path $logsPath)) { New-Item -ItemType Directory -Path $logsPath -Force | Out-Null }

# ОСТАНОВКА ПРОЦЕССОВ
Write-Host "[*] Stopping interfering processes..." -ForegroundColor Magenta
$processesToStop = @("obs64", "obs32", "obs", "ayugram", "telegram", "nvcontainer", "gamebar", "wallpaper32", "wallpaper64", "steam", "lively")
foreach ($proc in $processesToStop) {
    Get-Process -Name $proc -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue | Out-Null
}
Write-Host "[*] Stopping clipboard history service..." -ForegroundColor Magenta
Get-Service -Name "*cbdhsvc*" -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue | Out-Null

# ============================================
# 0. ИНФОРМАЦИЯ О СИСТЕМЕ
# ============================================
Write-Host "`n[0/6] COLLECTING SYSTEM INFORMATION..." -ForegroundColor Magenta
$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$disk = Get-Disk | Select-Object -First 1
$SystemUID = (Get-CimInstance -ClassName Win32_ComputerSystemProduct).UUID
$SystemHWID = $cpu.ProcessorId.Trim() + $disk.SerialNumber.Trim()
$ram = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
$gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notlike "*Remote*" -and $_.Name -notlike "*Mirror*" } | Select-Object -First 1

$systemInfo = @"
═══════════════════════════════════════════════════════════════
SYSTEM INFORMATION
═══════════════════════════════════════════════════════════════
Username:      $env:USERNAME
Computer:      $env:COMPUTERNAME
OS:            $($os.Caption)
OS Version:    $($os.Version)
OS Build:      $($os.BuildNumber)
Last Boot:     $($os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss'))
Current Time:  $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')
Time Zone:     $((Get-TimeZone).DisplayName)
───────────────────────────────────────────────────────────────
CPU:           $($cpu.Name.Trim())
CPU Cores:     $($cpu.NumberOfCores)
CPU Serial:    $($cpu.ProcessorId.Trim())
───────────────────────────────────────────────────────────────
RAM Total:     $([math]::Round($ram.Sum / 1GB, 2)) GB
RAM Slots:     $($ram.Count)
───────────────────────────────────────────────────────────────
GPU:           $($gpu.Name)
GPU VRAM:      $([math]::Round($gpu.AdapterRAM / 1GB, 2)) GB
───────────────────────────────────────────────────────────────
Disk Model:    $($disk.Model)
Disk Size:     $([math]::Round($disk.Size / 1GB, 2)) GB
Disk Serial:   $($disk.SerialNumber.Trim())
───────────────────────────────────────────────────────────────
UUID:          $SystemUID
HWID:          $SystemHWID
═══════════════════════════════════════════════════════════════
"@

Write-Host $systemInfo -ForegroundColor White
$systemInfo | Out-File "$logsPath\0_SystemInfo.txt" -Encoding UTF8
Write-Host "[+] System info saved to: $logsPath\0_SystemInfo.txt" -ForegroundColor Green

Start-Sleep -Seconds 2

# ============================================
# 1. BAM ПАРСЕР
# ============================================
Write-Host "`n[1/6] RUNNING BAM ANALYZER..." -ForegroundColor Magenta

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

$bamLog = @()
$bamLog += "═══════════════════════════════════════════════════════════════"
$bamLog += "BAM (Background Activity Moderator) ANALYSIS"
$bamLog += "═══════════════════════════════════════════════════════════════`n"

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
        $bamLog += "SUSPICIOUS BAM ENTRIES FOUND (newest to oldest):`n"
        $bamLog += "───────────────────────────────────────────────────────────────"
        
        $FilteredBam | ForEach-Object {
            if ($_.Signature -eq "File Was Not Found") {
                $bamLog += "[$($_.Time)] $($_.Application)"
                $bamLog += "    Status: $($_.Signature)"
                if ($_.Path) { $bamLog += "    Path: $($_.Path)" }
            } elseif ($_.Signature -match "Invalid Signature") {
                $bamLog += "[$($_.Time)] $($_.Application)"
                $bamLog += "    Status: $($_.Signature) [RED FLAG]"
                if ($_.Path) { $bamLog += "    Path: $($_.Path)" }
            }
            $bamLog += "───────────────────────────────────────────────────────────────"
        }
        
        $bamLog += "`nTotal suspicious entries: $($FilteredBam.Count)"
        
        Write-Host "    Suspicious BAM entries found: $($FilteredBam.Count)" -ForegroundColor Yellow
        $FilteredBam | ForEach-Object {
            Write-Host "    [$($_.Time)] $($_.Application)" -ForegroundColor Red
        }
    } else {
        $bamLog += "No suspicious BAM entries found."
        Write-Host "    No suspicious BAM entries found" -ForegroundColor Green
    }
} else {
    $bamLog += "Failed to get BAM data."
    Write-Host "    Failed to get BAM data" -ForegroundColor Gray
}

$bamLog += "`n═══════════════════════════════════════════════════════════════"
$bamLog | Out-File "$logsPath\1_BAM_Analysis.txt" -Encoding UTF8
Write-Host "[+] BAM log saved to: $logsPath\1_BAM_Analysis.txt" -ForegroundColor Green

Start-Sleep -Seconds 2

# ============================================
# 2. INJGEN
# ============================================
Write-Host "`n[2/6] DOWNLOADING AND RUNNING InjGen.exe..." -ForegroundColor Magenta
$injGenPath = "$workPath\InjGen.exe"
if (-not (Test-Path $injGenPath)) {
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/koras5880-alt/injgen/refs/heads/main/InjGen.exe" -OutFile $injGenPath
        Write-Host "[+] InjGen.exe downloaded to: $injGenPath" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Error downloading InjGen.exe" -ForegroundColor Red
    }
}

if (Test-Path $injGenPath) {
    Write-Host "[*] Running InjGen.exe..." -ForegroundColor DarkMagenta
    try {
        Start-Process -FilePath $injGenPath -WorkingDirectory $workPath
        Write-Host "[+] InjGen.exe started" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Error running InjGen.exe" -ForegroundColor Red
    }
}
else {
    Write-Host "[!] InjGen.exe not found" -ForegroundColor Red
}

Start-Sleep -Seconds 2

# ============================================
# 3. USB DRIVE LOG
# ============================================
Write-Host "`n[3/6] DOWNLOADING AND RUNNING USBDriveLog.exe..." -ForegroundColor Magenta
$usbDriveLogPath = "$workPath\USBDriveLog.exe"
if (-not (Test-Path $usbDriveLogPath)) {
    try {
        Invoke-WebRequest -Uri "https://cdn.discordapp.com/attachments/1491468384255086634/1491511410050728096/USBDriveLog.exe?ex=69d7f5bf&is=69d6a43f&hm=a56985b67e7087ab58cc410904871346dda6d04dec8bd12bfdc82e7207365605&" -OutFile $usbDriveLogPath
        Write-Host "[+] USBDriveLog.exe downloaded to: $usbDriveLogPath" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Error downloading USBDriveLog.exe: $_" -ForegroundColor Red
    }
}

if (Test-Path $usbDriveLogPath) {
    Write-Host "[*] Running USBDriveLog.exe..." -ForegroundColor Magenta
    try {
        Start-Process -FilePath $usbDriveLogPath -WorkingDirectory $workPath
        Write-Host "[+] USBDriveLog.exe started" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Error running USBDriveLog.exe: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "[!] USBDriveLog.exe not found" -ForegroundColor Red
}

Start-Sleep -Seconds 2

# ============================================
# 4. JOURNAL TRACE
# ============================================
Write-Host "`n[4/6] DOWNLOADING AND RUNNING JournalTrace.exe..." -ForegroundColor Magenta
$journalTracePath = "$workPath\JournalTrace.exe"
if (-not (Test-Path $journalTracePath)) {
    try {
        Invoke-WebRequest -Uri "https://github.com/ponei/JournalTrace/releases/download/1.0/JournalTrace.exe" -OutFile $journalTracePath
        Write-Host "[+] JournalTrace.exe downloaded to: $journalTracePath" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Error downloading JournalTrace.exe: $_" -ForegroundColor Red
    }
}

if (Test-Path $journalTracePath) {
    Write-Host "[*] Running JournalTrace.exe..." -ForegroundColor Magenta
    try {
        Start-Process -FilePath $journalTracePath -WorkingDirectory $workPath
        Write-Host "[+] JournalTrace.exe started" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Error running JournalTrace.exe: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "[!] JournalTrace.exe not found" -ForegroundColor Red
}

Start-Sleep -Seconds 2

# ============================================
# 5. SHELLBAG (АНАЛИЗ ИСТОРИИ ПАПОК)
# ============================================
Write-Host "`n[5/6] ANALYZING SHELLBAGS (Folder History)..." -ForegroundColor Magenta

$shellbagLog = @()
$shellbagLog += "═══════════════════════════════════════════════════════════════"
$shellbagLog += "SHELLBAG ANALYSIS (Windows Explorer Folder History)"
$shellbagLog += "═══════════════════════════════════════════════════════════════`n"

# Получаем SID текущего пользователя
$currentSid = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
$shellbagLog += "Current User SID: $currentSid`n"

# Пути к Shellbag в реестре
$shellbagPaths = @(
    "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\Shell\BagMRU",
    "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\Shell\Bags",
    "Registry::HKEY_USERS\$currentSid\Software\Microsoft\Windows\Shell\BagMRU",
    "Registry::HKEY_USERS\$currentSid\Software\Microsoft\Windows\Shell\Bags"
)

$totalFolders = 0
$shellbagData = @()

foreach ($path in $shellbagPaths) {
    if (Test-Path $path) {
        $shellbagLog += "[*] Analyzing: $path`n"
        
        # Функция для рекурсивного обхода BagMRU
        function Explore-BagMRU {
            param($regPath, $depth = 0)
            
            try {
                $items = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue
                foreach ($item in $items) {
                    $indent = "  " * $depth
                    $itemName = $item.PSChildName
                    
                    # Пропускаем NodeSlots
                    if ($itemName -eq "NodeSlots") { continue }
                    
                    # Пытаемся получить значение (путь к папке)
                    $folderPath = $null
                    try {
                        $folderData = (Get-ItemProperty -Path $item.PSPath -ErrorAction SilentlyContinue)."(default)"
                        if ($folderData) {
                            # Данные могут быть в бинарном формате, пытаемся извлечь строку
                            $folderPath = [System.Text.Encoding]::Unicode.GetString($folderData) -replace "`0", ""
                            if ($folderPath -match "^[A-Za-z]:\\") {
                                $shellbagData += [PSCustomObject]@{
                                    Path = $folderPath
                                    RegistryPath = $item.PSPath
                                }
                                $script:totalFolders++
                            }
                        }
                    }
                    catch { }
                    
                    # Рекурсивный обход
                    Explore-BagMRU -regPath $item.PSPath -depth ($depth + 1)
                }
            }
            catch { }
        }
        
        if ($path -match "BagMRU") {
            Explore-BagMRU -regPath $path
        } else {
            # Для Bags просто считаем количество
            try {
                $bags = Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue
                $bagCount = ($bags | Where-Object { $_.PSChildName -match "^\d+$" }).Count
                $totalFolders += $bagCount
                $shellbagLog += "    Found $bagCount bag entries`n"
            }
            catch { }
        }
    }
}

if ($shellbagData.Count -gt 0) {
    $shellbagLog += "`n───────────────────────────────────────────────────────────────"
    $shellbagLog += "ACCESSED FOLDERS (from BagMRU):"
    $shellbagLog += "───────────────────────────────────────────────────────────────"
    
    $shellbagData | Select-Object -First 50 | ForEach-Object {
        $shellbagLog += $_.Path
    }
    
    if ($shellbagData.Count -gt 50) {
        $shellbagLog += "... and $($shellbagData.Count - 50) more folders"
    }
    
    $shellbagLog += "`n───────────────────────────────────────────────────────────────"
    $shellbagLog += "TOTAL STATISTICS:"
    $shellbagLog += "───────────────────────────────────────────────────────────────"
    $shellbagLog += "Total unique folders accessed: $($shellbagData.Count)"
    $shellbagLog += "Total bag entries: $totalFolders"
    
    Write-Host "    Found $($shellbagData.Count) unique folders in Shellbag history" -ForegroundColor Yellow
} else {
    $shellbagLog += "No Shellbag data found or unable to read."
    Write-Host "    No Shellbag data found" -ForegroundColor Gray
}

$shellbagLog += "`n═══════════════════════════════════════════════════════════════"
$shellbagLog | Out-File "$logsPath\5_Shellbag_Analysis.txt" -Encoding UTF8
Write-Host "[+] Shellbag log saved to: $logsPath\5_Shellbag_Analysis.txt" -ForegroundColor Green

# Дополнительно экспортируем Shellbag в CSV
if ($shellbagData.Count -gt 0) {
    $shellbagData | Export-Csv "$logsPath\5_Shellbag_Folders.csv" -NoTypeInformation -Encoding UTF8
    Write-Host "[+] Shellbag CSV saved to: $logsPath\5_Shellbag_Folders.csv" -ForegroundColor Green
}

Start-Sleep -Seconds 2

# ============================================
# 6. EVERYTHING + КОНФИГ
# ============================================
Write-Host "`n[6/6] DOWNLOADING AND RUNNING Everything.exe..." -ForegroundColor Magenta

$everythingIniPath = "$workPath\Everything-1.5a.ini"
if (-not (Test-Path $everythingIniPath)) {
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/koras5880-alt/everything/refs/heads/main/Everything-1.5a.ini" -OutFile $everythingIniPath
        Write-Host "[+] Everything-1.5a.ini downloaded to: $everythingIniPath" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Error downloading Everything-1.5a.ini: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "[+] Everything-1.5a.ini already exists at: $everythingIniPath" -ForegroundColor Green
}

$everythingPath = "$workPath\Everything.exe"
if (-not (Test-Path $everythingPath)) {
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/koras5880-alt/everything/refs/heads/main/Everything.exe" -OutFile $everythingPath
        Write-Host "[+] Everything.exe downloaded to: $everythingPath" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Error downloading Everything.exe: $_" -ForegroundColor Red
    }
}

if (Test-Path $everythingPath) {
    Write-Host "[*] Running Everything.exe..." -ForegroundColor Magenta
    try {
        Start-Process -FilePath $everythingPath -WorkingDirectory $workPath
        Write-Host "[+] Everything.exe started" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Error running Everything.exe: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "[!] Everything.exe not found" -ForegroundColor Red
}

# ============================================
# ФИНАЛЬНЫЙ ОТЧЁТ
# ============================================
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "   SCRIPT COMPLETED SUCCESSFULLY" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "[+] All files saved to: $workPath" -ForegroundColor Green
Write-Host "[+] Logs saved to: $logsPath" -ForegroundColor Green
Write-Host ""
Write-Host "Generated files:" -ForegroundColor Yellow
Get-ChildItem $workPath | ForEach-Object { Write-Host "    - $($_.Name)" -ForegroundColor White }
Write-Host ""
Write-Host "Log files:" -ForegroundColor Yellow
Get-ChildItem $logsPath | ForEach-Object { Write-Host "    - $($_.Name)" -ForegroundColor White }
Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor Magenta
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
