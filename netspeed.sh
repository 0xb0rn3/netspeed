#!/bin/bash
# NetSpeed - Comprehensive Network Speed Testing Tool
# Tests download, upload, ping, and network quality

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Configuration
SPEEDTEST_CLI="speedtest-cli"
FAST_CLI="fast"
LOG_DIR="$HOME/.netspeed"
LOG_FILE="$LOG_DIR/speedtest_history.log"

# Ping test servers
PING_SERVERS=(
    "1.1.1.1:Cloudflare"
    "8.8.8.8:Google DNS"
    "208.67.222.222:OpenDNS"
    "9.9.9.9:Quad9"
)

# Download test files (for manual testing)
TEST_FILES=(
    "http://speedtest.tele2.net/100MB.zip:100MB"
    "http://speedtest.tele2.net/10MB.zip:10MB"
)

show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     ███╗   ██╗███████╗████████╗███████╗██████╗ ███████╗███████╗██████╗  ║
║     ████╗  ██║██╔════╝╚══██╔══╝██╔════╝██╔══██╗██╔════╝██╔════╝██╔══██╗ ║
║     ██╔██╗ ██║█████╗     ██║   ███████╗██████╔╝█████╗  █████╗  ██║  ██║ ║
║     ██║╚██╗██║██╔══╝     ██║   ╚════██║██╔═══╝ ██╔══╝  ██╔══╝  ██║  ██║ ║
║     ██║ ╚████║███████╗   ██║   ███████║██║     ███████╗███████╗██████╔╝ ║
║     ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚══════╝╚══════╝╚═════╝  ║
║                                                              ║
║              Network Speed & Quality Testing Tool            ║
║                        by 0xb0rn3                           ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

show_loading() {
    local msg="$1"
    local duration="${2:-3}"
    
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local end_time=$(($(date +%s) + duration))
    
    tput civis
    while [[ $(date +%s) -lt $end_time ]]; do
        for frame in "${frames[@]}"; do
            printf "\r${CYAN}${frame} ${msg}${NC}"
            sleep 0.1
        done
    done
    printf "\r${GREEN}✓ ${msg}${NC}\n"
    tput cnorm
}

check_dependencies() {
    local missing=()
    
    # Check for speedtest-cli
    if ! command -v speedtest-cli &>/dev/null; then
        missing+=("speedtest-cli")
    fi
    
    # Check for optional tools
    if ! command -v fast &>/dev/null; then
        echo -e "${YELLOW}[!] Note: 'fast-cli' not installed (optional Netflix speed test)${NC}"
        echo -e "${DIM}    Install with: sudo npm install -g fast-cli${NC}"
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}[!] Missing required dependencies: ${missing[*]}${NC}"
        echo
        read -p "Install missing dependencies? [Y/n]: " -n 1 -r
        echo
        
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            echo -e "${CYAN}[*] Installing dependencies...${NC}"
            
            for dep in "${missing[@]}"; do
                case $dep in
                    speedtest-cli)
                        if command -v pacman &>/dev/null; then
                            sudo pacman -S --needed --noconfirm speedtest-cli
                        elif command -v apt &>/dev/null; then
                            sudo apt install -y speedtest-cli
                        else
                            pip install speedtest-cli
                        fi
                        ;;
                esac
            done
            
            echo -e "${GREEN}[+] Dependencies installed${NC}"
        else
            echo -e "${RED}Cannot proceed without required dependencies${NC}"
            exit 1
        fi
    fi
}

