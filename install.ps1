[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$NodeRootPassword
)

$ErrorActionPreference = "Stop"
try {
    if (-not $PSScriptRoot) {
        throw "please run this script in powershell click to run"
    }

    # Check if docker is installed
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "Docker is not installed"
    }
    # Check if docker-compose is installed
    if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
        throw "Docker-compose is not installed"
    }

    if (-not $NodeRootPassword) {
        $NodeRootPassword = Read-Host "Please enter the root password for nodes " -MaskInput
    }

    if (-not $NodeRootPassword) {
        throw "NodeRootPassword is not defined"
    }

    $HOST_PATH = "$PSScriptRoot\ansible"
    if (-not (Test-Path $HOST_PATH)) {
        throw "ansible directory does not exist"
    }

    if (-not (Test-Path "$HOST_PATH\Dockerfile_core")) {
        throw "Dockerfile_core does not exist"
    }
    if (-not (Test-Path "$HOST_PATH\Dockerfile_node")) {
        throw "Dockerfile_node does not exist"
    }
    if (-not (Test-Path "$HOST_PATH\docker-compose.yml")) {
        throw "docker-compose.yml does not exist"
    }

    docker build --tag ansible-practice-core:1.0 -f "$HOST_PATH\Dockerfile_core" .
    docker build --tag ansible-practice-node:1.0 -f "$HOST_PATH\Dockerfile_node" .
    
    $env:HOST_PATH = $HOST_PATH
    docker-compose -f "$HOST_PATH\docker-compose.yml" up -d

    docker exec -it ansible-practice-core ssh-keygen -t rsa -b 2048 -f /root/.ssh/id_rsa -q -N ""

    docker exec -it ansible-practice-node1 bash -c "echo 'root:$NodeRootPassword' | chpasswd"
    docker exec -it ansible-practice-node2 bash -c "echo 'root:$NodeRootPassword' | chpasswd"
    docker exec -it ansible-practice-node3 bash -c "echo 'root:$NodeRootPassword' | chpasswd"

    docker exec -it ansible-practice-core sshpass -p "$NodeRootPassword" ssh-copy-id -o StrictHostKeyChecking=no root@node1
    docker exec -it ansible-practice-core sshpass -p "$NodeRootPassword" ssh-copy-id -o StrictHostKeyChecking=no root@node2
    docker exec -it ansible-practice-core sshpass -p "$NodeRootPassword" ssh-copy-id -o StrictHostKeyChecking=no root@node3

    Write-Host "Install Success" -ForegroundColor Green

    Write-Host "Please connect to the ansible-practice-core container and run the following command: `n`ndocker exec -it ansible-practice-core bash`n`n" -ForegroundColor Yellow
}
catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
} finally {
    if (-not $env:HOST_PATH) {
        # $env:HOST_PATH 제거
        Remove-Item Env:\HOST_PATH
    }

    Read-Host "Press any key to continue..."
}