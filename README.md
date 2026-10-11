# 🛡️ WireGuard Telegram Notifier
A Bash script for WireGuard installed over PiVPN that sends real-time connection and disconnection alerts via Telegram.<br>
![WireGuard](https://img.shields.io/badge/WireGuard-88171A?style=for-the-badge&logo=wireguard&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=GNU%20Bash&logoColor=white)
![Telegram](https://img.shields.io/badge/Telegram-26A5E4?style=for-the-badge&logo=telegram&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
---
## 🚀 Features
- 🟢 **Real-Time Alerts:** Get notified instantly when a peer connects or disconnects.
- 🏷️ **Detect Peer Names:** Automatically maps public keys to client names using PiVPN comments or `.conf` profiles.
- 🌐 **IP Tracking:** Detects external IP address changes during active sessions.
- ⚡ **Lightweight:** Uses native `wg` command output and simple state files without heavy dependencies.
---
## 📋 Prerequisites
- A working **WireGuard** instance (standalone or installed via **PiVPN**).
- `curl` installed on your server (`sudo apt install curl`).
- A Telegram Bot token (created via [@BotFather](https://t.me/BotFather)) and your Chat ID.
---
## 🔧 Installation & Setup
1. **Clone the repository:**
   ```bash
   git clone https://github.com/0xAlves/wireguard-telegram-notifier.git
   cd wireguard-telegram-notifier
   ```
2. **Move the script to a system path:**
   ```bash
   sudo cp wg-monitor.sh /usr/local/bin/wg-monitor.sh
   sudo chmod +x /usr/local/bin/wg-monitor.sh
   ```
3. **Create the configuration file:**
   ```bash
   sudo cp notifier.conf.example /etc/wireguard/notifier.conf
   sudo nano /etc/wireguard/notifier.conf
   ```
   Fill in your `BOT_TOKEN`, `CHAT_ID`, and adjust the paths if needed.
4. **Add it to cron (runs every minute):**
   ```bash
   sudo crontab -e
   ```
   Add the following line at the end:
   ```cron
   * * * * * /usr/local/bin/wg-monitor.sh >/dev/null 2>&1
   ```
---
## 🧪 How it works
- The script checks the current WireGuard peer state, compares it with the last known state, and sends a Telegram message whenever a peer connects or disconnects.
---
## 📌 Notes
- This project is designed for Linux systems using `wg` and standard shell utilities.
- For PiVPN, the script can use the client comments or config names to display friendlier peer names.
- You can adjust the notification text or the polling frequency as needed.