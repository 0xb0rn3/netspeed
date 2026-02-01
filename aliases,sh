#!/bin/bash
# NetSpeed Aliases - Add these to your ~/.zshrc or ~/.bashrc

# ============================================================================
# NETWORK SPEED TEST ALIASES
# ============================================================================

# Quick speed test
alias speedtest='netspeed -q'
alias st='netspeed -q'

# Full speed test (all tests)
alias speedtest-full='netspeed -f'
alias stf='netspeed -f'

# Ping test only
alias pingtest='netspeed -p'
alias pt='netspeed -p'

# Bandwidth test
alias bandwidth='netspeed -b'
alias bw='netspeed -b'

# Network info
alias netinfo='netspeed -i'
alias ni='netspeed -i'

# View speed test history
alias speedhistory='netspeed -h'
alias sth='netspeed -h'

# Interactive menu
alias netspeed-menu='netspeed'

# ============================================================================
# ADDITIONAL NETWORK UTILITIES
# ============================================================================

# Quick ping to common servers
alias ping1='ping -c 5 1.1.1.1'          # Cloudflare
alias ping8='ping -c 5 8.8.8.8'          # Google
alias pingg='ping -c 5 google.com'       # Google

# Show my public IP
alias myip='curl -s ifconfig.me && echo'
alias myip4='curl -s -4 ifconfig.me && echo'
alias myip6='curl -s -6 ifconfig.me && echo'
alias myipinfo='curl -s ipinfo.io'

# Show local IP addresses
alias localip='ip -4 addr show | grep -oP "(?<=inet\s)\d+(\.\d+){3}"'
alias localip6='ip -6 addr show | grep -oP "(?<=inet6\s)[0-9a-f:]+"'

# Network interfaces
alias interfaces='ip -br addr'
alias ifaces='ip -br link'

# Show active connections
alias connections='ss -tuln'
alias listening='ss -tuln | grep LISTEN'

# DNS lookup
alias dns='dig +short'
alias dnsf='dig +noall +answer'  # Full DNS info

# Traceroute shortcuts
alias trace='traceroute -I'
alias trace4='traceroute -4'
alias trace6='traceroute -6'

# Network statistics
alias netstats='netstat -s'
alias netcount='netstat -ant | wc -l'

# Show routing table
alias routes='ip route'
alias route6='ip -6 route'

# Port scanning (requires nmap)
alias portscan='nmap -sV localhost'
alias portscan-quick='nmap -F localhost'

# Download speed test using curl
alias dltest='curl -o /dev/null -w "Download Speed: %{speed_download} bytes/sec\nTime: %{time_total}s\n" http://speedtest.tele2.net/10MB.zip'

# Network quality test
alias netquality='ping -c 20 8.8.8.8 | tail -1 | awk -F "/" "{print \"Avg Ping: \" \$5 \" ms\"}"'

# Show bandwidth usage (requires vnstat)
alias bandwidth-usage='vnstat -l'
alias bandwidth-daily='vnstat -d'

# WiFi information (if using NetworkManager)
alias wifiinfo='nmcli device wifi list'
alias wifistrength='nmcli device wifi | grep "^\*"'

# Show network devices
alias netdevices='lspci | grep -i network'

# Flush DNS cache (systemd-resolved)
alias flushdns='sudo systemd-resolve --flush-caches && echo "DNS cache flushed"'

# ============================================================================
# FIREWALL & SECURITY
# ============================================================================

# Show firewall status
alias fwstatus='sudo iptables -L -n -v'
alias fw6status='sudo ip6tables -L -n -v'

# Show open ports
alias openports='sudo lsof -i -P -n | grep LISTEN'

# ============================================================================
# USAGE EXAMPLES
# ============================================================================
# 
# speedtest          - Quick speed test (ping + download/upload)
# speedtest-full     - Full comprehensive test
# pingtest           - Test ping to multiple servers
# myip               - Show your public IP
# netinfo            - Show network configuration
# connections        - Show active network connections
# dltest             - Quick download speed test
#
# ============================================================================

# Color output for network commands
if command -v grc &>/dev/null; then
    alias ping='grc ping'
    alias traceroute='grc traceroute'
    alias netstat='grc netstat'
fi

# ============================================================================
# FUNCTIONS FOR ADVANCED USAGE
# ============================================================================

# Test connection to specific host
testhost() {
    if [ -z "$1" ]; then
        echo "Usage: testhost <hostname>"
        return 1
    fi
    
    echo "Testing connection to $1..."
    echo
    echo "=== Ping Test ==="
    ping -c 5 "$1"
    echo
    echo "=== DNS Lookup ==="
    dig +short "$1"
    echo
    echo "=== Traceroute ==="
    traceroute -m 15 "$1"
}

# Download speed test from custom URL
speedtest-url() {
    if [ -z "$1" ]; then
        echo "Usage: speedtest-url <url>"
        return 1
    fi
    
    echo "Testing download speed from: $1"
    curl -o /dev/null -w "\nDownload Speed: %{speed_download} bytes/sec (%{size_download} bytes in %{time_total}s)\n" "$1"
}

# Port check
portcheck() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: portcheck <host> <port>"
        return 1
    fi
    
    if timeout 3 bash -c "echo >/dev/tcp/$1/$2" 2>/dev/null; then
        echo "Port $2 is OPEN on $1"
        return 0
    else
        echo "Port $2 is CLOSED on $1"
        return 1
    fi
}

# Continuous ping with timestamp
pingwatch() {
    local host="${1:-8.8.8.8}"
    ping "$host" | while read line; do
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $line"
    done
}

# Network speed monitor (updates every second)
speedmonitor() {
    local interface="${1:-$(ip route | grep default | awk '{print $5}' | head -1)}"
    
    echo "Monitoring interface: $interface"
    echo "Press Ctrl+C to stop"
    echo
    
    local prev_rx=0
    local prev_tx=0
    
    while true; do
        local rx=$(cat /sys/class/net/"$interface"/statistics/rx_bytes)
        local tx=$(cat /sys/class/net/"$interface"/statistics/tx_bytes)
        
        if [ $prev_rx -ne 0 ]; then
            local rx_rate=$(( (rx - prev_rx) / 1024 ))
            local tx_rate=$(( (tx - prev_tx) / 1024 ))
            
            printf "\r↓ %6d KB/s  ↑ %6d KB/s" $rx_rate $tx_rate
        fi
        
        prev_rx=$rx
        prev_tx=$tx
        sleep 1
    done
}

# Scan local network for active hosts
scan-network() {
    local network="${1:-192.168.1.0/24}"
    
    echo "Scanning network: $network"
    echo "This may take a few minutes..."
    echo
    
    if command -v nmap &>/dev/null; then
        sudo nmap -sn "$network" | grep "Nmap scan report" | awk '{print $5}'
    else
        echo "nmap not installed. Install with: sudo pacman -S nmap"
        return 1
    fi
}

# ============================================================================
# EXPORT FUNCTIONS
# ============================================================================

export -f testhost
export -f speedtest-url
export -f portcheck
export -f pingwatch
export -f speedmonitor
export -f scan-network
