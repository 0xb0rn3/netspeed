# NetSpeed

```
╔══════════════════════════════════════════════════════════════╗
║              Network Speed & Quality Testing Tool            ║
║                        by 0xb0rn3                           ║
╚══════════════════════════════════════════════════════════════╝
```

A terminal-native network diagnostics and speed testing tool built for operators who live in the shell. NetSpeed wraps `speedtest-cli`, `fast-cli`, and raw curl-based bandwidth probing behind a clean, color-coded TUI — with persistent logging, ping quality grading, and a full alias library for daily workflow integration.

---

## Features

- **Multi-source speed testing** — Ookla (`speedtest-cli`) + Netflix CDN (`fast-cli`) + direct curl bandwidth probe
- **Ping latency grading** — tests Cloudflare, Google DNS, OpenDNS, and Quad9 with min/avg/max summary
- **Quality scoring engine** — composite 0–100 score weighted across download (40pts), upload (30pts), and latency (30pts)
- **Persistent test history** — all results logged to `~/.netspeed/speedtest_history.log`
- **Network interface info** — active interface, local IPv4/IPv6, public IP, gateway, and DNS servers
- **Interactive TUI menu** — clean numbered menu when you don't want flags
- **Non-interactive CLI mode** — fully scriptable for automation and cron jobs
- **Animated spinners** — braille-frame progress indicators; no frozen terminal anxiety
- **Shell alias library** — drop-in aliases and power functions for `zsh`/`bash`

---

## Installation

### One-liner (recommended)

```bash
mkdir -p ~/bin && \
curl -o ~/bin/netspeed https://raw.githubusercontent.com/0xb0rn3/netspeed/main/netspeed.sh && \
chmod +x ~/bin/netspeed && \
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc && \
source ~/.zshrc && \
echo 'alias speedtest="netspeed -q"' >> ~/.zshrc && \
echo 'alias st="netspeed -q"' >> ~/.zshrc && \
echo 'alias myip="curl -s ifconfig.me && echo"' >> ~/.zshrc && \
source ~/.zshrc && \
echo "✓ NetSpeed installed! Try: speedtest"
```

> **bash users:** replace `~/.zshrc` with `~/.bashrc`

### Manual install

```bash
git clone https://github.com/0xb0rn3/netspeed.git
cd netspeed

cp netspeed.sh ~/bin/netspeed
chmod +x ~/bin/netspeed

# Load aliases (optional but recommended)
echo "source $(pwd)/aliases.sh" >> ~/.zshrc
source ~/.zshrc
```

### Aliases only

```bash
curl -o ~/.netspeed_aliases https://raw.githubusercontent.com/0xb0rn3/netspeed/main/aliases.sh && \
echo 'source ~/.netspeed_aliases' >> ~/.zshrc && \
source ~/.zshrc
```

---

## Dependencies

| Dependency | Required | Purpose |
|---|---|---|
| `speedtest-cli` | **Yes** | Ookla speed test backend |
| `curl` | **Yes** | Bandwidth probe + public IP resolution |
| `ping` | **Yes** | Latency tests across multiple DNS servers |
| `iproute2` (`ip`, `ss`) | **Yes** | Interface enumeration and routing info |
| `fast-cli` (`fast`) | Optional | Netflix CDN speed test |
| `jq` | Optional | JSON output parsing for fast-cli |
| `bc` | Optional | Floating-point math in bandwidth calculations |
| `nmap` | Optional | Local network host scanning |
| `vnstat` | Optional | Historical bandwidth usage stats |
| `grc` | Optional | Colorized output for ping/traceroute/netstat |
| `nmcli` | Optional | WiFi signal strength info |

**Arch / Manjaro**
```bash
sudo pacman -S speedtest-cli curl iproute2
```

**Debian / Ubuntu**
```bash
sudo apt install speedtest-cli curl iproute2
```

**fast-cli (optional)**
```bash
sudo npm install -g fast-cli
```

> NetSpeed will auto-detect missing required dependencies on first run and offer to install them automatically.

---

## Usage

### Interactive menu

```bash
netspeed
```

```
  1) Quick Test (Ping + Speedtest)
  2) Full Test (All tests)
  3) Ping Test Only
  4) Speedtest Only
  5) Bandwidth Test Only
  6) Network Information
  7) View History
  q) Quit
```

### CLI flags

```
netspeed [OPTIONS]

  -q, --quick       Quick test: ping + Ookla speedtest
  -f, --full        Full suite: ping + Ookla + Netflix CDN + bandwidth probe
  -p, --ping        Ping latency test only
  -s, --speed       Ookla speedtest only
  -b, --bandwidth   Direct curl bandwidth probe only
  -i, --info        Network interface and IP information
  -h, --history     View last 10 test results from log
      --help        Show help
```

### Examples

```bash
netspeed -q          # Quick speed test
netspeed -f          # Full suite
netspeed -p          # Latency check across 4 DNS providers
netspeed -i          # Interface info, public IP, gateway, DNS
netspeed -h          # Tail the result log
```

