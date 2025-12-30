# Windows history and activity cleanup cript

Questo script PowerShell è utile per la manutenzione e la pulizia di Windows 11.

##  Funzionalità principali

* ** Pulizia Totale Browser (Chromium & Firefox):**
    * Rimozione di Cronologia, Cookie, Cache e Scorciatoie.
    * **Eliminazione Sessioni Attive:** Chiude le schede che resterebbero in memoria.
* ** Manutenzione Windows Search:**
    * Reset e ricostruzione dell'indice di ricerca.
    * Pulizia della cronologia delle ricerche nel menu Start.
* ** Privacy del Terminale:**
    * Cancellazione totale della cronologia PowerShell (PSReadLine).
* ** File di Sistema e Temporanei:**
    * Svuotamento cartelle `Temp`, `Prefetch` e Cestino.
    * Pulizia della cache DNS.
* ** Supporto App Terze:**
    * Rimozione sessioni e backup di **Notepad++**.
* ** Log di Sistema:**
    * Svuotamento completo di tutti i registri eventi di Windows (Event Viewer).

##  Avvertenze importanti

> [!IMPORTANT]
> * **Privilegi:** Lo script richiede di essere eseguito come **Amministratore**.
> * **Chiusura Processi:** Durante l'esecuzione verranno chiusi forzatamente `explorer.exe`, tutti i browser e Notepad++. Il desktop potrebbe sparire per qualche secondo.
> * **Dati Persi:** Verranno chiuse tutte le schede aperte e dovrai effettuare nuovamente il login sui siti web (i cookie vengono eliminati).

##  Come utilizzare lo script

1.  Apri il Terminale (come amministratore) e digita:
    ```powershell
    Set-ExecutionPolicy Bypass -Scope Process -Force
    .\NomeDelloScript.ps1
    ```

##  Dettaglio elementi eliminati

| Area | Elementi Coinvolti |
| :--- | :--- |
| **Browser** | Chrome, Edge, Brave, Firefox (History, Sessions, Cache, Cookies) |
| **Windows** | Prefetch, Temp, Cestino, DNS Cache, RunMRU |
| **Search** | Recent Searches, Index Rebuild |
| **Logs** | Tutti i Windows Event Logs (System, Security, Application, ecc.) |
| **Terminal** | PowerShell History (ConsoleHost_history.txt) |



##  Licenza
Distribuito sotto Licenza MIT. Scaricando e utilizzando questo script, accetti che l'autore non è responsabile per eventuali perdite di dati non intenzionali.
