param (
    [switch]
    $install,
    [switch]
    $help,
    [switch]
    $checkInt,
    [switch]
    $uninstall,
    [switch]
    $force
)
# =====> VARS <===========================
$desktop = "$HOME\desktop"
$programFolder = "$HOME\ProxyToggel"
$profileConf = "$programFolder\proxyToggel.json"
$filePath = "$programFolder\poxyToggel.ps1"
$onIconPath = "$programFolder\on.ico"
$offIconPath = "$programFolder\off.ico"
$shortCutPath = "$HOME\desktop\proxy.lnk"
$currentFileName = $MyInvocation.MyCommand.Name
function Message {
    param(
        [string]
        $text,
        [switch]
        $isWaring
    )
    $getDate = (Get-Date).ToString("d.M.y hh:mm:ss");
    $date ="[" + $getDate + "] => "
    $text = $date + $text
    if($isWarning){
        Write-Warning $text
    }else{
        Write-Host $text
    }
}
function Install {
    Message "Inizio di installazione del programma"
    $currentScriptPathFolder = Get-Location #Cartella dove ci sono tutti i programmi da installare.
    $currentScriptPath = "$currentScriptPathFolder\$currentFileName" #Path del file script da spostare
    $proxyString = Read-Host "Inserire proxy"
    $proxyPort = Read-Host "Inserire prota proxy"
    $data = @{proxyString=$proxyString;proxyPort=$proxyPort;proxyIsActivated=$false}
    $data = $data | ConvertTo-Json -Compress
    if (-not(Test-Path $programFolder)){
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
    Remove-Item "$HOME\desktop\proxy.lnk"
    if(-not (Test-Path "$HOME\desktop\proxy.lnk")){
        Message "Creazione shortcut..."
        $WshShell = New-Object -ComObject WScript.shell
        $Shortcut = $WshShell.createShortcut("$HOME\desktop\proxy.lnk")
        $Shortcut.targetPath = $filePath
        $Shortcut.IconLocation = $offIconPath
        $Shortcut.save()
        Message "Shortcut creata"
    }
}
function CheckProgramIntegrity {
    if(-not (Test-Path $programFolder)){
        Message "Il programma non e`` installato. Eseguire il comando con l`'opzione -install per installarlo." -isWarning
        exit
    }
    if(-not (Test-Path $profileConf)){
        Message "File di configurazione mancante. Il file viene ricreato automaticamente al prossimo avvio" -isWarning
        return $false
    }
    if(-not (Test-Path $filePath)){
        Message "File di esecuzione mancante. Si necessita la reinstallazione del programma"
        exit
    }
    if(-not (Test-Path $onIconPath)){
        Message "Icona mancante. Si necessita la reinstallazione del programma"
        exit
    }
    if(-not (Test-Path $offIconPath)){
        Message "Icona mancante. Si necessita la reinstallazione del programma"
        exit
    }
    return $true
}
if ($install) {
    if($force){
        if(Test-Path $programFolder){
            Remove-Item $programFolder
        }
        if(Test-Path $profileConf){
            Remove-Item $profileConf
        }
        if(Test-Path $filePath){
            Remove-Item $filePath
        }
        if(Test-Path $onIconPath){
            Remove-Item $onIconPath
        }
        if(Test-Path $offIconPath){
            Remove-Item $offIconPath
        }
    }
    Install
}elseif($help){
    Message "https://github.com/ilBiondojs/ProxyToggel";
}else{
    if(CheckProgramIntegrity){
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
            $shortcut.TargetPath = $filePath
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
    }else{
        Message "File mancanti" -isWarning
    }
}
Read-host "Per continuare schiacciare un tasto..."