---

## Aliases

Source `aliases.sh` to unlock a full set of shell shortcuts.

### NetSpeed shortcuts

| Alias | Command | Description |
|---|---|---|
| `speedtest` / `st` | `netspeed -q` | Quick speed test |
| `speedtest-full` / `stf` | `netspeed -f` | Full test suite |
| `pingtest` / `pt` | `netspeed -p` | Ping test only |
| `bandwidth` / `bw` | `netspeed -b` | Bandwidth probe |
| `netinfo` / `ni` | `netspeed -i` | Network info |
| `speedhistory` / `sth` | `netspeed -h` | View history |
| `netspeed-menu` | `netspeed` | Interactive menu |

### Network utility aliases

| Alias | Description |
|---|---|
| `myip` / `myip4` / `myip6` | Public IP (any / IPv4 / IPv6) |
| `myipinfo` | Full IP geolocation via ipinfo.io |
| `localip` / `localip6` | Local interface addresses |
| `interfaces` / `ifaces` | Interface list with addresses / link state |
| `connections` | Active sockets (`ss -tuln`) |
| `listening` | Listening ports only |
| `dns` / `dnsf` | Quick dig / full answer dig |
| `trace` / `trace4` / `trace6` | Traceroute (ICMP / IPv4 / IPv6) |
| `routes` / `route6` | IPv4 and IPv6 routing tables |
| `portscan` / `portscan-quick` | nmap service scan / fast scan on localhost |
| `openports` | All listening processes with PIDs via lsof |
| `fwstatus` / `fw6status` | iptables / ip6tables rule listing |
| `wifiinfo` / `wifistrength` | NetworkManager WiFi scan / connected AP |
| `flushdns` | Flush systemd-resolved cache |
| `dltest` | Raw curl download speed from Tele2 10MB endpoint |
| `netquality` | 20-ping average latency to 8.8.8.8 |
| `bandwidth-usage` / `bandwidth-daily` | vnstat live / daily stats |
| `ping1` / `ping8` / `pingg` | 5-ping to 1.1.1.1 / 8.8.8.8 / google.com |

### Shell functions

| Function | Signature | Description |
|---|---|---|
| `testhost` | `testhost <hostname>` | Runs ping + dig + traceroute against a target |
| `speedtest-url` | `speedtest-url <url>` | Measures download speed from an arbitrary URL |
| `portcheck` | `portcheck <host> <port>` | TCP port reachability check via `/dev/tcp` |
| `pingwatch` | `pingwatch [host]` | Continuous timestamped ping (default: 8.8.8.8) |
| `speedmonitor` | `speedmonitor [iface]` | Live RX/TX KB/s from `/sys/class/net` stats |
| `scan-network` | `scan-network [cidr]` | nmap ping sweep, default `192.168.1.0/24` |

---

## Quality Scoring

The scoring engine produces a 0–100 composite used in Ookla test output:

| Category | Max Points | Thresholds |
|---|---|---|
| Download | 40 | ≥100 Mbps → 40 · ≥50 → 30 · ≥25 → 20 · ≥10 → 10 |
| Upload | 30 | ≥50 Mbps → 30 · ≥20 → 20 · ≥10 → 10 |
| Ping | 30 | ≤20ms → 30 · ≤50ms → 20 · ≤100ms → 10 |

| Score | Rating |
|---|---|
| 80–100 | Excellent |
| 60–79 | Good |
| 40–59 | Fair |
| 0–39 | Poor |

---

## Ping Latency Grading

Each server result is individually color-coded in the terminal output:

| Latency | Grade |
|---|---|
| < 30ms | Excellent |
| 30–59ms | Good |
| 60–99ms | Fair |
| ≥ 100ms | Poor |

Servers tested: `1.1.1.1` (Cloudflare), `8.8.8.8` (Google DNS), `208.67.222.222` (OpenDNS), `9.9.9.9` (Quad9)

---

## Test History

All Ookla and fast-cli results are appended to `~/.netspeed/speedtest_history.log`:

```
2025-06-01 14:32:11 | Speedtest-CLI | Ping: 14 ms | Down: 487.32 Mbps | Up: 94.17 Mbps
2025-06-01 14:33:45 | Fast.com      | Ping: N/A   | Down: 461.00 Mbps | Up: 88.00 Mbps
```

```bash
netspeed -h                              # Last 10 entries via TUI
tail -f ~/.netspeed/speedtest_history.log  # Raw tail
```

---

## File Structure

```
netspeed/
├── netspeed.sh       # Main script
├── aliases.sh        # Shell aliases and utility functions
└── README.md

~/.netspeed/
└── speedtest_history.log   # Auto-created on first run
```

---

## License

MIT — use it, fork it, weaponize it.

---

*Built by [0xb0rn3](https://github.com/0xb0rn3)*
