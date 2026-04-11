chcp 65001 > $null
Clear-Host
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

# Цветовая схема
$C1 = [char]27 + "[38;5;129m"
$C2 = [char]27 + "[38;5;93m"  
$C3 = [char]27 + "[38;5;57m"  
$W  = [char]27 + "[37m"         
$G  = [char]27 + "[38;5;118m" 
$GL = [char]27 + "[38;5;136m" 
$R  = [char]27 + "[0m"         
$RED = [char]27 + "[38;5;196m" 
$ORG = [char]27 + "[38;5;208m" 

# Принудительно включаем TLS 1.2 для работы с GitHub
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$frames = @(
@"
$C1    __                ___          
$C1   / /  ___  ___ ____/ (_)__  ___ _
$C2  / /__/ _ \/ _ `/ _  / / _ \/ _ `/
$C3 /____/\___/\_,_/\_,_/_/_//_/\_, / 
$C3                            /___/  
"@,
@"
$C1    __                ___          
$C1   / /  ___  ___ ____/ (_)__  ___ _
$C2  / /__/ _ \/ _ `/ _  / / _ \/ _ `/
$C3 /____/\___/\_,_/\_,_/_/_//_/\_, (_)
$C3                            /___/  
"@,
@"
$C1    __                ___                
$C1   / /  ___  ___ ____/ (_)__  ___ _      
$C2  / /__/ _ \/ _ `/ _  / / _ \/ _ `/ _   
$C3 /____/\___/\_,_/\_,_/_/_//_/\_, (_|_) 
$C3                            /___/        
"@,
@"
$C1    __                ___                  
$C1   / /  ___  ___ ____/ (_)__  ___ _        
$C2  / /__/ _ \/ _ `/ _  / / _ \/ _ `/ _ _   
$C3 /____/\___/\_,_/\_,_/_/_//_/\_, (_|_|_) 
$C3                            /___/          
"@
)

Write-Host -NoNewline ([char]27 + "[?25l")
for ($i = 1; $i -le 2; $i++) {
    foreach ($f in $frames) {
        Write-Host -NoNewline ([char]27 + "[H")
        Write-Host "`n"
        Write-Host ($f + $R)
        Start-Sleep -Milliseconds 700 
    }
}
Write-Host -NoNewline ([char]27 + "[?25h")
Clear-Host

$banner = @(
    @{ Text = "  ______  _____       _____ _               _             "; Color = $C1 }
    @{ Text = " |  ____|/ ____|     / ____| |             | |            "; Color = $C1 }
    @{ Text = " | |__  | (___      | |    | |__   ___  ___| | _____ _ __ "; Color = $C2 }
    @{ Text = " |  __|  \___ \     | |    | '_ \ / _ \/ __| |/ / _ \ '__|"; Color = $C2 }
    @{ Text = " | |     ____) |    | |____| | | |  __/ (__|  <  __/ |    "; Color = $C3 }
    @{ Text = " |_|    |_____/      \_____|_| |_|\___|\___|_|\_\___|_|    "; Color = $C3 }
)

Write-Host ""
foreach ($line in $banner) {
    Write-Host ($line.Color + $line.Text + $R)
    Start-Sleep -Milliseconds 60
}

Write-Host ""
Write-Host "                $($GL)Developers: op4ox, net_dobra$R"
Write-Host ""

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Administrator rights are required for operation." -ForegroundColor Red
    while($true) { Start-Sleep -Seconds 3600 }
    exit 1
}
Write-Host ($G + "[+] Administrator rights: OK" + $R)

$workPath = "C:\FSChecker"
if (-not (Test-Path $workPath)) { New-Item -ItemType Directory -Path $workPath -Force | Out-Null }
Set-Location $workPath

Write-Host ($G + "[*] Stopping interfering processes..." + $R)
$processesToStop = @("obs64", "obs32", "obs", "ayugram", "telegram", "nvcontainer", "gamebar", "wallpaper32", "wallpaper64", "steam", "lively")
foreach ($proc in $processesToStop) {
    Get-Process -Name $proc -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue | Out-Null
}

