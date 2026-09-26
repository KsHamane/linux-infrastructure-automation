#04-distribute-jump-key.ps1

# ============================================================
# 04-distribute-jump-key.ps1
#
# Current VM state:
#   nfs-server : SSH port 6546
#   jump-host  : SSH port 6546
#   web-server : SSH port 22 / not hardened yet
#
# This script:
#   1. Gets Jump Host public key
#   2. Copies it to nfs-server using SSH port 6546
#   3. Adds it to nfs-server authorized_keys
#   4. Copies it to web-server using Multipass
#   5. Adds it to web-server authorized_keys
# ============================================================

$UserPrivateKey = Join-Path $HOME ".ssh\id_ed25519"
$TempJumpKey = Join-Path $env:TEMP "jump-host-id_ed25519.pub"

# ============================================================
# Check Windows SSH key
# ============================================================

if (-not (Test-Path $UserPrivateKey)) {
    Write-Host "ERROR: Windows SSH private key not found:"
    Write-Host $UserPrivateKey
    exit 1
}

# ============================================================
# Get VM IPs
# ============================================================

function Get-VMIP {
    param (
        [string]$VMName
    )

    $Info = multipass info $VMName --format json | ConvertFrom-Json

    return $Info.info.PSObject.Properties[$VMName].Value.ipv4 |
        Where-Object {
            $_ -and $_ -notmatch "^127\."
        } |
        Select-Object -First 1
}

$NFSIP = Get-VMIP "nfs-server"
$JumpIP = Get-VMIP "jump-host"
$WebIP = Get-VMIP "web-server"

if (-not $NFSIP -or -not $JumpIP -or -not $WebIP) {
    Write-Host "ERROR: Could not get one or more VM IPs."
    exit 1
}

Write-Host "nfs-server : $NFSIP"
Write-Host "jump-host  : $JumpIP"
Write-Host "web-server : $WebIP"

# ============================================================
# Get Jump Host public key
# SSH to Jump Host through port 6546
# ============================================================

Write-Host ""
Write-Host "Getting Jump Host public key..."

ssh `
    -i $UserPrivateKey `
    -p 6546 `
    -o StrictHostKeyChecking=no `
    "ubuntu@$JumpIP" `
    "cat /home/ubuntu/.ssh/id_ed25519.pub" |
    Set-Content -Path $TempJumpKey -NoNewline

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Could not retrieve Jump Host public key."
    exit 1
}

if (-not (Test-Path $TempJumpKey)) {
    Write-Host "ERROR: Temporary key file was not created."
    exit 1
}

Write-Host "Jump Host public key retrieved."

# ============================================================
# NFS SERVER
# SSH port = 6546
# ============================================================

Write-Host ""
Write-Host "Installing Jump Host key on nfs-server..."

scp `
    -i $UserPrivateKey `
    -P 6546 `
    -o StrictHostKeyChecking=no `
    $TempJumpKey `
    "ubuntu@${NFSIP}:/home/ubuntu/jump_key.pub"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Could not copy key to nfs-server."
    exit 1
}

ssh `
    -i $UserPrivateKey `
    -p 6546 `
    -o StrictHostKeyChecking=no `
    "ubuntu@$NFSIP" `
    "mkdir -p /home/ubuntu/.ssh; touch /home/ubuntu/.ssh/authorized_keys; chmod 700 /home/ubuntu/.ssh; chmod 600 /home/ubuntu/.ssh/authorized_keys; if ! grep -qxF '`$(cat /home/ubuntu/jump_key.pub)' /home/ubuntu/.ssh/authorized_keys; then cat /home/ubuntu/jump_key.pub >> /home/ubuntu/.ssh/authorized_keys; fi; rm -f /home/ubuntu/jump_key.pub"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Could not install Jump Host key on nfs-server."
    exit 1
}

Write-Host "nfs-server configured successfully."

# ============================================================
# WEB SERVER
# Still using Multipass / default SSH port 22
# ============================================================

Write-Host ""
Write-Host "Installing Jump Host key on web-server..."

multipass transfer `
    $TempJumpKey `
    "web-server:/home/ubuntu/jump_key.pub"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Could not copy key to web-server."
    exit 1
}

multipass exec web-server -- `
    bash -c @'
mkdir -p /home/ubuntu/.ssh
touch /home/ubuntu/.ssh/authorized_keys

chmod 700 /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/authorized_keys

if ! grep -qxF "$(cat /home/ubuntu/jump_key.pub)" /home/ubuntu/.ssh/authorized_keys; then
    cat /home/ubuntu/jump_key.pub >> /home/ubuntu/.ssh/authorized_keys
fi

rm -f /home/ubuntu/jump_key.pub
'@

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Could not install Jump Host key on web-server."
    exit 1
}

Write-Host "web-server configured successfully."

# ============================================================
# Cleanup
# ============================================================

Remove-Item $TempJumpKey -Force -ErrorAction SilentlyContinue

# ============================================================
# Done
# ============================================================

Write-Host ""
Write-Host "=============================================="
Write-Host "JUMP KEY DISTRIBUTION COMPLETE"
Write-Host "=============================================="
Write-Host ""
Write-Host "Jump Host can now SSH to:"
Write-Host "  nfs-server : 6546"
Write-Host "  web-server : 22"
```
