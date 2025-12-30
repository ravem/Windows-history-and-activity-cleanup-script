# ======================================
# SCRIPT DI PULIZIA PROFONDA WINDOWS 11 
# ======================================

# --- 1. Verifica Privilegi Amministratore ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERRORE: Devi eseguire lo script come AMMINISTRATORE." -ForegroundColor Red
    pause
    break
}

$LogEliminati = New-Object System.Collections.Generic.List[string]

function Remove-AndLog {
    param ([string]$Path, [switch]$Recurse)
    if (Test-Path $Path) {
        try {
            Remove-Item -Path $Path -Force -Recurse:$Recurse -ErrorAction Stop
            $LogEliminati.Add("ELIMINATO: $Path")
        } catch {
            $LogEliminati.Add("ERRORE (In uso o negato): $Path")
        }
    }
}

Write-Host "--- AVVIO PULIZIA TOTALE (SISTEMA, BROWSER E SESSIONI WEB) ---" -ForegroundColor Magenta

# --- 2. Arresto Aggressivo Processi e Servizi ---
# Aggiunti processi che spesso tengono aperti database dei browser
Write-Host "[*] Arresto servizi e applicazioni in corso..." -ForegroundColor Yellow
$Processi = @("msedge", "chrome", "firefox", "brave", "explorer", "SearchHost", "SearchIndexer", "notepad++", "runtimebroker")
foreach ($p in $Processi) { 
    Stop-Process -Name $p -Force -ErrorAction SilentlyContinue 
}
Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue

# Attesa necessaria affinché il sistema rilasci i lock sui file
Write-Host "[*] Attesa rilascio file (4 secondi)..." -ForegroundColor Gray
Start-Sleep -Seconds 4

# --- 3. Browser Chromium (Chrome, Edge, Brave) Corretto ---
$ChromiumPaths = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data",
    "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
)

foreach ($BasePath in $ChromiumPaths) {
    if (Test-Path $BasePath) {
        Write-Host "[*] Pulizia in corso per: $BasePath" -ForegroundColor Gray
        # Trova tutte le cartelle profilo
        $ProfileFolders = Get-ChildItem -Path $BasePath -Directory | Where-Object { $_.Name -match "Default|Profile" }
        
        foreach ($PDir in $ProfileFolders) {
            $pPath = $PDir.FullName
            
            # File specifici per le sessioni
            $Items = @(
                "$pPath\Network\Cookies",
                "$pPath\Network\Cookies-journal",
                "$pPath\Network\Network Persistent State",
                "$pPath\Cookies",
                "$pPath\Login Data",
                "$pPath\Web Data",
                "$pPath\Sessions",
                "$pPath\Session Storage",
                "$pPath\Local Storage",
                "$pPath\IndexedDB",
                "$pPath\Extension State"
            )

            foreach ($item in $Items) {
                if (Test-Path $item) {
                    Remove-AndLog -Path $item -Recurse
                }
            }
        }
    }
}

# --- 4. Firefox (Gestione Storage e Sessioni) ---
Write-Host "[*] Pulizia Firefox..." -ForegroundColor Yellow
$FFPath = "$env:APPDATA\Mozilla\Firefox\Profiles"
if (Test-Path $FFPath) {
    Get-ChildItem -Path $FFPath -Directory | ForEach-Object {
        $p = $_.FullName
        # File di database e sessione
        foreach ($f in @("places.sqlite", "cookies.sqlite", "formhistory.sqlite", "sessionstore.jsonlz4", "storage.sqlite")) {
            Remove-AndLog -Path "$p\$f"
        }
        # Cartelle di archiviazione persistente (dove risiedono i dati dei siti)
        Remove-AndLog -Path "$p\storage" -Recurse
        Remove-AndLog -Path "$p\sessionstore-backups" -Recurse
        
        # Cache locale
        $ffCache = $p.Replace("Roaming", "Local")
        Remove-AndLog -Path "$ffCache\cache2" -Recurse
    }
}

# --- 5. Registro, Ricerca e Terminale ---
Write-Host "[*] Pulizia Registro e Cronologia Terminale..." -ForegroundColor Cyan
$RegPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\RecentSearches",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
)
foreach ($reg in $RegPaths) {
    if (Test-Path $reg) { Remove-Item -Path $reg -Recurse -Force -ErrorAction SilentlyContinue }
}

foreach ($file in @("$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt", "$env:LOCALAPPDATA\Microsoft\PowerShell\PSReadLine\ConsoleHost_history.txt")) {
    Remove-AndLog -Path $file
}
[Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory()

# --- 6. File Temporanei di Sistema ---
Write-Host "[*] Svuotamento Temp e Log di Sistema..." -ForegroundColor Yellow
$TempPaths = @("$env:TEMP\*", "C:\Windows\Temp\*", "C:\Windows\Prefetch\*")
foreach ($tp in $TempPaths) { 
    Get-ChildItem -Path $tp -ErrorAction SilentlyContinue | ForEach-Object { Remove-AndLog -Path $_.FullName -Recurse }
}

# Svuotamento Log Eventi (opzionale, richiede tempo)
Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | ForEach-Object {
    try { [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog($_.LogName) } catch {}
}

#Svuotamento cartella downloads
Remove-Item -Path "$env:USERPROFILE\Downloads\*" -Recurse -Force


# --- 7. Ripristino ---
Write-Host "[*] Ripristino ambiente..." -ForegroundColor Yellow
Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue
Clear-DnsClientCache
Start-Service -Name "WSearch" -ErrorAction SilentlyContinue
Start-Process "explorer.exe"

# --- 8. REPORT FINALE ---
Clear-Host
Write-Host "========================" -ForegroundColor Green
Write-Host "    PULIZIA COMPLETATA  " -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green
Write-Host "Le sessioni browser sono state rimosse."
Write-Host "Totale azioni eseguite: $($LogEliminati.Count)"
Write-Host "-----------------------------------------"
Pause