$clipboardService = Get-Service -Name "*cbdhsvc*" -ErrorAction SilentlyContinue
if ($clipboardService) { 
    Stop-Service -Name $clipboardService.Name -Force -ErrorAction SilentlyContinue 
}

# --- [1/6] COLLECTING SYSTEM INFORMATION ---
$SystemUser = $env:USERNAME
$SystemName = (Get-CimInstance Win32_OperatingSystem).Caption
$SystemUID = (Get-CimInstance -ClassName Win32_ComputerSystemProduct).UUID
$SystemCPU = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name.Trim()
$SystemCPUSerial = (Get-CimInstance Win32_Processor | Select-Object -First 1).ProcessorId.trim()
$SystemDiskSerial = (Get-Disk | Select-Object -First 1).SerialNumber.trim()
$SystemBootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss')
$SystemHWID = $SystemCPUSerial + $SystemDiskSerial

Write-Host "`n[1/6] COLLECTING SYSTEM INFORMATION..." -ForegroundColor White
Write-Host "    Username: $SystemUser" -ForegroundColor White
Write-Host "    OS: $SystemName" -ForegroundColor White
Write-Host "    CPU: $SystemCPU" -ForegroundColor White
Write-Host "    UUID: $SystemUID" -ForegroundColor White
Write-Host "    HWID: $SystemHWID" -ForegroundColor White
Write-Host "    Boot Time: $SystemBootTime" -ForegroundColor White
Write-Host "    Current Time: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')" -ForegroundColor White

# --- SERVICE STATUS ---
Write-Host "`n[*] SERVICE STATUS :" -ForegroundColor White
$ServicesToCheck = @(
    @{ Name = "SysMain"; Display = "SysMain" },
    @{ Name = "DiagTrack"; Display = "DiagTrack" },
    @{ Name = "PcaSvc"; Display = "PcaSvc" },
    @{ Name = "Appinfo"; Display = "Appinfo" },
    @{ Name = "Bam"; Display = "Bam" },
    @{ Name = "Power"; Display = "Power" },
    @{ Name = "WSearch"; Display = "WSearch" },
    @{ Name = "DPS"; Display = "DPS" },
    @{ Name = "EventLog"; Display = "EventLog" },
    @{ Name = "CDPSvc"; Display = "CDPSvc" }
)

foreach ($Svc in $ServicesToCheck) {
    try {
        $ServiceObj = Get-Service -Name $Svc.Name -ErrorAction Stop
        $Label = "    $($Svc.Display.PadRight(25))"
        if ($ServiceObj.Status -eq "Running") {
            Write-Host -NoNewline ($W + $Label + $R)
            Write-Host ($G + "[ Running ]" + $R)
        } else {
            Write-Host -NoNewline ($W + $Label + $R)
            Write-Host ($ORG + "[ Stopped ]" + $R)
        }
    } catch {
        Write-Host -NoNewline ($W + "    $($Svc.Display.PadRight(25))" + $R)
        Write-Host ($RED + "[ Not Found ]" + $R)
    }
}

# --- [2/6] RUNNING BAM PARSER ---
Write-Host "`n[2/6] RUNNING BAM PARSER..." -ForegroundColor White

function Get-Signature {
    param ([string[]]$FilePath)
    if (Test-Path -PathType "Leaf" -Path $FilePath) {
        $Authenticode = (Get-AuthenticodeSignature -FilePath $FilePath -ErrorAction SilentlyContinue).Status
        if ($Authenticode -eq "Valid") { return "Valid Signature" }
        elseif ($Authenticode -eq "NotSigned") { return "Invalid Signature (NotSigned)" }
        else { return "Invalid Signature" }
    } else { return "File Was Not Found" }
}

