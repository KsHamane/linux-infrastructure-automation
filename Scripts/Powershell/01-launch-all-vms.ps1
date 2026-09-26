#01-launch-all-vms.ps1

# ============================================================
# 01-create-vms.ps1
# Creates 3 Multipass VMs, collects their IPs,
# puts ~/all-ips on every VM, and copies the user's
# Windows SSH public key to jump-host as ~/user_key.pub
# ============================================================

$VMs = @(
    "nfs-server",
    "jump-host",
    "web-server"
)

$Memory = "512M"
$UserKey = Join-Path $HOME ".ssh\id_ed25519.pub"

# ============================================================
# Check user's SSH public key
# ============================================================

if (-not (Test-Path $UserKey)) {
    Write-Host "ERROR: $UserKey was not found."
    Write-Host "Create your SSH key first with:"
    Write-Host "ssh-keygen -t ed25519"
    exit 1
}

# ============================================================
# Create / start VMs
# ============================================================

foreach ($VM in $VMs) {

    $exists = multipass list --format csv |
        Select-String "^$VM,"

    if ($exists) {

        Write-Host "$VM already exists."

        $state = (multipass list --format csv |
            Select-String "^$VM," |
            ForEach-Object {
                $_.ToString().Split(",")[1]
            })

        if ($state -ne "RUNNING") {
            Write-Host "Starting $VM..."
            multipass start $VM
        }

    }
    else {

        Write-Host "Creating $VM..."
        multipass launch `
            --name $VM `
            --memory $Memory
    }
}

# ============================================================
# Wait for all VMs to be running
# ============================================================

Write-Host ""
Write-Host "Waiting for all VMs to be running..."

foreach ($VM in $VMs) {

    do {
        Start-Sleep -Seconds 2

        $state = (multipass list --format csv |
            Select-String "^$VM," |
            ForEach-Object {
                $_.ToString().Split(",")[1]
            })

    } while ($state -ne "RUNNING")

    Write-Host "$VM is RUNNING."
}

# ============================================================
# Get IP address of every VM
# ============================================================

$VMIPs = @{}

foreach ($VM in $VMs) {

    $Info = multipass info $VM --format json | ConvertFrom-Json

    $VMInfo = $Info.info.PSObject.Properties[$VM].Value

    $IP = $VMInfo.ipv4 |
        Where-Object {
            $_ -and $_ -notmatch "^127\."
        } |
        Select-Object -First 1

    if (-not $IP) {
        Write-Host "ERROR: Could not find IP address for $VM."
        exit 1
    }

    $VMIPs[$VM] = $IP

    Write-Host "$VM -> $IP"
}

# ============================================================
# Create all-ips file
# Format:
# <IP> <VM-NAME>
# ============================================================

$AllIPsContent = foreach ($VM in $VMs) {
    "$($VMIPs[$VM]) $VM"
}

$AllIPsContent = $AllIPsContent -join "`n"

Write-Host ""
Write-Host "all-ips:"
Write-Host $AllIPsContent

# Create temporary file on Windows
$TempAllIPs = Join-Path $env:TEMP "all-ips"

Set-Content `
    -Path $TempAllIPs `
    -Value $AllIPsContent `
    -NoNewline

# ============================================================
# Copy all-ips to every VM
# ============================================================

foreach ($VM in $VMs) {

    Write-Host ""
    Write-Host "Copying all-ips to $VM..."

    multipass transfer `
        $TempAllIPs `
        "${VM}:/home/ubuntu/all-ips"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to copy all-ips to $VM."
        exit 1
    }

    # Your existing Bash scripts use all-ips.txt
    multipass exec $VM -- `
        bash -c "ln -sf /home/ubuntu/all-ips /home/ubuntu/all-ips.txt"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to create all-ips.txt on $VM."
        exit 1
    }
}

# ============================================================
# Copy user's Windows SSH public key to all servers
# ============================================================

Write-Host ""
Write-Host "Copying Windows SSH public key to jump-host..."

multipass transfer `
    $UserKey `
    "jump-host:/home/ubuntu/user_key.pub"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to copy user_key.pub to jump-host."
    exit 1
}

multipass exec jump-host -- `
    chmod 644 /home/ubuntu/user_key.pub


Write-Host ""
Write-Host "Copying Windows SSH public key to nfs-server..."

multipass transfer `
    $UserKey `
    "nfs-server:/home/ubuntu/user_key.pub"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to copy user_key.pub to nfs-server."
    exit 1
}

multipass exec nfs-server -- `
    chmod 644 /home/ubuntu/user_key.pub



Write-Host ""
Write-Host "Copying Windows SSH public key to web-server..."

multipass transfer `
    $UserKey `
    "web-server:/home/ubuntu/user_key.pub"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to copy user_key.pub to web-server."
    exit 1
}

multipass exec web-server -- `
    chmod 644 /home/ubuntu/user_key.pub



# ============================================================
# Clean temporary file
# ============================================================

Remove-Item $TempAllIPs -Force -ErrorAction SilentlyContinue

# ============================================================
# Done
# ============================================================

Write-Host ""
Write-Host "=============================================="
Write-Host "VM SETUP COMPLETE"
Write-Host "=============================================="

foreach ($VM in $VMs) {
    Write-Host "$VM : $($VMIPs[$VM])"
}

Write-Host ""
Write-Host "all-ips installed on all VMs."
Write-Host "user_key.pub installed on all servers."
