# Competition Setup Script
# Interactive script to set up AI coding competitions

# ============================================
# STEP 1: Repository Selection
# ============================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "STEP 1: Repository Selection" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Get saved repos from environment variable (stored as semicolon-separated list)
$envRepos = [Environment]::GetEnvironmentVariable("AITOOLBOX_REPOS", "User")
$savedRepos = @()
if ($envRepos) {
    $savedRepos = $envRepos -split ";"
}

# Display options
$optionIndex = 1
$repoOptions = @{}

if ($savedRepos.Count -gt 0) {
    Write-Host "`nSaved repositories:" -ForegroundColor Yellow
    foreach ($repo in $savedRepos) {
        if ($repo.Trim()) {
            Write-Host "  [$optionIndex] $repo" -ForegroundColor White
            $repoOptions[$optionIndex] = $repo
            $optionIndex++
        }
    }
}

Write-Host "  [N] Enter a new repository URL" -ForegroundColor Green
Write-Host ""

$repoUrl = $null
while (-not $repoUrl) {
    $selection = Read-Host "Select an option"
    
    if ($selection -eq "N" -or $selection -eq "n") {
        $newRepo = Read-Host "Enter the repository URL"
        if ($newRepo.Trim()) {
            $repoUrl = $newRepo.Trim()
            
            # Save to environment variable
            if ($savedRepos -notcontains $repoUrl) {
                $savedRepos += $repoUrl
                $newEnvValue = ($savedRepos | Where-Object { $_.Trim() }) -join ";"
                [Environment]::SetEnvironmentVariable("AITOOLBOX_REPOS", $newEnvValue, "User")
                Write-Host "  Repository saved for future use!" -ForegroundColor Green
            }
        } else {
            Write-Host "  Invalid URL. Please try again." -ForegroundColor Red
        }
    } elseif ($repoOptions.ContainsKey([int]$selection)) {
        $repoUrl = $repoOptions[[int]$selection]
    } else {
        Write-Host "  Invalid selection. Please try again." -ForegroundColor Red
    }
}

Write-Host "  Selected: $repoUrl" -ForegroundColor Green

# ============================================
# STEP 2: Competition Name
# ============================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "STEP 2: Competition Name" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Enter a name for this competition (max 20 characters)" -ForegroundColor Yellow
Write-Host "This will be used as the folder name with a timestamp." -ForegroundColor Gray

$competitionName = $null
while (-not $competitionName) {
    $input = Read-Host "Competition name"
    if (-not $input.Trim()) {
        Write-Host "  Please enter a valid name." -ForegroundColor Red
    } elseif ($input.Trim().Length -gt 20) {
        Write-Host "  Name too long ($($input.Trim().Length) chars). Maximum is 20 characters." -ForegroundColor Red
    } else {
        # Sanitize the name - remove invalid path characters
        $competitionName = $input.Trim() -replace '[<>:"/\\|?*]', '_'
    }
}

# ============================================
# STEP 3: Number of Competitors
# ============================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "STEP 3: Number of Competitors" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "How many competitor repos should be cloned?" -ForegroundColor Yellow

$N = 0
while ($N -lt 1) {
    $input = Read-Host "Number of competitors"
    if ($input -match '^\d+$' -and [int]$input -gt 0) {
        $N = [int]$input
    } else {
        Write-Host "  Please enter a valid number (1 or more)." -ForegroundColor Red
    }
}

# ============================================
# Setup Confirmation
# ============================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Configuration Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Repository:   $repoUrl" -ForegroundColor White
Write-Host "  Competition:  $competitionName" -ForegroundColor White
Write-Host "  Competitors:  $N" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Proceed with setup? (Y/n)"
if ($confirm -eq "n" -or $confirm -eq "N") {
    Write-Host "Setup cancelled." -ForegroundColor Yellow
    exit
}

# ============================================
# Execute Setup
# ============================================

# Create competition folder with name and datetime (MMddyyyyHHmm format)
$dateTime = Get-Date -Format "MMddyyyyHHmm"
$competitionFolder = "${competitionName}_$dateTime"

Write-Host "`nCreating competition folder: $competitionFolder" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $competitionFolder -Force | Out-Null

# Change to competition folder
Push-Location $competitionFolder

try {
    for ($i = 1; $i -le $N; $i++) {
        $contestantFolder = "Contestant$i"
        $branchName = "Contestant$i"
        
        Write-Host "`nSetting up $contestantFolder..." -ForegroundColor Yellow
        
        # Clone directly into contestant folder (not a subfolder)
        Write-Host "  Cloning repository..." -ForegroundColor Gray
        $cloneOutput = git clone -c core.longpaths=true $repoUrl $contestantFolder 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            # Check for long path error
            $longPathError = $cloneOutput | Where-Object { $_ -match "Filename too long" }
            if ($longPathError) {
                Write-Host "  ERROR: Path too long for Windows!" -ForegroundColor Red
                Write-Host "  Windows has a 260 character path limit." -ForegroundColor Red
                
                # Extract the problematic file path from the error
                $errorLine = $cloneOutput | Where-Object { $_ -match "unable to create file" } | Select-Object -First 1
                if ($errorLine -match "unable to create file (.+):") {
                    $problemFile = $matches[1]
                    $fullPath = Join-Path (Get-Location) "$contestantFolder\$problemFile"
                    Write-Host "  Problem file: $problemFile" -ForegroundColor Yellow
                    Write-Host "  Full path length: $($fullPath.Length) characters" -ForegroundColor Yellow
                }
                
                Write-Host "" -ForegroundColor White
                Write-Host "  To fix this, enable long paths in Windows (requires admin):" -ForegroundColor Cyan
                Write-Host "  Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1" -ForegroundColor Gray
                Write-Host "  Then restart your terminal and try again." -ForegroundColor Cyan
            } else {
                Write-Host "  ERROR: Failed to clone repository for $contestantFolder" -ForegroundColor Red
                Write-Host "  $cloneOutput" -ForegroundColor Gray
            }
            continue
        }
        
        # Change to contestant folder and create branch
        Push-Location $contestantFolder
        
        Write-Host "  Creating branch: $branchName" -ForegroundColor Gray
        git checkout -b $branchName
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Successfully created branch: $branchName" -ForegroundColor Green
        } else {
            Write-Host "  ERROR: Failed to create branch for $contestantFolder" -ForegroundColor Red
        }
        
        Pop-Location
    }
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Competition setup complete!" -ForegroundColor Green
    Write-Host "Folder: $competitionFolder" -ForegroundColor Cyan
    Write-Host "Competition: $competitionName" -ForegroundColor Cyan
    Write-Host "Competitors: $N" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}
finally {
    Pop-Location
}
