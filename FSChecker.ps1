# ============================================
# 6. СКАЧИВАНИЕ И ЗАПУСК ShellBag Analyzer
# ============================================
Write-Host "`n[6/7] DOWNLOADING AND RUNNING ShellBag Analyzer & Cleaner..." -ForegroundColor Magenta

$shellbagExe = "ShellBagAnalyzerCleaner.exe"
if (-not (Test-Path $shellbagExe)) {
    try {
        Invoke-WebRequest -Uri "https://privazer.com/ru/shellbag_analyzer_cleaner.exe" -OutFile $shellbagExe -UseBasicParsing
        Write-Host "[+] ShellBag Analyzer successfully downloaded" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Error downloading ShellBag Analyzer: $_" -ForegroundColor Red
    }
}

if (Test-Path $shellbagExe) {
    Write-Host "[*] Running ShellBag Analyzer & Cleaner..." -ForegroundColor Magenta
    try {
        Start-Process -FilePath ".\$shellbagExe" -WindowStyle Normal
        Write-Host "[+] ShellBag Analyzer started" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Error running ShellBag Analyzer: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "[!] ShellBag Analyzer not found, skipping..." -ForegroundColor Red
}

Start-Sleep -Seconds 2

# ============================================
# 7. СКАЧИВАНИЕ И ЗАПУСК Everything + конфиг
# ============================================
Write-Host "`n[7/7] DOWNLOADING AND RUNNING Everything.exe..." -ForegroundColor Magenta

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
