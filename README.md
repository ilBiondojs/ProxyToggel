Timo Coupek I2BC
---
## Utilizzo
### Insallazione
> Per eseguire l'istallazione è necessario eseguire il comando `main.ps1 -install`
Il comando è semi inteliggente nel senso che, se si vuole ri installare l'applicativo in caso di problemi non renistallerà tutto ma solo le cosa necessarie o corotte.
Ci sono dei parametri aggiuntivi come:
 - -help che stampa il link del repo
 - -checkInt che ferifica l'integrita dello script
 - -uninstall per disinstallare il tutto
 - -force utile solo all'installazione per reinstallare tutto in modo forzato
## Funzionamento del codice
---
**<h1>Dichiarazioni delle variabili utili</h1>**

### Spiegazione:
> Come prima cosa dichiaro tutte le variabili di cui necessito più volte nel mio script
- _**$desktop**_ rappresenta il percorso file per arrivare al desktop
- _**$programFolder**_ rappresenta la cartella di lavoro dello script **Quando gia installato**
- _**$profileConf**_ rappresenta il file che contiene i dati necessari per l'utilizzo:
    - Stringa che contiene il server proxy
    - Stringa che contiene la porta della proxy
    - Boolean che contiene lo stato della proxy
- _**$onIconPath**_ e _$offIconPath_ sono i due percorsi file che portano alle icone della shortcut sul desktop
- _**$shortCutPath**_ il percorso file della shortcut
- _**$currentFileName**_ il nome corrente dello script in esecuzione
### Code:
```powershell
$desktop = "$HOME\desktop"
$programFolder = "$HOME\ProxyToggel"
$profileConf = "$programFolder\proxyToggel.json"
$filePath = "$programFolder\poxyToggel.ps1"
$onIconPath = "$programFolder\on.ico"
$offIconPath = "$programFolder\off.ico"
$shortCutPath = "$HOME\desktop\proxy.lnk"
$currentFileName = $MyInvocation.MyCommand.Name
```
---
**<h1>Main dello script</h1>**
### Spiegazione
> Main dell script. Nel main viene esguita prima un controllo della variabile _**$install**_ che permette di verificare se l'utente ha richiesto l'installazione del prodotto, e poi, nel caso l'utente non l'avesse richiesta, viene eseguita la funzione per la verifica dell'integrità del prodotto. Se la funzione restituisce un esito positivo si passa al vero codice dello script. Lo script sottostande esegue le seguenti cose:
1.  Legge il file JSON di configureazione, ne estrae la stringa proxy e lo stato
2.  In base allo stato valuta se attivare o disattivare la proxy
3.  Manda a terminale un messaggio che indica la nuova posizione della proxy
4.  Attiva ed inseriesce la stringa o disattiva la proxy
5.  Aggiorna il cambiamento nell'oggetto __*$data*__
6.  Aggiorna l'icona della shortcut sul desktop
7.  Aggiorna il file JSON
### Codice:
```powershell
$data = Get-Content $profileConf
$data = $data | ConvertFrom-Json
$regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
$proxyString = $data.proxyString
$proxy = $proxyString + ":" + $data.proxyPort
if([boolean]$data.proxyIsActivated){
    Message "Proxy disattivata"
    $data.proxyIsActivated = $false
    Set-ItemProperty -path $regKey ProxyEnable -value 0
    Set-ItemProperty -path $regKey ProxyServer -value ""
    $WScriptShell = New-Object -ComObject WScript.Shell
    $shortcut = $WScriptShell.CreateShortcut($shortCutPath)
    $shortcut.TargetPath = $TargetFile
    $shortcut.IconLocation = "$offIconPath"
    $shortcut.Save()
}else{
    $text = "Proxy " + $data.proxyString +  " con la porta " + $data.proxyPort + " e`` stata attivata"
    Message $text
    $data.proxyIsActivated = $true
    Set-ItemProperty -path $regKey ProxyEnable -value 1
    Set-ItemProperty -path $regKey ProxyServer -value "$proxy"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $shortcut = $WScriptShell.CreateShortcut($shortCutPath)
    $shortcut.TargetPath = $filePath
    $shortcut.IconLocation = "$onIconPath"
    $shortcut.Save()
}
$data = $data | ConvertTo-Json
$data | Out-File -FilePath $profileConf
```
---
### Spiegazione
**<h1>Funzione di installazione</h1>**
> Quesa funzione è costruita in modo tale che anche se manca 1 solo file essa può essere reinstallata. In pratica permette di ignorare i file già esistenti e crea quelli necessari
### Codice

```powershell
Message "Inizio di installazione del programma"
$currentScriptPathFolder = Get-Location #Cartella dove ci sono tutti i programmi da installare.
$currentScriptPath = "$currentScriptPathFolder\$currentFileName" #Path del file script da spostare
$proxyString = Read-Host "Inserire proxy"
$proxyPort = Read-Host "Inserire prota proxy"
$data = @{proxyString=$proxyString;proxyPort=$proxyPort;proxyIsActivated=$false}
$data = $data | ConvertTo-Json -Compress
if (-not( Test-Path $programFolder)){
    Message "Creazione cartela programma..."
    New-Item -Type "Directory" -Path $programFolder | out-null
    Message "Cartela programma creata"
}
if (-not(Test-Path $profileConf)){
    Message "Creazione file di configurazione..."
    New-Item -Path $profileConf | out-null
    Message "File di configurazione creato"
}
if (-not(Test-Path $onIconPath)){
    if(Test-path "$currentScriptPathFolder\on.ico"){
        Message "Spostamento dell'icona on.ico..."
        Move-Item "$currentScriptPathFolder\on.ico" "$programFolder\on.ico" | out-null
        Message "Icona on.ico spostata"
    }else{
        Message "Icona on.ico mancante" -isWaring
    }
}
if (-not(Test-Path $offIconPath)){
    if(Test-path "$currentScriptPathFolder\off.ico"){
        Message "Spostamento dell'icona off.ico..."
        Move-Item "$currentScriptPathFolder\off.ico" "$programFolder\off.ico" | out-null
        Message "Icona off.ico spostata"
    }else{
        Message "Icona off.ico mancante" -isWaring
    }
}
if (-not(Test-Path $filePath)){
    Message "Spostamento dello script..."
    Move-Item $currentScriptPath $filePath | out-null
    Message "Script spostato"
}
$data | Out-File -FilePath $profileConf
rm "$HOME\desktop\proxy.lnk"
if(-not (Test-Path "$HOME\desktop\proxy.lnk")){
    Message "Creazione shortcut..."
    $WshShell = New-Object -ComObject WScript.shell
    $Shortcut = $WshShell.createShortcut("$HOME\desktop\proxy.lnk")
    $Shortcut.targetPath = $filePath
    $Shortcut.IconLocation = $offIconPath
    $Shortcut.save()
    Message "Shortcut creata"
}
```
`Message` è un metodo che permette di stampare a terminale in modo formattato una specie di log.