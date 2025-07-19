# Windows Survival Kit 

# Who are you ?
$isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')
if (! $isAdmin) {
    Write-Host -ForegroundColor Red "ERROR: script must be run as Admin"
    return
}

$ProgressPreference = 'SilentlyContinue'

# Display hidden files & dirs for the current user
Write-Host "Enable `"Show hidden elements`""
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value "1" -PropertyType DWORD -Force | Out-Null

# Display files extensions for the current user
Write-Host "Enable `"Show file extensions`""
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value "0" -PropertyType DWORD -Force | Out-Null

$WD = "C:\Windows\Temp"

# 7zip
Write-Host "Installing 7-Zip... " -NoNewline

if (!(Get-Package | Select-Object -Property Name | Select-String "7-Zip")){
    $7Z_PATH = "$WD\7z.exe"
    curl.exe -sL 'https://www.7-zip.org/a/7z2409-x64.exe' -o "$7Z_PATH"
    Start-Process "$7Z_PATH" /S -Wait
    Remove-Item "$7Z_PATH" -force
    Write-Host -ForegroundColor Green "OK"

}else{
    Write-Host -ForegroundColor Gray "Already installed"
}

# Firefox
Write-Host "Installing Firefox ESR... " -NoNewline

if (!(Get-Package | Select-Object -Property Name | Select-String "Firefox ESR")){
    $FF_PATH = "$WD\ff-esr.exe"
    curl.exe -sL 'https://download.mozilla.org/?product=firefox-esr-latest-ssl&os=win64&lang=fr' -o "$FF_PATH"
    Start-Process "$FF_PATH" /silent -Wait
    Remove-Item "$FF_PATH" -force
    Write-Host -ForegroundColor Green "OK"
}else{
    Write-Host -ForegroundColor Gray "Already installed"
}

# Firefox extensions
$FIREFOX_EXTENSIONS = (
    "istilldontcareaboutcookies",
    "ublock-origin"
)

New-Item -Path "$env:ProgramFiles\Mozilla Firefox\distribution\extensions\" -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

foreach ($EXT in $FIREFOX_EXTENSIONS){
    Write-Host "  Installing $EXT... " -NoNewline

    $EXT_URL = "https://addons.mozilla.org/en-US/firefox/addon/$EXT"
    $EXT_ID = curl.exe -sL "$EXT_URL" | Select-String -Pattern '"guid":"([^"]+)"' | ForEach-Object {$_.Matches[0].Groups[1].Value}

    $EXT_PATH = "$env:ProgramFiles\Mozilla Firefox\distribution\extensions\$EXT_ID.xpi"
    if (Test-Path -Path "$EXT_PATH"){
        Write-Host -ForegroundColor Gray "Already installed"
    }else{
        $EXT_LATEST_XPI = curl.exe -s "$EXT_URL" | Select-String -Pattern 'href="(https://addons\.mozilla\.org/firefox/downloads/file/[^"]+?\.xpi)"' |
        ForEach-Object {$_.Matches[0].Groups[1].Value}

        curl.exe -s "$EXT_LATEST_XPI" -o "$EXT_PATH"
        Write-Host -ForegroundColor Green "OK"
    }
}
