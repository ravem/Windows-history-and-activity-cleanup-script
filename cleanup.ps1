# =============================
# SCRIPT DI PULIZIA WINDOWS 11 
# =============================

# --- 1. Verifica Privilegi Amministratore ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERRORE: Devi eseguire lo script come AMMINISTRATORE." -ForegroundColor Red
    pause
    break
}

# Variabile per tracciare gli elementi eliminati
$LogEliminati = New-Object System.Collections.Generic.List[string]

# Funzione per eliminare e loggare
function Remove-AndLog {
    param ([string]$Path, [switch]$Recurse)
    if (Test-Path $Path) {
        try {
            Remove-Item -Path $Path -Force -Recurse:$Recurse -ErrorAction Stop
            $LogEliminati.Add("ELIMINATO: $Path")
        } catch {
            $LogEliminati.Add("ERRORE (In uso?): $Path")
        }
    }
}

Write-Host "--- AVVIO PULIZIA TOTALE (SISTEMA E BROWSER) ---" -ForegroundColor Magenta

# --- 2. Arresto Servizi e Processi ---
Write-Host "[*] Arresto servizi e app..." -ForegroundColor Yellow
$Services = @("WSearch")
foreach ($s in $Services) { Stop-Service -Name $s -Force -ErrorAction SilentlyContinue }

# Processi da chiudere (NON inclusi i terminali per non interrompere lo script)
$Processi = @("msedge", "chrome", "firefox", "brave", "explorer", "SearchHost", "SearchIndexer", "notepad++")
foreach ($p in $Processi) { Stop-Process -Name $p -Force -ErrorAction SilentlyContinue }
Start-Sleep -Seconds 2

# --- 3. Registro e Ricerca ---
Write-Host "[*] Pulizia Registro e Indice Ricerca..." -ForegroundColor Cyan
$SearchRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows Search"
if (Test-Path $SearchRegistryPath) {
    Set-ItemProperty -Path $SearchRegistryPath -Name "RebuildIndex" -Value 1 -ErrorAction SilentlyContinue
    $LogEliminati.Add("REGISTRO: Reset Indice Ricerca impostato")
}

$RegPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\RecentSearches",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\WorldWheelQuery",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
)
foreach ($reg in $RegPaths) {
    if (Test-Path $reg) {
        Remove-Item -Path $reg -Recurse -Force -ErrorAction SilentlyContinue
        $LogEliminati.Add("REGISTRO: $reg")
    }
}

# --- 4. Browser Chromium (Versione Aggiornata) ---
Write-Host "[*] Pulizia Browser Chromium (Sessioni e Cronologia)..." -ForegroundColor Yellow
$ChromiumBrowsers = @{
    "Google Chrome" = "$env:LOCALAPPDATA\Google\Chrome\User Data"
    "Microsoft Edge" = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
    "Brave Browser"  = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
}

foreach ($browser in $ChromiumBrowsers.Keys) {
    $rootPath = $ChromiumBrowsers[$browser]
    if (Test-Path $rootPath) {
        # Cerca il profilo Default e tutti i Profile X
        $Profiles = Get-ChildItem -Path $rootPath -Directory | Where-Object { $_.Name -eq "Default" -or $_.Name -like "Profile *" }
        
        foreach ($profile in $Profiles) {
            $pPath = $profile.FullName
            
            # 1. Elenco file specifici da eliminare (inclusi Current Session e Current Tabs)
            $FilesToRemove = @(
                "History", "Cookies", "Web Data", "Login Data", "Top Sites", 
                "Visited Links", "Last Tabs", "Last Session", 
                "Current Tabs", "Current Session", "Shortcuts", "Network Action Predictor"
            )
            
            foreach ($f in $FilesToRemove) {
                Remove-AndLog -Path "$pPath\$f"
            }
            
            # 2. Eliminazione cartelle critiche per le sessioni e cache
            $FoldersToRemove = @("Sessions", "Session Storage", "Cache", "Code Cache", "GPUCache")
            foreach ($folder in $FoldersToRemove) {
                Remove-AndLog -Path "$pPath\$folder" -Recurse
            }
        }
    }
}

# --- 5. Firefox ---
$FFPath = "$env:APPDATA\Mozilla\Firefox\Profiles"
if (Test-Path $FFPath) {
    Get-ChildItem -Path $FFPath -Directory | ForEach-Object {
        $p = $_.FullName
        foreach ($f in @("places.sqlite", "cookies.sqlite", "formhistory.sqlite", "sessionstore.jsonlz4")) {
            Remove-AndLog -Path "$p\$f"
        }
        $ffCache = $p.Replace("Roaming", "Local")
        Remove-AndLog -Path "$ffCache\cache2" -Recurse
    }
}

# --- 6. Cronologia Terminali ---
Write-Host "[*] Pulizia cronologia comandi..." -ForegroundColor Red
foreach ($file in @("$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt", "$env:LOCALAPPDATA\Microsoft\PowerShell\PSReadLine\ConsoleHost_history.txt")) {
    Remove-AndLog -Path $file
}
Clear-History
if (Get-Module -ListAvailable PSReadLine) { [Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory() }

# --- 7. File Temporanei e Log ---
Write-Host "[*] Pulizia file temporanei e log..." -ForegroundColor Yellow
$TempPaths = @("$env:TEMP\*", "C:\Windows\Temp\*", "C:\Windows\Prefetch\*")
foreach ($tp in $TempPaths) { 
    Get-ChildItem -Path $tp -ErrorAction SilentlyContinue | ForEach-Object { Remove-AndLog -Path $_.FullName -Recurse }
}

# Svuotamento Log Eventi
Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | ForEach-Object {
    try { 
        [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog($_.LogName)
        $LogEliminati.Add("LOG SVUOTATO: $($_.LogName)")
    } catch {}
}

# --- 8. Notepad++ ---
$NppPath = "$env:APPDATA\Notepad++"
if (Test-Path $NppPath) {
    Remove-AndLog -Path "$NppPath\session.xml"
    Remove-AndLog -Path "$NppPath\backup" -Recurse
}

# --- 9. Ripristino Sistema ---
Write-Host "[*] Ripristino servizi e interfaccia..." -ForegroundColor Yellow
Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue
Clear-DnsClientCache
Start-Service -Name "WSearch" -ErrorAction SilentlyContinue
Start-Process "explorer.exe"

# --- 10. REPORT FINALE A VIDEO ---
Clear-Host
Write-Host "=========================================" -ForegroundColor Green
Write-Host "           REPORT  PULIZIA               " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
if ($LogEliminati.Count -gt 0) {
    $LogEliminati | ForEach-Object {
        if ($_ -like "ERRORE*") { Write-Host $_ -ForegroundColor Red }
        else { Write-Host $_ -ForegroundColor Gray }
    }
} else {
    Write-Host "Nessuna operazione necessaria." -ForegroundColor Cyan
}
Write-Host ""
Write-Host "----------------------------------------------------" -ForegroundColor Green
Write-Host "TOTALE AZIONI: $($LogEliminati.Count)" -ForegroundColor Green
Write-Host "----------------------------------------------------" -ForegroundColor Green
Pause