test_ping() {
    echo -e "${CYAN}${BOLD}[*] Ping Test${NC}"
    echo -e "${DIM}Testing latency to major servers...${NC}"
    echo
    
    local total_latency=0
    local server_count=0
    local min_ping=99999
    local max_ping=0
    local min_server=""
    local max_server=""
    
    for server_info in "${PING_SERVERS[@]}"; do
        local server=$(echo "$server_info" | cut -d: -f1)
        local name=$(echo "$server_info" | cut -d: -f2)
        
        # Ping 5 times and get average
        local ping_result=$(ping -c 5 -W 2 "$server" 2>/dev/null | tail -1 | awk -F'/' '{print $5}')
        
        if [ -n "$ping_result" ]; then
            local ping_ms=$(printf "%.0f" "$ping_result")
            
            echo -ne "  ${CYAN}•${NC} $name ($server): "
            
            # Color code based on latency
            if [ "$ping_ms" -lt 30 ]; then
                echo -e "${GREEN}${BOLD}${ping_ms}ms${NC} ${GREEN}[Excellent]${NC}"
            elif [ "$ping_ms" -lt 60 ]; then
                echo -e "${CYAN}${ping_ms}ms${NC} ${CYAN}[Good]${NC}"
            elif [ "$ping_ms" -lt 100 ]; then
                echo -e "${YELLOW}${ping_ms}ms${NC} ${YELLOW}[Fair]${NC}"
            else
                echo -e "${RED}${ping_ms}ms${NC} ${RED}[Poor]${NC}"
            fi
            
            total_latency=$((total_latency + ping_ms))
            server_count=$((server_count + 1))
            
            if [ "$ping_ms" -lt "$min_ping" ]; then
                min_ping=$ping_ms
                min_server="$name"
            fi
            
            if [ "$ping_ms" -gt "$max_ping" ]; then
                max_ping=$ping_ms
                max_server="$name"
            fi
        else
            echo -e "  ${CYAN}•${NC} $name ($server): ${RED}Failed${NC}"
        fi
    done
    
    if [ "$server_count" -gt 0 ]; then
        local avg_ping=$((total_latency / server_count))
        
        echo
        echo -e "${YELLOW}Summary:${NC}"
        echo -e "  • Average: ${CYAN}${avg_ping}ms${NC}"
        echo -e "  • Best: ${GREEN}${min_ping}ms${NC} (${min_server})"
        echo -e "  • Worst: ${RED}${max_ping}ms${NC} (${max_server})"
    fi
    
    echo
}

test_speedtest_cli() {
    echo -e "${CYAN}${BOLD}[*] Speedtest (Ookla)${NC}"
    echo -e "${DIM}Testing download and upload speeds...${NC}"
    echo
    
    local temp_file=$(mktemp)
    
    # Show server selection
    echo -e "${CYAN}[*] Finding best server...${NC}"
    speedtest-cli --simple --secure > "$temp_file" 2>&1 &
    local pid=$!
    
    # Animated loading
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    tput civis
    while kill -0 $pid 2>/dev/null; do
        for frame in "${frames[@]}"; do
            printf "\r${CYAN}${frame} Running speedtest...${NC}"
            sleep 0.1
        done
    done
    wait $pid
    printf "\r${GREEN}✓ Speedtest complete${NC}\n"
    tput cnorm
    
    echo
    
    # Parse results
    if [ -f "$temp_file" ]; then
        local ping=$(grep "Ping:" "$temp_file" | awk '{print $2}')
        local download=$(grep "Download:" "$temp_file" | awk '{print $2}')
        local upload=$(grep "Upload:" "$temp_file" | awk '{print $2}')
        
        echo -e "${YELLOW}Results:${NC}"
        echo -e "  ${CYAN}•${NC} Ping: ${GREEN}${BOLD}${ping} ms${NC}"
        echo -e "  ${CYAN}•${NC} Download: ${GREEN}${BOLD}${download} Mbit/s${NC}"
        echo -e "  ${CYAN}•${NC} Upload: ${GREEN}${BOLD}${upload} Mbit/s${NC}"
        
        # Calculate quality rating
        local rating=$(calculate_quality_rating "$download" "$upload" "$ping")
        echo -e "  ${CYAN}•${NC} Quality: $rating"
        
        # Log results
        log_result "Speedtest-CLI" "$ping" "$download" "$upload"
        
        rm -f "$temp_file"
    else
        echo -e "${RED}Failed to get speedtest results${NC}"
    fi
    
    echo
}

test_fast_cli() {
    if ! command -v fast &>/dev/null; then
        return
    fi
    
    echo -e "${CYAN}${BOLD}[*] Fast.com (Netflix)${NC}"
    echo -e "${DIM}Testing Netflix CDN speed...${NC}"
    echo
    
    # Run fast-cli with upload test
    local result=$(fast --upload --json 2>/dev/null)
    
    if [ -n "$result" ]; then
        local download=$(echo "$result" | jq -r '.downloadSpeed' 2>/dev/null)
        local upload=$(echo "$result" | jq -r '.uploadSpeed' 2>/dev/null)
        
        if [ -n "$download" ] && [ "$download" != "null" ]; then
            echo -e "${YELLOW}Results:${NC}"
            echo -e "  ${CYAN}•${NC} Download: ${GREEN}${BOLD}${download} Mbps${NC}"
            
            if [ -n "$upload" ] && [ "$upload" != "null" ]; then
                echo -e "  ${CYAN}•${NC} Upload: ${GREEN}${BOLD}${upload} Mbps${NC}"
            fi
            
            log_result "Fast.com" "N/A" "$download" "$upload"
        fi
    else
        echo -e "${YELLOW}[!] Fast.com test unavailable${NC}"
    fi
    
    echo
}