try {
    $Users = foreach($ii in ("bam", "bam\State")) {
        Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$($ii)\UserSettings\" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty PSChildName
    }
} catch { $Users = @() }

if ($Users) {
    Write-Host ("Time".PadRight(20) + "Application".PadRight(25) + "Signature".PadRight(30) + "Path") -ForegroundColor White
    Write-Host ("----".PadRight(20) + "-----------".PadRight(25) + "---------".PadRight(30) + "----") -ForegroundColor White

    $rpath = @("HKLM:\SYSTEM\CurrentControlSet\Services\bam\","HKLM:\SYSTEM\CurrentControlSet\Services\bam\state\")
    $BamList = @()
    foreach ($Sid in $Users) {
        foreach($rp in $rpath) {
            $Items = Get-Item -Path "$($rp)UserSettings\$Sid" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Property
            ForEach ($Item in $Items) {
                $Val = Get-ItemProperty -Path "$($rp)UserSettings\$Sid" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $Item
                If($Val.length -eq 24) {
                    $Hex = [System.BitConverter]::ToString($Val[7..0]) -replace "-",""
                    $SortDate = [DateTime]::FromFileTimeUtc([Convert]::ToInt64($Hex, 16))
                    $TimeStr = $SortDate.ToString("dd.MM.yy HH:mm")
                    
                    if((((split-path -path $Item) | ConvertFrom-String -Delimiter "\\").P3)-match '\d{1}') {
                        $fPath = Join-Path -Path "C:" -ChildPath ($Item).Remove(1,23)
                        $sig = Get-Signature -FilePath $fPath
                        $app = Split-path -leaf ($Item).TrimStart()
                    } else { $fPath = ""; $sig = "N/A"; $app = $Item }
                    
                    $BamList += [PSCustomObject]@{ 'Time' = $TimeStr; 'App' = $app; 'Sig' = $sig; 'Path' = $fPath; 'Sort' = $SortDate }
                }
            }
        }
    }
    
    $FinalBam = $BamList | Where-Object { $_.Sig -ne "Valid Signature" -and $_.Sig -ne "N/A" } | Sort-Object Sort -Descending
    
    foreach ($e in $FinalBam) {
        $statusColor = if ($e.Sig -eq "Invalid Signature (NotSigned)") { $RED } else { $ORG }
        Write-Host -NoNewline ($statusColor + $e.Time.PadRight(20) + $R)
        Write-Host -NoNewline ($W + $e.App.PadRight(25) + $R)
        Write-Host -NoNewline ($statusColor + $e.Sig.PadRight(30) + $R)
        Write-Host ($W + $e.Path + $R)
    }
}

# --- [3/6] RECYCLE BIN ANALYSIS ---
Write-Host "`n[3/6] RECYCLE BIN ANALYSIS..." -ForegroundColor White
$Drives = Get-PSDrive -PSProvider FileSystem
$LatestClean = $null
$FoundAnyFile = $false

Write-Host ("Time".PadRight(20) + "File Name".PadRight(25) + "Status".PadRight(20) + "Original Path") -ForegroundColor White
Write-Host ("----".PadRight(20) + "---------".PadRight(25) + "------".PadRight(20) + "-------------") -ForegroundColor White

foreach ($Drive in $Drives) {
    $RecyclePath = Join-Path -Path $Drive.Root -ChildPath "`$Recycle.Bin"
    if (Test-Path $RecyclePath) {
        $Items = Get-ChildItem -Path $RecyclePath -Include "`$I*" -File -Recurse -Force -ErrorAction SilentlyContinue
        foreach ($Item in $Items) {
            $FoundAnyFile = $true
            try {
                $bytes = [System.IO.File]::ReadAllBytes($Item.FullName)
                $ft = [System.BitConverter]::ToInt64($bytes, 16)
                $dropTime = [DateTime]::FromFileTime($ft)
                $TimeStr = $dropTime.ToString("dd.MM.yy HH:mm")
                $origNameBytes = $bytes[24..($bytes.Length - 1)]
                $origPath = [System.Text.Encoding]::Unicode.GetString($origNameBytes).TrimEnd("`0")
                $fileName = Split-Path -Leaf $origPath
                
                if ($null -eq $LatestClean -or $dropTime -gt $LatestClean) { $LatestClean = $dropTime }

                $sigStatus = Get-Signature -FilePath $origPath
                $statusColor = if ($sigStatus -eq "Valid Signature") { $G } else { $RED }

                Write-Host -NoNewline ($W + $TimeStr.PadRight(20) + $R)
                Write-Host -NoNewline ($W + $fileName.PadLeft(1).Substring(0, [Math]::Min($fileName.Length, 24)).PadRight(25) + $R)
                Write-Host -NoNewline ($statusColor + $sigStatus.PadRight(20) + $R)
                Write-Host ($W + $origPath + $R)
            } catch { continue }
        }
    }
}

if (-not $FoundAnyFile) {
    Write-Host -NoNewline ($ORG + "N/A".PadRight(20) + $R)
    Write-Host -NoNewline ($W + "EMPTY".PadRight(25) + $R)
    Write-Host ($G + "OK" + $R)
}

if ($null -ne $LatestClean) {
    Write-Host "`nLatest update: $($LatestClean.ToString('dd.MM.yyyy HH:mm:ss'))" -ForegroundColor Yellow
}

# --- [4/6] EVENT LOG ANALYSIS ---
Write-Host "`n[4/6] EVENT LOG ANALYSIS..." -ForegroundColor White

try {
    $e = Get-WinEvent -FilterHashtable @{LogName="Application"; ID=3079} -MaxEvents 1 -ErrorAction Stop
    Write-Host -NoNewline "  [!] USN Journal (ID 3079): " -ForegroundColor Yellow
    Write-Host $e.TimeCreated.ToString("dd.MM.yy HH:mm") -ForegroundColor White
} catch {
    Write-Host "  [+] USN Journal (ID 3079): Not found" -ForegroundColor Green
}

try {
    $e = Get-WinEvent -FilterHashtable @{LogName="Security"; ID=1102} -MaxEvents 1 -ErrorAction Stop
    Write-Host -NoNewline "$ORG  [!] Security Log Clear (ID 1102): "
    Write-Host $e.TimeCreated.ToString("dd.MM.yy HH:mm") -ForegroundColor White
} catch {
    Write-Host "  [+] Security Log Clear (ID 1102): Not found" -ForegroundColor Green
}

# --- [5/6] JVMTI DETECTOR ---
Write-Host "`n[5/6] JVMTI DETECTOR..." -ForegroundColor White

$PATTERN_A = [uint32]524294
$PATTERN_B = [uint32]4242546329

function Find-DwordInBytes {
    param([byte[]]$Buffer, [uint32]$Target, [int]$BaseOffset)
    $i = 0
    while ($i + 4 -le $Buffer.Length) {
        $val = [System.BitConverter]::ToUInt32($Buffer, $i)
        if ($val -eq $Target) { return $BaseOffset + $i }
        $i += 4
    }
    return $null
}

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class WinMem {
    [DllImport("kernel32.dll")]
    public static extern IntPtr OpenProcess(uint dwAccess, bool bInherit, int dwPid);
    [DllImport("kernel32.dll")]
    public static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBase, byte[] lpBuffer, int nSize, out int lpRead);
    [DllImport("kernel32.dll")]
    public static extern bool CloseHandle(IntPtr hObject);
}
'@ -ErrorAction SilentlyContinue

