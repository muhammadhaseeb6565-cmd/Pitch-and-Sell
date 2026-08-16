# Flutter SDK Auto-Installer for Windows using curl
# Pitch and Sell Platform - Emulgic Setup Tool

$installDir = "C:\src"
$flutterZip = "$installDir\flutter.zip"
$flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.0-stable.zip"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  PITCH AND SELL - FLUTTER AUTO-SETUP   " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 1. Create Installation Directory
if (!(Test-Path $installDir)) {
    Write-Host "Creating installation directory: $installDir..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $installDir | Out-Null
}

# 2. Download Flutter SDK Zip using curl.exe (highly performant compared to Invoke-WebRequest)
if (Test-Path "$installDir\flutter\bin\flutter.bat") {
    Write-Host "Flutter SDK is already detected in $installDir\flutter." -ForegroundColor Green
} else {
    Write-Host "Downloading Flutter SDK stable branch (Approx. 700MB) using curl..." -ForegroundColor Yellow
    Write-Host "Source: $flutterUrl" -ForegroundColor Gray
    
    # Remove any existing corrupt zip
    if (Test-Path $flutterZip) {
        Remove-Item $flutterZip -Force
    }

    # Execute native curl.exe with progress bar redirected to host
    & curl.exe -L -o $flutterZip $flutterUrl

    if (!(Test-Path $flutterZip) -or (Get-Item $flutterZip).Length -lt 100MB) {
        Write-Host "Download failed or file is incomplete." -ForegroundColor Red
        Exit 1
    }
    Write-Host "Download complete." -ForegroundColor Green

    # 3. Extract SDK
    Write-Host "Extracting Flutter SDK zip to $installDir..." -ForegroundColor Yellow
    try {
        Expand-Archive -Path $flutterZip -DestinationPath $installDir -Force
        Write-Host "Extraction complete." -ForegroundColor Green
        Remove-Item $flutterZip -Force
    } catch {
        Write-Host "Failed to extract zip file: $_" -ForegroundColor Red
        Exit 1
    }
}

# 4. Add to System/User PATH
$binPath = "$installDir\flutter\bin"
Write-Host "Configuring Windows Environment PATH variable..." -ForegroundColor Yellow

$userPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User)

if ($userPath -like "*$binPath*") {
    Write-Host "Flutter binary directory is already in your PATH." -ForegroundColor Green
} else {
    $newUserPath = $userPath + ";" + $binPath
    [Environment]::SetEnvironmentVariable("PATH", $newUserPath, [EnvironmentVariableTarget]::User)
    Write-Host "Successfully added Flutter to User PATH: $binPath" -ForegroundColor Green
    Write-Host "NOTE: Please restart your terminal/IDE for PATH changes to take effect." -ForegroundColor Cyan
}

# 5. Verify Installation
Write-Host "Running flutter doctor..." -ForegroundColor Yellow
Start-Process -FilePath "$binPath\flutter.bat" -ArgumentList "doctor" -NoNewWindow -Wait

Write-Host "=========================================" -ForegroundColor Green
Write-Host "Setup Completed! Re-open terminal and run: flutter --version" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
