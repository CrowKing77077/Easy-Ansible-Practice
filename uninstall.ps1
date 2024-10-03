
$ErrorActionPreference = "Stop"

function Read-ConfirmPrompt {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $true)]
        [string[]]$AnwerSets
    )

    $answer = Read-Host -Prompt "$Message ($($AnwerSets -join "/"))"
    while ($true) {
        # Check if the answer is in the answer set
        # case insensitive
        if ($AnwerSets -contains $answer) {
            return $answer
        } else {
            Write-Host "Invalid input." -ForegroundColor Red
            $answer = Read-Host -Prompt "$Message ($($AnwerSets -join " / "))"
        }
    }
}

try {
    $prompt = Read-ConfirmPrompt -Message "Are you sure you want to uninstall?" -AnwerSets "Y", "N"
    if ($prompt -ne "Y") {
        Write-Host "Uninstall Cancelled" -ForegroundColor Yellow
        exit
    }

    if (-not $PSScriptRoot) {
        throw "please run this script in powershell click to run"
    }

    $HOST_PATH = "$PSScriptRoot\ansible"
    $env:HOST_PATH = $HOST_PATH
    
    docker-compose -f "$HOST_PATH\docker-compose.yml" down
    
    Remove-Item Env:\HOST_PATH
    
    Write-Host "Uninstall Success" -ForegroundColor Green

    $prompt = Read-ConfirmPrompt -Message "Do you want to remove the old images?" -AnwerSets "Y", "N"
    if ($prompt -eq "Y") {
        docker rmi ansible-practice-core:1.0
        docker rmi ansible-practice-node:1.0
    }
}
catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
} finally {
    Read-Host "Press any key to continue..."
}