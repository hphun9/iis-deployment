# Parameters
$siteName = "HelloWorldSite"
$appPoolName = "HelloWorldAppPool"
$localUser = "HelloWorldUser"
$localGroup = "HelloWorldGroup"
$passwordPlain = "P@ssword123"
$publishZip = "C:\Development\hphun9\HelloWorld.zip"
$appPath = "C:\inetpub\HelloWorld"
$logPath = "C:\inetpub\logs\HelloWorld"

# Create group if not exists
if (-Not (Get-LocalGroup -Name $localGroup -ErrorAction SilentlyContinue)) {
    New-LocalGroup -Name $localGroup
}

# Create user if not exists and add to group
if (-Not (Get-LocalUser -Name $localUser -ErrorAction SilentlyContinue)) {
    $password = ConvertTo-SecureString $passwordPlain -AsPlainText -Force
    New-LocalUser -Name $localUser -Password $password -PasswordNeverExpires
    Add-LocalGroupMember -Group $localGroup -Member $localUser
}

# Extract the publish zip
if (Test-Path $appPath) {
    Remove-Item -Recurse -Force $appPath
}
New-Item -ItemType Directory -Path $appPath | Out-Null
Expand-Archive -Path $publishZip -DestinationPath $appPath -Force

# Verify web.config is present
if (-Not (Test-Path "$appPath\web.config")) {
    Write-Host "web.config not found in published output! Please re-publish your app with: dotnet publish -c Release"
    exit 1
}

# Create Application Pool
Import-Module WebAdministration
if (-Not (Test-Path "IIS:\AppPools\$appPoolName")) {
    New-WebAppPool -Name $appPoolName
}
Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name processModel.identityType -Value SpecificUser
Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name processModel.userName -Value $localUser
Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name processModel.password -Value $passwordPlain

# Remove site if it already exists
if (Test-Path "IIS:\Sites\$siteName") {
    Remove-Website -Name $siteName
}

# Create Website
New-Website -Name $siteName -Port 80 -PhysicalPath $appPath -ApplicationPool $appPoolName

# Set log file path
Set-ItemProperty "IIS:\Sites\$siteName" -Name logFile.directory -Value $logPath

Write-Host "Deployment completed. Visit http://localhost"