function Scan-JvmDll {
    param([System.Diagnostics.Process]$Process)
    $jvmModule = $null
    try { $jvmModule = $Process.Modules | Where-Object { $_.ModuleName -ieq "jvm.dll" } | Select-Object -First 1 } catch {}
    if (-not $jvmModule) { return $null }

    $baseAddr   = $jvmModule.BaseAddress.ToInt64()
    $moduleSize = $jvmModule.ModuleMemorySize
    $hProc = [WinMem]::OpenProcess(0x0410, $false, $Process.Id)
    if ($hProc -eq [IntPtr]::Zero) { return $null }

    try {
        $chunkSize = 256 * 1024
        $hitA = $null; $hitB = $null; $offset = 0
        while ($offset -lt $moduleSize) {
            $toRead = [Math]::Min($chunkSize, $moduleSize - $offset)
            $buf    = New-Object byte[] $toRead
            $read   = 0
            $addr   = [IntPtr]($baseAddr + $offset)
            $ok     = [WinMem]::ReadProcessMemory($hProc, $addr, $buf, $toRead, [ref]$read)
            if ($ok -and $read -gt 0) {
                $slice = if ($read -lt $buf.Length) { $buf[0..($read-1)] } else { $buf }
                if ($null -eq $hitA) { $hitA = Find-DwordInBytes -Buffer $slice -Target $PATTERN_A -BaseOffset $offset }
                if ($null -eq $hitB) { $hitB = Find-DwordInBytes -Buffer $slice -Target $PATTERN_B -BaseOffset $offset }
            }
            $offset += $chunkSize
        }
        return [PSCustomObject]@{ Pid = $Process.Id; JvmPath = $jvmModule.FileName; HitA = $hitA; HitB = $hitB }
    } finally {
        [WinMem]::CloseHandle($hProc) | Out-Null
    }
}