calculate_quality_rating() {
    local download=$1
    local upload=$2
    local ping=$3
    
    # Remove decimals for comparison
    download=${download%.*}
    upload=${upload%.*}
    ping=${ping%.*}
    
    local score=0
    
    # Download score (max 40 points)
    if [ "$download" -ge 100 ]; then
        score=$((score + 40))
    elif [ "$download" -ge 50 ]; then
        score=$((score + 30))
    elif [ "$download" -ge 25 ]; then
        score=$((score + 20))
    elif [ "$download" -ge 10 ]; then
        score=$((score + 10))
    fi
    
    # Upload score (max 30 points)
    if [ "$upload" -ge 50 ]; then
        score=$((score + 30))
    elif [ "$upload" -ge 20 ]; then
        score=$((score + 20))
    elif [ "$upload" -ge 10 ]; then
        score=$((score + 10))
    fi
    
    # Ping score (max 30 points)
    if [ "$ping" -le 20 ]; then
        score=$((score + 30))
    elif [ "$ping" -le 50 ]; then
        score=$((score + 20))
    elif [ "$ping" -le 100 ]; then
        score=$((score + 10))
    fi
    
    # Rating based on score
    if [ "$score" -ge 80 ]; then
        echo -e "${GREEN}${BOLD}Excellent${NC} (Score: $score/100)"
    elif [ "$score" -ge 60 ]; then
        echo -e "${CYAN}${BOLD}Good${NC} (Score: $score/100)"
    elif [ "$score" -ge 40 ]; then
        echo -e "${YELLOW}${BOLD}Fair${NC} (Score: $score/100)"
    else
        echo -e "${RED}${BOLD}Poor${NC} (Score: $score/100)"
    fi
}

log_result() {
    local service="$1"
    local ping="$2"
    local download="$3"
    local upload="$4"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    mkdir -p "$LOG_DIR"
    
    echo "$timestamp | $service | Ping: $ping ms | Down: $download Mbps | Up: $upload Mbps" >> "$LOG_FILE"
}

show_history() {
    echo -e "${CYAN}${BOLD}[*] Speed Test History${NC}"
    echo
    
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${YELLOW}No history available${NC}"
        return
    fi
    
    echo -e "${DIM}Last 10 tests:${NC}"
    echo
    
    tail -n 10 "$LOG_FILE" | while IFS='|' read -r timestamp service ping download upload; do
        echo -e "${CYAN}$timestamp${NC}"
        echo -e "  Service: $service"
        echo -e "  $ping | $download | $upload"
        echo
    done
}

