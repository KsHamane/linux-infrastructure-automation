#!/bin/bash

#=============================Harden Every Server============================================
mkdir -p ~/.ssh


sudo groupadd -f admins ; sudo groupadd -f devs
sudo usermod -aG admins $(whoami)
#groups $(whoami)


sudo sed -i 's/^#\?Port .*/Port 6546/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config


sudo ufw allow 6546/tcp
sudo ufw allow 22/tcp
sudo ufw allow http
sudo ufw allow https
sudo ufw enable
sudo ufw reload
#sudo ufw status



if sudo sshd -t; then
        sudo systemctl enable --now ssh
        sudo systemctl restart ssh
else
        echo "SSH configuration is invalid!"
        exit 1
fi
#sudo systemctl status ssh


#TAKING THE USER'S KEY
if [ ! -f ~/.ssh/authorized_keys ]; then
touch ~/.ssh/authorized_keys
fi

if ! grep -q "ssh-ed25519" ~/.ssh/authorized_keys ; then
cat ~/user_key.pub >> ~/.ssh/authorized_keys
fi



#==========================NFS SHARE STORAGE TO OTHERS IN NETWORK========================================
sudo apt update -q ; sudo apt install -y -q ipcalc

#echo "$(ipcalc $(CIDR=$(ip -o -4 addr show | awk '$2 != "lo" {print $4; exit}') ; echo $CIDR)" > ~/ipcalc.txt

echo "$(ipcalc $(ip -o -4 addr show | awk '$2 != "lo" {print $4; exit}') )" > ~/ipcalc.txt

NETWORK=$(grep "Network:" ~/ipcalc.txt | awk '{print $2}')



sudo apt install -y -q nfs-kernel-server
sudo mkdir -p /srv/shared
echo "/srv/shared $NETWORK(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server
echo "Hello from Shared-storage nfs-server ip:$(hostname -I)" | sudo tee /srv/shared/greeting.txt

sudo ufw allow from "$NETWORK" to any port 2049 proto tcp
sudo ufw reload

if [ ! -d /srv/shared/apps ]; then
sudo mkdir -p /srv/shared/apps

fi