$javawProcs = Get-Process -Name "javaw" -ErrorAction SilentlyContinue

if (-not $javawProcs) {
    Write-Host ($W + "  [+] Minecraft not found" + $R)
} else {
    $jvmtiFound   = $false
    $jvmtiPartial = $false
    foreach ($proc in @($javawProcs)) {
        $result = Scan-JvmDll -Process $proc
        if (-not $result) { continue }
        $bothHit = ($null -ne $result.HitA) -and ($null -ne $result.HitB)
        $anyHit  = ($null -ne $result.HitA) -or  ($null -ne $result.HitB)
        if ($bothHit) { $jvmtiFound = $true; break }
        if ($anyHit)  { $jvmtiPartial = $true }
    }

    if ($jvmtiFound) {
        Write-Host ($RED + "  [!] JVMTI inject detect" + $R)
    } elseif ($jvmtiPartial) {
        Write-Host ($ORG + "  [?] JVMTI inject possible detect" + $R)
    } else {
        Write-Host ($G + "  [+] JVMTI inject not detected" + $R)
    }
}

# --- [6/6] OPENING UTILS ---
Write-Host "`n[6/6] OPENING UTILS..." -ForegroundColor White

$SilentUtils = @(
    @{ Path = "USBDriveLog.exe"; URL = "https://cdn.discordapp.com/attachments/1491468384255086634/1491511410050728096/USBDriveLog.exe" }
    @{ Path = "JournalTrace.exe"; URL = "https://github.com/ponei/JournalTrace/releases/download/1.0/JournalTrace.exe" }
    @{ Path = "ShellBagAnalyzerCleaner.exe"; URL = "https://raw.githubusercontent.com/koras5880-alt/shellbag/refs/heads/main/ShellBagAnalyzerCleaner.exe" }
    @{ Path = "Everything.exe"; URL = "https://raw.githubusercontent.com/koras5880-alt/everything/refs/heads/main/Everything.exe" }
)

foreach ($u in $SilentUtils) {
    $p = Join-Path $workPath $u.Path
    if (-not (Test-Path $p)) {
        try { Invoke-WebRequest -Uri $u.URL -OutFile $p -UseBasicParsing } catch {}
    }
    if (Test-Path $p) {
        Unblock-File -Path $p
        Start-Process -FilePath $p -WorkingDirectory $workPath -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
    }
}

Write-Host ($G + "[+] OK" + $R)

while($true) { Start-Sleep -Seconds 3600 }