test_bandwidth() {
    echo -e "${CYAN}${BOLD}[*] Bandwidth Test${NC}"
    echo -e "${DIM}Testing real download speed...${NC}"
    echo
    
    local test_url="http://speedtest.tele2.net/10MB.zip"
    local test_file="/tmp/speedtest_download.tmp"
    
    echo -e "${CYAN}[*] Downloading 10MB test file...${NC}"
    
    # Download with progress and measure speed
    local start_time=$(date +%s.%N)
    
    curl -# -o "$test_file" "$test_url" 2>&1 | while IFS= read -r line; do
        if [[ "$line" =~ ^# ]]; then
            printf "\r${CYAN}Progress: ${line}${NC}"
        fi
    done
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    local file_size=$(stat -c%s "$test_file" 2>/dev/null || echo "0")
    
    if [ "$file_size" -gt 0 ]; then
        # Calculate speed in Mbps
        local bytes_per_sec=$(echo "$file_size / $duration" | bc)
        local mbps=$(echo "scale=2; $bytes_per_sec * 8 / 1000000" | bc)
        
        echo
        echo -e "${GREEN}✓ Download complete${NC}"
        echo -e "  • Speed: ${GREEN}${BOLD}${mbps} Mbps${NC}"
        echo -e "  • Time: ${duration} seconds"
    else
        echo
        echo -e "${RED}✗ Download failed${NC}"
    fi
    
    rm -f "$test_file"
    echo
}

show_network_info() {
    echo -e "${CYAN}${BOLD}[*] Network Information${NC}"
    echo
    
    # Get active interface
    local interface=$(ip route | grep default | awk '{print $5}' | head -1)
    
    if [ -n "$interface" ]; then
        echo -e "${YELLOW}Active Interface:${NC} $interface"
        
        # Get IP addresses
        local ipv4=$(ip -4 addr show "$interface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
        local ipv6=$(ip -6 addr show "$interface" | grep -oP '(?<=inet6\s)[0-9a-f:]+' | head -1)
        
        echo -e "${YELLOW}Local IPv4:${NC} $ipv4"
        [ -n "$ipv6" ] && echo -e "${YELLOW}Local IPv6:${NC} $ipv6"
        
        # Get public IP
        echo -ne "${YELLOW}Public IPv4:${NC} "
        local public_ip=$(curl -s -4 ifconfig.me 2>/dev/null)
        if [ -n "$public_ip" ]; then
            echo "$public_ip"
        else
            echo "Unable to determine"
        fi
        
        # Get gateway
        local gateway=$(ip route | grep default | awk '{print $3}' | head -1)
        echo -e "${YELLOW}Gateway:${NC} $gateway"
        
        # Get DNS servers
        echo -e "${YELLOW}DNS Servers:${NC}"
        grep "nameserver" /etc/resolv.conf | awk '{print "  • " $2}'
    fi
    
    echo
}

quick_test() {
    show_banner
    show_network_info
    test_ping
    test_speedtest_cli
}

full_test() {
    show_banner
    show_network_info
    test_ping
    test_speedtest_cli
    test_fast_cli
    test_bandwidth
}

show_menu() {
    show_banner
    
    echo -e "${YELLOW}${BOLD}Available Tests:${NC}"
    echo
    echo -e "  ${GREEN}1)${NC} Quick Test (Ping + Speedtest)"
    echo -e "  ${GREEN}2)${NC} Full Test (All tests)"
    echo -e "  ${GREEN}3)${NC} Ping Test Only"
    echo -e "  ${GREEN}4)${NC} Speedtest Only"
    echo -e "  ${GREEN}5)${NC} Bandwidth Test Only"
    echo -e "  ${GREEN}6)${NC} Network Information"
    echo -e "  ${GREEN}7)${NC} View History"
    echo -e "  ${GREEN}q)${NC} Quit"
    echo
    echo -e "${DIM}────────────────────────────────────────────────────────${NC}"
}

# Main execution
main() {
    mkdir -p "$LOG_DIR"
    check_dependencies
    
    # If arguments provided, run non-interactive
    if [ $# -gt 0 ]; then
        case "$1" in
            -q|--quick)
                quick_test
                ;;
            -f|--full)
                full_test
                ;;
            -p|--ping)
                show_banner
                test_ping
                ;;
            -s|--speed)
                show_banner
                test_speedtest_cli
                ;;
            -b|--bandwidth)
                show_banner
                test_bandwidth
                ;;
            -i|--info)
                show_banner
                show_network_info
                ;;
            -h|--history)
                show_banner
                show_history
                ;;
            --help)
                echo "NetSpeed - Network Speed Testing Tool"
                echo
                echo "Usage: $0 [OPTIONS]"
                echo
                echo "Options:"
                echo "  -q, --quick       Quick test (ping + speedtest)"
                echo "  -f, --full        Full test (all tests)"
                echo "  -p, --ping        Ping test only"
                echo "  -s, --speed       Speedtest only"
                echo "  -b, --bandwidth   Bandwidth test only"
                echo "  -i, --info        Network information"
                echo "  -h, --history     View test history"
                echo "  --help            Show this help"
                echo
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
        exit 0
    fi
    
    # Interactive menu
    while true; do
        show_menu
        read -p "$(echo -e ${CYAN}Select option:${NC} )" -r choice
        echo
        
        case $choice in
            1)
                quick_test
                ;;
            2)
                full_test
                ;;
            3)
                show_banner
                test_ping
                ;;
            4)
                show_banner
                test_speedtest_cli
                ;;
            5)
                show_banner
                test_bandwidth
                ;;
            6)
                show_banner
                show_network_info
                ;;
            7)
                show_banner
                show_history
                ;;
            q|Q)
                echo -e "${GREEN}Thanks for using NetSpeed!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
        
        echo
        read -p "$(echo -e ${CYAN}Press Enter to continue...${NC})" -r
    done
}

# Run main
main "$@"