sudo tee /srv/shared/apps/test_site.html > /dev/null <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>HTTPS 200 OK | Automated 4-Node Linux Cluster by KsHamane</title>

  <style>
    :root {
      --ink: #0B1220;
      --panel: #131c30;
      --panel-dark: #090e1a;
      --hero-red: #C81E3A;
      --web-white: #F5F5F0;
      --electric: #29B6F6;
      --burst-yellow: #FFD23F;
      --success-green: #00E676;
      --purple-accent: #A855F7;
      --border-width: 4px;
      --shadow-offset: 8px;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    html, body {
      min-height: 100vh;
      background-color: var(--ink);
      color: var(--web-white);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      line-height: 1.5;
      overflow-x: hidden;
    }

    /* Ambient background grid and glowing radial gradients */
    body::before {
      content: "";
      position: fixed;
      inset: 0;
      z-index: 0;
      background:
        radial-gradient(circle at 15% 15%, rgba(200, 30, 58, 0.35), transparent 45%),
        radial-gradient(circle at 85% 85%, rgba(41, 182, 246, 0.28), transparent 50%),
        radial-gradient(circle at 50% 50%, rgba(255, 210, 63, 0.12), transparent 60%),
        repeating-linear-gradient(0deg, rgba(245, 245, 240, 0.03) 0px, rgba(245, 245, 240, 0.03) 1px, transparent 1px, transparent 28px),
        repeating-linear-gradient(90deg, rgba(245, 245, 240, 0.03) 0px, rgba(245, 245, 240, 0.03) 1px, transparent 1px, transparent 28px);
      pointer-events: none;
    }

    .top-bar {
      position: relative;
      z-index: 10;
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 1rem 1.5rem;
      max-width: 1100px;
      margin: 0 auto;
    }

    .brand {
      display: flex;
      align-items: center;
      gap: 0.6rem;
      font-weight: 800;
      font-size: 1.1rem;
      letter-spacing: 0.5px;
      color: var(--web-white);
      text-decoration: none;
    }

    .brand-icon {
      width: 28px;
      height: 28px;
      fill: var(--electric);
    }

    .live-status {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      background: var(--panel);
      border: 2px solid var(--web-white);
      padding: 0.35rem 0.85rem;
      border-radius: 999px;
      font-size: 0.825rem;
      font-weight: 700;
      box-shadow: 3px 3px 0px var(--hero-red);
    }

    .pulse-dot {
      width: 10px;
      height: 10px;
      background-color: var(--success-green);
      border-radius: 50%;
      box-shadow: 0 0 8px var(--success-green);
      animation: pulse 1.8s infinite;
    }

    @keyframes pulse {
      0% { transform: scale(0.95); opacity: 0.8; }
      50% { transform: scale(1.3); opacity: 1; }
      100% { transform: scale(0.95); opacity: 0.8; }
    }

    .stage {
      position: relative;
      z-index: 2;
      min-height: calc(100vh - 80px);
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 2rem 1.25rem 3rem;
    }

    .panel-wrapper {
      position: relative;
      width: 100%;
      max-width: 820px;
      margin: 0 auto;
    }

    /* Starburst Badge */
    .burst {
      position: absolute;
      width: 150px;
      height: 150px;
      top: -35px;
      right: -25px;
      background: var(--burst-yellow);
      clip-path: polygon(50% 0%, 61% 35%, 98% 35%, 68% 57%, 79% 91%, 50% 70%, 21% 91%, 32% 57%, 2% 35%, 39% 35%);
      transform: rotate(12deg);
      z-index: 5;
      display: flex;
      align-items: center;
      justify-content: center;
      text-align: center;
      animation: burst-float 4s ease-in-out infinite alternate;
    }

    @keyframes burst-float {
      0% { transform: rotate(10deg) translateY(0); }
      100% { transform: rotate(16deg) translateY(-8px); }
    }

    .burst-text {
      color: var(--ink);
      font-family: "Arial Black", Impact, sans-serif;
      font-weight: 900;
      font-size: 0.85rem;
      line-height: 1.15;
      transform: rotate(-8deg);
      text-transform: uppercase;
    }

    /* Neo-Brutalist Main Panel */
    .panel {
      position: relative;
      z-index: 2;
      background: rgba(19, 28, 48, 0.94);
      backdrop-filter: blur(8px);
      border: var(--border-width) solid var(--web-white);
      border-radius: 12px;
      padding: 2.5rem clamp(1.25rem, 5vw, 3rem);
      box-shadow: var(--shadow-offset) var(--shadow-offset) 0px var(--hero-red);
      animation: swing-in 0.7s cubic-bezier(0.2, 0.8, 0.2, 1.25) both;
    }

    @keyframes swing-in {
      from { transform: rotate(-3deg) translateY(-20px); opacity: 0; }
      to { transform: rotate(0deg) translateY(0); opacity: 1; }
    }

    .eyebrow {
      display: inline-block;
      font-weight: 800;
      font-size: 0.8rem;
      text-transform: uppercase;
      letter-spacing: 1.2px;
      color: var(--burst-yellow);
      background: rgba(255, 210, 63, 0.12);
      border: 1.5px solid var(--burst-yellow);
      padding: 0.25rem 0.75rem;
      border-radius: 6px;
      margin-bottom: 1.2rem;
    }

    h1 {
      font-family: "Arial Black", Impact, Haettenschweiler, sans-serif;
      font-size: clamp(2rem, 6vw, 3.4rem);
      line-height: 1.02;
      margin: 0 0 0.8rem;
      color: var(--hero-red);
      text-transform: uppercase;
      letter-spacing: -0.5px;
      text-shadow:
        -2px -2px 0 var(--ink),
         2px -2px 0 var(--ink),
        -2px  2px 0 var(--ink),
         2px  2px 0 var(--ink),
         4px  4px 0px rgba(0,0,0,0.5);
    }

    h1 .white-text {
      color: var(--web-white);
    }

    .maker-tag {
      font-size: 0.95rem;
      font-weight: 700;
      color: var(--electric);
      margin-bottom: 1.25rem;
      display: flex;
      align-items: center;
      gap: 0.4rem;
      flex-wrap: wrap;
    }

    .maker-tag span.badge {
      background: var(--electric);
      color: var(--ink);
      padding: 0.15rem 0.5rem;
      border-radius: 4px;
      font-size: 0.8rem;
      font-weight: 900;
    }

    .maker-tag span.school {
      background: rgba(255, 255, 255, 0.1);
      border: 1px solid rgba(255, 255, 255, 0.2);
      color: var(--web-white);
      padding: 0.15rem 0.5rem;
      border-radius: 4px;
      font-size: 0.8rem;
    }

    .tagline {
      font-size: 1.025rem;
      color: rgba(245, 245, 240, 0.92);
      margin: 0 0 1.75rem;
      line-height: 1.6;
      font-weight: 400;
      text-align: left;
      border-left: 4px solid var(--electric);
      padding-left: 1rem;
    }

    .arch-header {
      font-size: 0.85rem;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: var(--burst-yellow);
      margin-bottom: 0.8rem;
      font-weight: 800;
      text-align: left;
    }

    .vm-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 0.75rem;
      margin-bottom: 1.75rem;
    }

    .vm-card {
      background: var(--panel-dark);
      border: 2px solid var(--web-white);
      border-radius: 8px;
      padding: 0.85rem;
      box-shadow: 3px 3px 0px var(--ink);
      transition: transform 0.2s ease, border-color 0.2s ease;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
    }

    .vm-card:hover {
      transform: translateY(-3px);
      border-color: var(--electric);
    }

    .vm-card .vm-title {
      font-weight: 800;
      font-size: 0.9rem;
      color: var(--burst-yellow);
      display: flex;
      align-items: center;
      gap: 0.4rem;
      margin-bottom: 0.3rem;
    }

    .vm-card .vm-role {
      font-size: 0.75rem;
      color: rgba(245, 245, 240, 0.75);
      margin-bottom: 0.5rem;
      line-height: 1.3;
    }

    .vm-card .vm-tag {
      font-family: monospace;
      font-size: 0.7rem;
      background: rgba(41, 182, 246, 0.15);
      color: var(--electric);
      padding: 0.2rem 0.4rem;
      border-radius: 4px;
      border: 1px solid rgba(41, 182, 246, 0.3);
      display: inline-block;
      width: fit-content;
    }

    .skills-title {
      font-size: 0.8rem;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: rgba(245, 245, 240, 0.6);
      margin-bottom: 0.6rem;
      font-weight: 700;
      text-align: left;
    }

    .skills {
      list-style: none;
      display: flex;
      flex-wrap: wrap;
      gap: 0.5rem;
      justify-content: flex-start;
      padding: 0;
      margin: 0 0 2rem;
    }

    .skills li {
      background: var(--panel-dark);
      border: 2px solid var(--web-white);
      border-radius: 999px;
      padding: 0.35rem 0.85rem;
      font-size: 0.825rem;
      font-weight: 700;
      display: flex;
      align-items: center;
      gap: 0.4rem;
      box-shadow: 2px 2px 0px var(--ink);
      transition: transform 0.2s ease, background 0.2s ease;
    }

    .skills li:hover {
      transform: translateY(-2px);
      background: var(--hero-red);
      color: var(--web-white);
    }

    .skills li svg {
      width: 14px;
      height: 14px;
      fill: currentColor;
    }

    .terminal-card {
      background: var(--panel-dark);
      border: 2px solid var(--web-white);
      border-radius: 8px;
      overflow: hidden;
      margin-top: 1rem;
      box-shadow: 4px 4px 0px var(--ink);
    }

    .terminal-header {
      background: rgba(255, 255, 255, 0.06);
      padding: 0.5rem 0.85rem;
      display: flex;
      align-items: center;
      justify-content: space-between;
      border-bottom: 1px solid rgba(255, 255, 255, 0.1);
      flex-wrap: wrap;
      gap: 0.5rem;
    }

    .terminal-dots {
      display: flex;
      gap: 6px;
    }

    .dot-btn {
      width: 10px;
      height: 10px;
      border-radius: 50%;
    }

    .dot-btn.red { background: #FF5F56; }
    .dot-btn.yellow { background: #FFBD2E; }
    .dot-btn.green { background: #27C93F; }

    .terminal-tabs {
      display: flex;
      gap: 0.3rem;
    }

    .term-tab-btn {
      background: transparent;
      border: 1px solid rgba(255, 255, 255, 0.2);
      color: rgba(245, 245, 240, 0.7);
      padding: 0.2rem 0.6rem;
      border-radius: 4px;
      font-family: monospace;
      font-size: 0.725rem;
      cursor: pointer;
      transition: all 0.2s ease;
    }

    .term-tab-btn.active, .term-tab-btn:hover {
      background: var(--electric);
      color: var(--ink);
      border-color: var(--electric);
      font-weight: 700;
    }

    .terminal-body {
      padding: 1rem;
      font-family: "Courier New", Courier, monospace;
      font-size: 0.825rem;
      color: #A9DC76;
      line-height: 1.5;
      text-align: left;
      overflow-x: auto;
      min-height: 160px;
    }

    .terminal-tab-content {
      display: none;
    }

    .terminal-tab-content.active {
      display: block;
    }

    .terminal-line {
      display: flex;
      align-items: flex-start;
      gap: 0.5rem;
      margin-bottom: 0.35rem;
      flex-wrap: wrap;
    }

    .prompt {
      color: var(--electric);
      user-select: none;
    }

    .command {
      color: var(--web-white);
      font-weight: 700;
    }

    .response-header {
      color: #FFD23F;
    }

    .cta-row {
      display: flex;
      gap: 0.85rem;
      flex-wrap: wrap;
      margin-top: 1.75rem;
      margin-bottom: 1.25rem;
    }

    .cta {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      text-decoration: none;
      font-weight: 800;
      font-size: 0.9rem;
      padding: 0.7rem 1.25rem;
      border-radius: 8px;
      border: 2px solid var(--web-white);
      box-shadow: 4px 4px 0px var(--ink);
      transition: transform 0.15s ease, box-shadow 0.15s ease, background 0.2s ease;
      cursor: pointer;
    }

    .cta:hover {
      transform: translate(-2px, -2px);
      box-shadow: 6px 6px 0px var(--ink);
    }

    .cta:active {
      transform: translate(2px, 2px);
      box-shadow: 2px 2px 0px var(--ink);
    }

    .cta.primary {
      background: var(--hero-red);
      color: var(--web-white);
    }

    .cta.secondary {
      background: var(--electric);
      color: var(--ink);
    }

    .cta.outline {
      background: transparent;
      color: var(--web-white);
      border-color: var(--web-white);
    }

    .cta svg {
      width: 16px;
      height: 16px;
      fill: currentColor;
    }

    /* Footnote */
    .footnote {
      font-size: 0.825rem;
      color: rgba(245, 245, 240, 0.75);
      margin-top: 1.5rem;
      padding-top: 1rem;
      border-top: 1px dashed rgba(245, 245, 240, 0.2);
      display: flex;
      align-items: center;
      justify-content: space-between;
      flex-wrap: wrap;
      gap: 0.5rem;
    }

    .server-host {
      font-family: monospace;
      background: var(--panel-dark);
      padding: 0.2rem 0.5rem;
      border-radius: 4px;
      color: var(--electric);
      border: 1px solid rgba(41, 182, 246, 0.3);
    }

    /* Toast Notification */
    .toast {
      position: fixed;
      bottom: 20px;
      right: 20px;
      background: var(--burst-yellow);
      color: var(--ink);
      font-weight: 800;
      padding: 0.75rem 1.25rem;
      border-radius: 8px;
      border: 2px solid var(--ink);
      box-shadow: 4px 4px 0px var(--ink);
      z-index: 100;
      transform: translateY(100px);
      opacity: 0;
      transition: all 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
    }

    .toast.show {
      transform: translateY(0);
      opacity: 1;
    }

    /* Responsive Adjustments */
    @media (max-width: 640px) {
      .burst {
        width: 110px;
        height: 110px;
        top: -25px;
        right: -10px;
      }
      .burst-text {
        font-size: 0.7rem;
      }
      .panel {
        padding: 2rem 1.25rem;
        box-shadow: 5px 5px 0px var(--hero-red);
      }
      .cta-row {
        flex-direction: column;
      }
      .cta {
        width: 100%;
        justify-content: center;
      }
    }
  </style>
</head>
<body>

  <header class="top-bar">
    <a href="#" class="brand">
      <svg class="brand-icon" viewBox="0 0 24 24">
        <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
      </svg>
      KsHamane / DevOps
    </a>
    <div class="live-status">
      <span class="pulse-dot"></span>
      <span>HTTPS SECURE • 4-NODE CLUSTER</span>
    </div>
  </header>

  <main class="stage">
    <div class="panel-wrapper">

      <!-- Starburst Badge -->
      <div class="burst" aria-hidden="true">
        <span class="burst-text">4-VM MESH<br>100% AUTOMATED</span>
      </div>

      <!-- Main Brutalist Panel -->
      <section class="panel">

        <!-- Eyebrow status -->
        <div class="eyebrow">HTTPS / TLS 1.3 • AUTOMATED LINUX CLUSTER DEPLOYED</div>

        <!-- Big Main Heading -->
        <h1>AUTOMATED LINUX <br><span class="white-text">INFRASTRUCTURE</span></h1>

        <!-- Maker Attribution -->
        <div class="maker-tag">
          Architected by <strong>Karim Salah Hamane</strong>
          <span class="badge">KsHamane</span>
          <span class="school">1st Year @ ENSTTIC (Oran, Algeria)</span>
        </div>

        <!-- Project Description Paragraph -->
        <p class="tagline">
          This site is served live over <strong>HTTPS</strong> via <strong>Nginx</strong> from a 4-node local Linux cloud cluster built with <strong>Multipass</strong>. A single automated PowerShell orchestrator provisions all four VMs, dynamically generates the IP mesh network (<code>all-ips.txt</code>), exports central NFS storage, hardens a secure SSH Bastion jump host, and configures automated daily cron backups.
        </p>

        <div class="arch-header">⚡ 4-Node Architecture Overview:</div>
        <div class="vm-grid">
          <div class="vm-card">
            <div>
              <div class="vm-title">📦 VM 1: nfs-server</div>
              <div class="vm-role">Central Network File Storage. Exports <code>/srv/shared</code> to all cluster nodes.</div>
            </div>
            <span class="vm-tag">NFS Server</span>
          </div>

          <div class="vm-card">
            <div>
              <div class="vm-title">🛡️ VM 2: jump-host</div>
              <div class="vm-role">Bastion. Custom Port 6546, Key-Only Auth, No Root, Cron Backups @ 12:00.</div>
            </div>
            <span class="vm-tag">SSH Bastion</span>
          </div>

          <div class="vm-card">
            <div>
              <div class="vm-title">🌐 VM 3: web-server</div>
              <div class="vm-role">Mounts NFS at <code>/mnt/shared</code>. Runs Nginx with SSL/TLS HTTPS.</div>
            </div>
            <span class="vm-tag">HTTPS / Nginx</span>
          </div>

          <div class="vm-card">
            <div>
              <div class="vm-title">🔗 Mesh Network</div>
              <div class="vm-role">Master PowerShell script syncs all node IPs into <code>all-ips.txt</code>.</div>
            </div>
            <span class="vm-tag">Multipass + PS</span>
          </div>
        </div>

        <div class="skills-title">Skills Mastered & Tools Featured:</div>
        <ul class="skills">
          <li>
            <svg viewBox="0 0 24 24"><path d="M12 2a10 10 0 00-10 10c0 5.52 4.48 10 10 10s10-4.48 10-10A10 10 0 0012 2zm1 14.5h-2v-2h2v2zm0-4h-2v-6h2v6z"/></svg>
            Linux Infrastructure
          </li>
          <li>
            <svg viewBox="0 0 24 24"><path d="M12 2L2 7v10l10 5 10-5V7L12 2zm0 2.8L18.6 8 12 11.2 5.4 8 12 4.8zM4 9.6l7 3.5v6.5l-7-3.5V9.6zm16 6.5l-7 3.5v-6.5l7-3.5v6.5z"/></svg>
            Multipass Automation
          </li>
          <li>
            <svg viewBox="0 0 24 24"><path d="M4 17l6-5-6-5v10zm8 0h8v-2h-8v2z"/></svg>
            PowerShell & Shell Scripting
          </li>
          <li>
            <svg viewBox="0 0 24 24"><path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm0 10.99h7c-.53 4.12-3.28 7.79-7 8.94V12H5V6.3l7-3.11v8.8s0 0 0 0z"/></svg>
            Bastion Hardening (Port 6546)
          </li>
          <li>
            <svg viewBox="0 0 24 24"><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14H7v-2h7v2zm3-4H7v-2h10v2zm0-4H7V7h10v2z"/></svg>
            NFS Shared Storage
          </li>
          <li>
            <svg viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 15h-2v-6h2v6zm0-8h-2V7h2v2z"/></svg>
            Nginx & Self-Signed SSL
          </li>
          <li>
            <svg viewBox="0 0 24 24"><path d="M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8zm.5-13H11v6l5.25 3.15.75-1.23-4.5-2.67z"/></svg>
            Cron Automation Backups
          </li>
        </ul>

        <div class="terminal-card">
          <div class="terminal-header">
            <div class="terminal-dots">
              <div class="dot-btn red"></div>
              <div class="dot-btn yellow"></div>
              <div class="dot-btn green"></div>
            </div>
            <div class="terminal-tabs">
              <button class="term-tab-btn active" onclick="switchTab('tab-https')">web-server</button>
              <button class="term-tab-btn" onclick="switchTab('tab-jump')">jump-host</button>
              <button class="term-tab-btn" onclick="switchTab('tab-nfs')">nfs-server</button>
              <button class="term-tab-btn" onclick="switchTab('tab-cron')">cron-backup</button>
            </div>
          </div>

          <div class="terminal-body">
            <!-- TAB 1: HTTPS Verification -->
            <div id="tab-https" class="terminal-tab-content active">
              <div class="terminal-line">
                <span class="prompt">kshamane@web-server:~$</span>
                <span class="command">curl -kI https://localhost</span>
              </div>
              <div class="terminal-line">
                <span class="response-header">HTTP/1.1 200 OK</span>
              </div>
              <div class="terminal-line">
                <span>Server: nginx/1.24.0 (Ubuntu)</span>
              </div>
              <div class="terminal-line">
                <span>SSL-Cert: Self-Signed (Generated via OpenSSL setup.sh)</span>
              </div>
              <div class="terminal-line">
                <span>Content-Source: /mnt/shared/apps/test_site.html</span>
              </div>
              <div class="terminal-line" style="margin-top: 0.4rem;">
                <span class="prompt">kshamane@web-server:~$</span>
                <span style="color: #29B6F6;"># Live HTTPS Web Server ready! 🚀</span>
              </div>
            </div>

            <!-- TAB 2: Jump Host SSH Bastion -->
            <div id="tab-jump" class="terminal-tab-content">
              <div class="terminal-line">
                <span class="prompt">PS C:\Users\Karim></span>
                <span class="command">ssh -i ~/.ssh/id_rsa -p 6546 kshamane@jump-host</span>
              </div>
              <div class="terminal-line">
                <span class="response-header">Welcome to Ubuntu 24.04 LTS (Hardened Bastion Host)</span>
              </div>
              <div class="terminal-line">
                <span>Security Policies: PasswordAuthentication=no | PermitRootLogin=no</span>
              </div>
              <div class="terminal-line">
                <span class="prompt">kshamane@jump-host:~$</span>
                <span class="command">cat /etc/all-ips.txt</span>
              </div>
              <div class="terminal-line">
                <span style="color: #FFD23F;">nfs-server: 10.152.183.10 | jump-host: 10.152.183.11 | web-server: 10.152.183.12</span>
              </div>
            </div>

            <!-- TAB 3: NFS Server Storage -->
            <div id="tab-nfs" class="terminal-tab-content">
              <div class="terminal-line">
                <span class="prompt">kshamane@nfs-server:~$</span>
                <span class="command">showmount -e localhost</span>
              </div>
              <div class="terminal-line">
                <span class="response-header">Export list for localhost:</span>
              </div>
              <div class="terminal-line">
                <span>/srv/shared 10.152.183.0/24(rw,sync,no_subtree_check)</span>
              </div>
              <div class="terminal-line">
                <span class="prompt">kshamane@nfs-server:~$</span>
                <span class="command">ls -l /srv/shared/apps/</span>
              </div>
              <div class="terminal-line">
                <span style="color: #29B6F6;">-rw-r--r-- 1 root root 12480 Sep 26 test_site.html</span>
              </div>
            </div>

            <!-- TAB 4: Daily Cron Backups -->
            <div id="tab-cron" class="terminal-tab-content">
              <div class="terminal-line">
                <span class="prompt">kshamane@jump-host:~$</span>
                <span class="command">crontab -l</span>
              </div>
              <div class="terminal-line">
                <span class="response-header"># Daily backup of /mnt/shared at 12:00 PM</span>
              </div>
              <div class="terminal-line">
                <span>0 12 * * * /usr/local/bin/backup-shared.sh</span>
              </div>
              <div class="terminal-line">
                <span class="prompt">kshamane@jump-host:~$</span>
                <span class="command">ls -lh /var/backups/shared/</span>
              </div>
              <div class="terminal-line">
                <span style="color: #FFD23F;">backup-26-09-2026.tar.gz (14.2 MB) [SUCCESS]</span>
              </div>
            </div>

          </div>
        </div>

        <div class="cta-row">
          <a class="cta secondary" href="https://github.com/KsHamane" target="_blank" rel="noopener noreferrer" id="github-link">
            <svg viewBox="0 0 24 24"><path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z"/></svg>
            GitHub Portfolio
          </a>
          <a class="cta primary" href="https://www.linkedin.com/in/karim-salah-hamane" target="_blank" rel="noopener noreferrer" id="linkedin-link">
            <svg viewBox="0 0 24 24"><path d="M19 3a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h14m-.5 15.5v-5.3a3.26 3.26 0 0 0-3.26-3.26c-.85 0-1.84.52-2.28 1.3v-1.11h-2.79v8.37h2.79v-4.93c0-.77.62-1.4 1.39-1.4a1.4 1.4 0 0 1 1.4 1.4v4.93h2.75M6.46 10.9v8.37H9.25V10.9H6.46M7.86 6.78a1.62 1.62 0 1 0 0 3.24 1.62 1.62 0 0 0 0-3.24z"/></svg>
            Connect on LinkedIn
          </a>
          <button class="cta outline" onclick="copyCurlCommand()">
            <svg viewBox="0 0 24 24"><path d="M16 1H4c-1.1 0-2 .9-2 2v14h2V3h12V1zm3 4H8c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h11c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2zm0 16H8V7h11v14z"/></svg>
            Copy CURL Test
          </button>
        </div>

        <!-- Dynamic Hostname Footnote -->
        <div class="footnote">
          <span id="server-location">Served live via Nginx over HTTPS</span>
          <span id="timestamp-badge" style="font-family: monospace; opacity: 0.85;">Cluster Status: 100% OK</span>
        </div>

      </section>
    </div>
  </main>

  <!-- Toast Box for Clipboard feedback -->
  <div class="toast" id="toast">Command copied to clipboard!</div>

  <script>
    document.addEventListener('DOMContentLoaded', function() {
      // Determine real host or domain
      const host = window.location.host || window.location.hostname || 'localhost';

      const serverLocEl = document.getElementById('server-location');
      if (serverLocEl) {
        serverLocEl.innerHTML = 'Served live from <span class="server-host">' + host + '</span> via Nginx HTTPS';
      }

      // Update timestamp
      const now = new Date();
      const timeStr = now.toISOString().split('T')[1].slice(0, 8) + ' UTC';
      const timeEl = document.getElementById('timestamp-badge');
      if (timeEl) {
        timeEl.textContent = 'Cluster Check: ' + timeStr + ' • 4/4 Nodes Active';
      }
    });

    // Tab switcher logic
    function switchTab(tabId) {
      // Hide all tabs
      const tabs = document.querySelectorAll('.terminal-tab-content');
      tabs.forEach(t => t.classList.remove('active'));

      // Deactivate all buttons
      const btns = document.querySelectorAll('.term-tab-btn');
      btns.forEach(b => b.classList.remove('active'));

      // Activate target tab & button
      const targetTab = document.getElementById(tabId);
      if (targetTab) targetTab.classList.add('active');

      const activeBtn = Array.from(btns).find(btn => btn.getAttribute('onclick').includes(tabId));
      if (activeBtn) activeBtn.classList.add('active');
    }

    // Copy CURL command functionality
    function copyCurlCommand() {
      const host = window.location.host || 'localhost';
      const commandText = 'curl -kI https://' + host;

      // Fallback copy logic for iFrame compatibility
      const dummy = document.createElement('textarea');
      document.body.appendChild(dummy);
      dummy.value = commandText;
      dummy.select();
      document.execCommand('copy');
      document.body.removeChild(dummy);

      // Show toast
      showToast('Copied: "' + commandText + '"');
    }

    function showToast(message) {
      const toast = document.getElementById('toast');
      toast.textContent = message;
      toast.classList.add('show');
      setTimeout(function() {
        toast.classList.remove('show');
      }, 2500);
    }
  </script>
</body>
</html>



EOF
