$redis_version = "3.0.504"
$download_url = "https://github.com/MSOpenTech/redis/releases/download/win-$redis_version/Redis-x64-$redis_version.zip"
$downloadPath = "C:\tmp"
$installationPath = "C:\tools"

# start common functions
function Test-Administrator {
  $user = [Security.Principal.WindowsIdentity]::GetCurrent();
  (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Stop-LocalService {
  param([string]$serviceName)

  Write-Host "Stopping $serviceName"

  if (Test-Administrator) {
    Get-Service |
    where { $_.status -eq "Running" } |
    where { $_.name -eq $serviceName } |
    Stop-Service
  }
  else {
    Write-Host "This action requires elevated permissions." -ForegroundColor "Red"
  }
}

function Start-LocalService {
  param([string]$serviceName)

  Write-Host "Starting $serviceName"

  if (Test-Administrator) {
    Get-Service |
    where { $_.status -eq "Stopped" } |
    where { $_.name -eq $serviceName } |
    Start-Service
  }
  else {
    Write-Host "This action requires elevated permissions." -ForegroundColor "Red"
  }
}
# end common functions


function Get-Redis {

  Push-Location $downloadPath

  if (!(Test-Path -Path "Redis_$redis_version") -And !(Test-Path -Path "redis.zip")) {
    Write-Host "Redis not found, downloading from: $download_url to: redis.zip" -ForegroundColor "Yellow"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest $download_url -OutFile "redis.zip"
  }

  If ((Test-Path -Path "redis.zip") -And !(Test-Path -Path "Redis_$redis_version")) {
    Write-Host "Decompressing redis.zip to $installationPath\Redis_$redis_version" -ForegroundColor "Yellow"
    Add-Type -assembly "system.io.compression.filesystem"
    [io.compression.zipfile]::ExtractToDirectory("$downloadPath\redis.zip", "$installationPath\Redis_$redis_version")
    
    Remove-Item redis.zip
  }

  Pop-Location
}

function Install-Redis {

  if (Test-Administrator) {

    Push-Location $installationPath
    if (!(Test-Path -Path "Redis_$redis_version")) {
      Get-Redis
    }

    if ( !(Test-Path -Path "$installationPath\Redis_$redis_version\Logs")) {
      New-Item -Path "$installationPath\Redis_$redis_version\Logs" -ItemType Directory > $null
    }

    # Copy-Item .\Redis\*.local.conf .\Redis_$redis_version\ -Force -PassThru `
    # | Set-ItemProperty -Name IsReadOnly -Value $false

    if (Test-Path -Path "Redis_$redis_version") {
      Write-Host "Installing Redis"
      . Redis_$redis_version\redis-server.exe --service-install --service-name "Redis" "$installationPath\Redis_$redis_version\redis.windows-service.conf" --port 6379
    }
    Pop-Location
  }
  else {
    Write-Host "This action requires elevated permissions." -ForegroundColor "Red"
  }
}

function Uninstall-Redis {

  if (Test-Administrator) {
    Push-Location $installationPath
    Stop-Redis
    if (Test-Path -Path "Redis_$redis_version") {
      . Redis_$redis_version\redis-server.exe --service-uninstall --service-name "Redis"
      Remove-Item "Redis_$redis_version" -Force -Recurse
    }
     
    Pop-Location  
  }
  else {
    Write-Host "This action requires elevated permissions." -ForegroundColor "Red"
  }
}

function Start-Redis {
  Start-LocalService -serviceName  "Redis"
}

function Stop-Redis {
  Stop-LocalService -serviceName  "Redis"
}

function Invoke-RedisCli {
  Push-Location $installationPath
  if ((Test-Path -Path "Redis_$redis_version")) {
    . Redis_$redis_version/redis-cli.exe -p 26379
  }
  Pop-Location
}

function Ping-Redis {
  Push-Location $installationPath
  if ((Test-Path -Path "Redis_$redis_version")) {
    . Redis_$redis_version/redis-cli.exe -p 26379 ping
  }
  Pop-Location
}

function Invoke-RedisFailover {
  Push-Location $installationPath
  if ((Test-Path -Path "Redis_$redis_version")) {
    . Redis_$redis_version/redis-cli.exe -p 26379 sentinel failover RedisESD
  }
  Pop-Location
}

Uninstall-Redis
Install-Redis
Start-Redis