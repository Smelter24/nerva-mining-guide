# Nerva (XNV) Solo Mining — Complete Guide

A comprehensive, step-by-step guide to mining Nerva (XNV) — a CPU-only, privacy-focused cryptocurrency with no pool support. Every miner runs a full node, making it one of the most decentralized PoW networks.

---

## Table of Contents

- [What is Nerva?](#what-is-nerva)
- [Why Mine Nerva?](#why-mine-nerva)
- [System Requirements](#system-requirements)
- [Step 1: Download Nerva Binaries](#step-1-download-nerva-binaries)
- [Step 2: QuickSync (Optional but Recommended)](#step-2-quicksync-optional-but-recommended)
- [Step 3: Start the Daemon and Sync](#step-3-start-the-daemon-and-sync)
- [Step 4: Create a Wallet](#step-4-create-a-wallet)
- [Step 5: Start Solo Mining](#step-5-start-solo-mining)
- [Step 6: Set Up Block Notifications](#step-6-set-up-block-notifications)
- [Monitoring Your Node](#monitoring-your-node)
- [Multi-Node Setup](#multi-node-setup)
- [Thread Allocation Strategy](#thread-allocation-strategy)
- [Estimating Earnings](#estimating-earnings)
- [Restarting Without Re-Syncing](#restarting-without-re-syncing)
- [LMDB Snapshot (Backup)](#lmdb-snapshot-backup)
- [Critical Pitfalls](#critical-pitfalls)
- [Useful Links](#useful-links)

---

## What is Nerva?

| Property | Value |
|----------|-------|
| **Ticker** | XNV |
| **Algorithm** | Cryptonight Adaptive (CPU-only, no GPU, no ASIC) |
| **Block Time** | 60 seconds |
| **Block Reward** | 0.3 XNV |
| **Max Supply** | ~18.5M XNV (then 1% annual tail emission) |
| **Consensus** | Proof of Work |
| **Pool Support** | None — solo mining only |
| **Privacy** | CryptoNote-based (Monero fork), all transactions private |
| **Mainnet** | Live since 2018 |
| **Latest Release** | v0.2.2.0 "Legacy Reborn" (May 28, 2026) |
| **Exchanges** | NonKyc, KlingEx, NoirTrade |
| **Price** | ~$0.17 (June 2026) |
| **Market Cap** | ~$3.2M |

---

## Why Mine Nerva?

1. **CPU-only** — No ASIC or GPU competition. Your CPU is the mining hardware.
2. **No pools** — Every miner is a full node. Highly decentralized by design.
3. **Privacy niche** — CryptoNote-based privacy always has demand.
4. **8-year track record** — Running since 2018, not a fly-by-night project.
5. **Active development** — v0.2.2.0 released May 2026, hard fork 13 planned Q3 2026.
6. **Real exchanges** — Listed on 3 exchanges with actual volume.

---

## System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | Any modern x86_64 | AMD EPYC / Ryzen (high core count) |
| **RAM** | 4GB | 8GB+ |
| **Storage** | 20GB SSD | 50GB+ SSD (blockchain grows over time) |
| **OS** | Linux (x86_64) | Ubuntu 22.04+ / Debian 12+ |
| **Network** | Stable connection | Unmetered bandwidth |

**Note:** Nerva does NOT need huge pages (unlike RandomX mining). CryptoNight Adaptive has different memory requirements.

---

## Step 1: Download Nerva Binaries

```bash
# Navigate to install directory
cd /opt

# Download latest release (v0.2.2.0)
wget https://github.com/nerva-project/nerva/releases/download/v0.2.2.0/nerva-linux-x86_64-v0.2.2.0.tar.bz2

# Extract
tar xjf nerva-linux-x86_64-v0.2.2.0.tar.bz2

# Enter directory
cd nerva-linux-x86_64-v0.2.2.0
```

**Binaries included:**
- `nervad` — Full node daemon (handles blockchain, P2P, mining)
- `nerva-wallet-cli` — Wallet CLI (create wallets, check balance, send XNV)

---

## Step 2: QuickSync (Optional but Recommended)

QuickSync contains pre-verified block hashes that speed up block verification during P2P sync. It does NOT load a pre-synced blockchain — you still sync via P2P, but verification is ~52% faster.

```bash
# Download quicksync file (129MB)
wget https://github.com/nerva-project/nerva/releases/download/v0.2.2.0/quicksync.raw

# Copy to the SAME directory as nervad binary
cp quicksync.raw /opt/nerva-linux-x86_64-v0.2.2.0/
```

### QuickSync Pitfalls

1. **Location matters** — `quicksync.raw` MUST be in the same directory as the `nervad` binary. If it's elsewhere, nervad silently ignores it and starts normal P2P sync from block 0. No error message.

2. **Not instant** — QuickSync speeds up verification, not download. Full sync of 4.25M blocks still takes 2-4 hours depending on network speed and CPU.

3. **No confirmation log** — There is no log message that confirms quicksync loaded. If sync speed is ~250 blocks/sec, quicksync is NOT loaded. Working quicksync shows ~500-700 blocks/sec.

---

## Step 3: Start the Daemon and Sync

### 3a. Start nervad (WITHOUT mining)

**Critical: Do NOT mine during sync.** Mining during sync hogs all CPU, leaving nothing for sync. Result: sync crawls at ~250 blocks/sec instead of ~500-700 blocks/sec.

```bash
# Kill any existing nervad
pkill -9 nervad

# Remove old blockchain data if restarting from scratch
rm -rf /root/.nerva/lmdb /root/.nerva/*.bin

# Start daemon with optimized sync flags
./nervad \
  --data-dir /root/.nerva \
  --non-interactive \
  --quicksync quicksync.raw \
  --fast-block-sync 1 \
  --prep-blocks-threads 512 \
  --block-sync-size 1000 \
  --db-sync-mode fastest:async:500000000bytes \
  --limit-rate 50000 \
  --db-readers 254
```

**Flag explanations:**
| Flag | Purpose |
|------|---------|
| `--data-dir /root/.nerva` | Blockchain data location |
| `--non-interactive` | Run without interactive console |
| `--quicksync quicksync.raw` | Use pre-verified block hashes |
| `--fast-block-sync 1` | Enable fast block verification |
| `--prep-blocks-threads 512` | Threads for block preparation |
| `--block-sync-size 1000` | Blocks per sync batch |
| `--db-sync-mode fastest:async:500000000bytes` | Aggressive DB sync |
| `--limit-rate 50000` | Network rate limit (KB/s) |
| `--db-readers 254` | Max concurrent DB readers |

### 3b. Monitor sync progress

```bash
# Check last 5 lines of log
tail -5 /root/.nerva/nerva.log
```

**What to look for:**
- `Synced XXXXX/4253XXX (X%, XXXXX left)` — Still syncing
- `SYNCHRONIZED OK` — Ready to mine

### 3c. Sync speed reference (AMD EPYC 9755, 512 threads)

| Sync Mode | Speed | Time (4.25M blocks) |
|-----------|-------|---------------------|
| With quicksync + no mining | ~700 blocks/sec | ~1.7 hours |
| Without quicksync + no mining | ~570 blocks/sec | ~2.1 hours |
| With mining during sync | ~250 blocks/sec | ~4.7 hours |

**CPU usage during sync:** ~120-150% (light, most work is I/O + verification)

---

## Step 4: Create a Wallet

Wait for `SYNCHRONIZED OK` before creating a wallet.

```bash
# Connect wallet CLI to running daemon
./nerva-wallet-cli
```

**Inside the wallet CLI:**

```
# Create a new wallet
> create_new_wallet my-wallet

# Set password (can be empty for no password)
Enter password: ****

# Choose language
Language: 1 (English)

# Your wallet address (starts with NV...)
> address

# Your 25-word mnemonic seed — BACKUP THIS SECURELY!
> seed

# Save the wallet
> save

# Exit
> exit
```

### Wallet file location

The wallet file is saved in the current directory as `my-wallet` (or whatever name you chose). Back up both the wallet file AND the 25-word seed.

### Checking balance

```bash
./nerva-wallet-cli --daemon-address 127.0.0.1:17565
> open_wallet my-wallet
> balance
> refresh
> balance
```

**Important:** Nerva is a privacy coin. The block explorer CANNOT look up wallet addresses or balances. You must use `nerva-wallet-cli` connected to a synced node to check your balance.

---

## Step 5: Start Solo Mining

Nerva has NO pool support. Every miner runs a full node and mines solo.

### Option A: Mine from daemon

```bash
./nervad --data-dir /root/.nerva --non-interactive \
  --start-mining NV_ADDRESS --mining-threads 500
```

### Option B: Mine from wallet (daemon must be running separately)

```bash
# Terminal 1: Start daemon
./nervad --data-dir /root/.nerva --non-interactive

# Terminal 2: Connect wallet and mine
./nerva-wallet-cli
> start_mining 500
> stop_mining
```

### Verify mining is active

```bash
# Check nervad is using CPU
top -bn1 | grep nervad

# Check thread count
ps -T -p $(pgrep nervad | head -1) | wc -l

# Check log for mining activity
tail -f /root/.nerva/nerva.log
```

---

## Step 6: Set Up Block Notifications

nervad doesn't have webhooks or callbacks for block events. Use a bash script to monitor the log file.

### Create the notification script

```bash
cat > /root/nerva-block-notifier.sh << 'EOF'
#!/bin/bash
# Nerva Block Found Notifier
# Sends Telegram notification when a new block is found

BOT_TOKEN="YOUR_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"
LOG_FILE="/root/.nerva/nerva.log"

# Get the last known block count on startup
LAST_COUNT=$(grep -c "Found block" "$LOG_FILE" 2>/dev/null || echo 0)

echo "Monitoring nerva log... (known blocks: $LAST_COUNT)"

tail -Fn0 "$LOG_FILE" | while read line; do
  if echo "$line" | grep -q "Found block"; then
    HEIGHT=$(echo "$line" | grep -oP 'height: \K[0-9]+')
    NEW_COUNT=$(grep -c "Found block" "$LOG_FILE" 2>/dev/null || echo 0)
    
    # Only notify for NEW blocks (skip existing on startup)
    if [ "$NEW_COUNT" -gt "$LAST_COUNT" ]; then
      curl -s "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        -d "text=Nerva Block Found!
Height: ${HEIGHT}
Reward: 0.3 XNV
Time: $(date '+%H:%M:%S %d/%m/%Y')" \
        -d "parse_mode=HTML" > /dev/null
      LAST_COUNT=$NEW_COUNT
    fi
  fi
done
EOF

chmod +x /root/nerva-block-notifier.sh
```

### Run as background process

```bash
nohup bash /root/nerva-block-notifier.sh > /dev/null 2>&1 &
```

**Resource usage:** ~1-2MB RAM, near-zero CPU (idle waiting on log).

### Create a systemd service (optional but recommended)

```bash
cat > /etc/systemd/system/nerva-notifier.service << EOF
[Unit]
Description=Nerva Block Notifier
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash /root/nerva-block-notifier.sh
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable nerva-notifier
systemctl start nerva-notifier
```

---

## Monitoring Your Node

### Check sync status

```bash
curl -s http://127.0.0.1:17566/json_rpc -X POST \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":"0","method":"get_info"}' | python3 -m json.tool
```

**Key fields:**
- `height` — Current block height
- `difficulty` — Current network difficulty
- `target` — Target block time in seconds (60)
- `outgoing_connections_count` — Connected peers
- Network hashrate ≈ `difficulty / target` (e.g., 30,814,741 / 60 = ~514 KH/s)

### Check blocks found

```bash
grep -c "Found block" /root/.nerva/nerva.log
```

**Important:** The log pattern is case-sensitive. Use `"Found block"` (title case), NOT `"block found"` (lowercase).

### Daemon CLI commands

```bash
# Connect to running daemon
./nerva-wallet-cli --daemon-address 127.0.0.1:17565

# Inside daemon:
status          # sync status
diff            # current difficulty
print_pl        # peer list
start_mining N  # start mining with N threads
stop_mining     # stop mining
```

**Note:** `mining_status` RPC method does NOT exist on nervad. There is no way to query current hashrate via RPC. nervad also does NOT log hashrate. You can only estimate hashrate from block discovery rate over time.

---

## Multi-Node Setup

Running multiple nodes on different servers increases your total hashrate and chances of finding blocks.

### SSH-based monitoring script

```bash
#!/bin/bash
# nerva-multi-node-monitor.sh
# Monitors multiple Nerva nodes via SSH

check_node() {
  local name="$1"
  shift
  local result
  result=$(ssh -o ConnectTimeout=15 -o ServerAliveInterval=5 "$@" '
    FOUND=$(grep -c "Found block" /root/.nerva/nerva.log 2>/dev/null || echo 0)
    INFO=$(curl -s -m 8 http://127.0.0.1:17566/json_rpc \
      -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"get_info\"}" \
      -H "Content-Type: application/json" 2>/dev/null)
    if [ -n "$INFO" ] && echo "$INFO" | grep -q "height"; then
      HEIGHT=$(echo "$INFO" | grep -o "\"height\": *[0-9]*" | head -1 | grep -o "[0-9]*$")
      PEERS=$(echo "$INFO" | grep -o "\"outgoing_connections_count\": *[0-9]*" | head -1 | grep -o "[0-9]*$")
      THREADS=$(ps -T -p $(pgrep nervad | head -1) 2>/dev/null | tail -n +2 | wc -l)
      echo "OK|$FOUND|$HEIGHT|$PEERS|$THREADS"
    else
      echo "DOWN|$FOUND|-|-|-"
    fi
  ' 2>/dev/null)
  
  if [ -z "$result" ]; then
    echo "ERR|$name|-|-|-|-"
  else
    echo "$result|$name"
  fi
}

# Configure your nodes here:
NODE1=$(check_node "Node1" user@host1)
NODE2=$(check_node "Node2" user@host2)
NODE3=$(check_node "Node3" user@host3)

for RESULT in "$NODE1" "$NODE2" "$NODE3"; do
  STATUS=$(echo "$RESULT" | cut -d'|' -f1)
  FOUND=$(echo "$RESULT" | cut -d'|' -f2)
  HEIGHT=$(echo "$RESULT" | cut -d'|' -f3)
  PEERS=$(echo "$RESULT" | cut -d'|' -f4)
  THREADS=$(echo "$RESULT" | cut -d'|' -f5)
  NAME=$(echo "$RESULT" | cut -d'|' -f6)
  
  if [ "$STATUS" = "OK" ]; then
    echo "OK  $NAME: height=$HEIGHT peers=$PEERS threads=$THREADS blocks=$FOUND"
  elif [ "$STATUS" = "DOWN" ]; then
    echo "DOWN  $NAME: daemon down (had $FOUND blocks)"
  else
    echo "ERR  $NAME: unreachable"
  fi
done
```

---

## Thread Allocation Strategy

| Total Cores | During Sync | After Sync | Notes |
|-------------|-------------|------------|-------|
| 4-8 | All for sync | total - 2 for mining | Leave 2 for system |
| 16-32 | All for sync | total - 2 for mining | |
| 64 | All for sync | total - 2 for mining | |
| 128+ | All for sync | total - 12 for mining | Leave room for P2P + SSH |
| 512 (2x EPYC 9755) | All for sync | 500 for mining | Leave 12 for system |

**Rule:** ALWAYS sync first with all cores, THEN mine. Never split CPU between sync and mining.

### L3 Cache Consideration

CryptoNight Adaptive needs ~2MB L3 cache per thread. Check your CPU's L3 cache:

```bash
lscpu | grep "L3 cache"
```

**Example:** EPYC 9755 has 384MB L3 → optimal max 192 threads. Running 500 threads = 2.6x oversubscribed → cache thrashing → lower per-thread hashrate. May be better to run fewer threads at higher per-thread rate. Test both configurations.

---

## Estimating Earnings

```bash
# Get network stats
curl -s http://127.0.0.1:17566/json_rpc -X POST \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":"0","method":"get_info"}' | python3 -c "
import json, sys
data = json.load(sys.stdin)['result']
diff = data['difficulty']
height = data['height']
hashrate = diff / 60
print(f'Height: {height}')
print(f'Difficulty: {diff:,}')
print(f'Network hashrate: {hashrate:,.0f} H/s ({hashrate/1000:.1f} KH/s)')
print(f'Daily emission: 432 XNV (1440 blocks x 0.3)')
"
```

### Earnings formula

```
Your share = your_hashrate / network_hashrate
Daily XNV = 432 x your_share
Daily USD = daily_XNV x price
```

### Example calculation (512-core EPYC 9755)

```
Estimated hashrate: ~2,880 H/s (500 threads x ~5.76 H/s)
Network hashrate: ~500 KH/s
Share: 2,880 / 500,000 = 0.576%
Daily: 432 x 0.00576 = ~2.5 XNV = ~$0.41
```

**Important:** Cryptonight Adaptive gives ~5-10 H/s per core (much lower than SHA-256d). Solo mining means you only earn when YOU find a block (0.3 XNV each). At low hashrate relative to network, blocks may be very infrequent (hours or days between finds).

---

## Restarting Without Re-Syncing

nervad stores the blockchain in LMDB database at `/root/.nerva/lmdb/`. Restarting only needs to verify the last few blocks (~1-3 seconds).

```bash
# Safe restart (keeps blockchain data):
# Find nervad PID (don't use pkill -f nervad, it may kill SSH!)
NID=$(ps aux | grep nervad | grep -v grep | awk '{print $2}' | head -1)
kill -9 $NID
sleep 2

# Restart with new settings
./nervad --data-dir /root/.nerva --non-interactive \
  --start-mining NV_ADDRESS --mining-threads 500

# "SYNCHRONIZED OK" appears within seconds
# Mining resumes immediately
```

### Destructive restart (re-syncs from scratch)

```bash
rm -rf /root/.nerva/lmdb
./nervad ...
# Must sync 4.25M blocks again (~2 hours)
```

---

## LMDB Snapshot (Backup)

After syncing, create a snapshot of the blockchain database for future use. This lets you skip the 2-4 hour sync on new instances.

```bash
# Create snapshot (after nervad is stopped)
cd /root/.nerva
tar czf /root/nerva-lmdb-snapshot.tar.gz lmdb/

# Restore on new instance
mkdir -p /root/.nerva
cd /root/.nerva
tar xzf /root/nerva-lmdb-snapshot.tar.gz

# Start nervad — "SYNCHRONIZED OK" in seconds
./nervad --data-dir /root/.nerva --non-interactive \
  --start-mining NV_ADDRESS --mining-threads 500
```

---

## Critical Pitfalls

### 1. NO POOL SUPPORT
Solo mining only. Every miner must run a full node. There are no mining pools for Nerva.

### 2. Don't Mine During Sync
Mining during sync uses all CPU for mining, leaving nothing for sync. Sync crawls at ~250 blocks/sec instead of ~700 blocks/sec.

### 3. QuickSync File Location
`quicksync.raw` MUST be in the same directory as the `nervad` binary. If it's elsewhere, nervad silently ignores it. No error message.

### 4. QuickSync Is Not Instant
Speeds up verification, not download. Full sync still takes 2-4 hours.

### 5. Low Hashrate Per Core
Cryptonight Adaptive gives ~5-10 H/s per core. Don't expect high hashrates like SHA-256d or RandomX.

### 6. Solo = Infrequent Blocks
At low network share, may go hours or days without finding a block. Each block = 0.3 XNV.

### 7. No Hashrate Reporting
nervad does NOT report hashrate via RPC or logs. You can only estimate from blocks found over time.

### 8. Log Pattern Is Case-Sensitive
```bash
# WRONG — returns 0 even when blocks are found:
grep -c 'block found' /root/.nerva/nerva.log

# CORRECT:
grep -c 'Found block' /root/.nerva/nerva.log
```

### 9. pkill Danger
`pkill -f nervad` may kill your SSH session if it matches the grep pattern. Use:
```bash
ps aux | grep nervad | grep -v grep | awk '{print $2}' | xargs kill
```

### 10. CryptoNight Adaptive vs RandomX
Nerva uses CryptoNight Adaptive, NOT RandomX. This means:
- No huge pages needed
- Different hashrate characteristics
- Different optimization strategies

### 11. Privacy Coin = No Explorer Balance Check
The block explorer CANNOT look up wallet addresses or balances. You must use `nerva-wallet-cli` connected to a synced node.

### 12. Peer Connection Instability
Peer connections may drop frequently. Daemon auto-reconnects but sync may stall. Use `--add-priority-node` for known stable peers:
```bash
./nervad --add-priority-node IP:PORT
```

---

## Useful Links

| Resource | URL |
|----------|-----|
| Website | https://nerva.one |
| Explorer | https://explorer.nerva.one |
| Node Map | https://map.nerva.one |
| Wiki | https://docs.nerva.one |
| Mining Calculator | https://nerva.one/nerva-mining-profitability-calculator/ |
| Discord | https://discord.gg/ufysfvcFwe |
| Telegram | https://t.me/NervaCrypto |
| GitHub | https://github.com/nerva-project/nerva |
| Downloads | https://nerva.one/#downloads |

---

## License

This guide is provided as-is for educational purposes. Nerva is open-source software (GitHub: nerva-project/nerva).

---

*Last updated: June 2026*
