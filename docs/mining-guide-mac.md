# Equium ($EQM) Mining Guide — macOS CLI

## Prerequisites

- A Mac running macOS 12 (Monterey) or later
- A Solana RPC URL from a provider such as [Helius](https://helius.dev) or [Alchemy](https://alchemy.com)

---

## Step 1: Install Xcode Command Line Tools

These provide the C compiler and build tools required:

```bash
xcode-select --install
```

A dialog will appear — click **Install** and wait for it to finish.

---

## Step 2: Install Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
```

---

## Step 3: Install Solana CLI Tools

Required to generate and manage your wallet:

```bash
sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
```

Add the export line to your shell profile so it persists across sessions:

```bash
# For zsh (default on modern Macs):
echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

---

## Step 4: Clone and Build the Miner

```bash
git clone https://github.com/HannaPrints/equium
cd equium
cargo build -p equium-cli-miner --release
```

The binary will be created at `./target/release/equium-miner`.

---

## Step 5: Generate a Solana Wallet

> **Important:** Save the seed phrase shown after running this — it is the only way to recover your wallet.

```bash
solana-keygen new -o ~/.config/solana/eqm.json
```

Fund this wallet with approximately **0.02 SOL** to cover transaction fees.

### Using an existing wallet (e.g. Phantom)

If you prefer to mine directly to an existing Phantom wallet:

1. Open Phantom → click your account → **⋯** → **Export Private Key**
2. Enter your password and copy the key
3. Run the following and paste your key when prompted:

```bash
python3 -c "
import json

ALPHA = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'

def b58decode(s):
    n = 0
    for c in s:
        n = n * 58 + ALPHA.index(c)
    out = []
    while n > 0:
        out.append(n & 0xff)
        n >>= 8
    for c in s:
        if c == '1': out.append(0)
        else: break
    return bytes(reversed(out))

pk = input('Paste Phantom private key: ').strip()
raw = b58decode(pk)
path = '$HOME/.config/solana/eqm.json'
with open(path, 'w') as f:
    json.dump(list(raw), f)
print('Saved to', path)
"
```

Verify it matches your Phantom address:

```bash
solana-keygen pubkey ~/.config/solana/eqm.json
```

---

## Step 6: Start Mining

Replace `YOUR_RPC_URL` with your actual Solana RPC URL:

```bash
./target/release/equium-miner \
  --keypair ~/.config/solana/eqm.json \
  --rpc-url YOUR_RPC_URL
```

---

## Optional Flags

| Flag | Description |
|---|---|
| `--threads N` | Number of CPU threads to use |
| `--max-blocks N` | Stop after N successfully mined blocks |
| `--cu-limit N` | Compute unit limit per transaction |

**Example with flags:**

```bash
./target/release/equium-miner \
  --keypair ~/.config/solana/eqm.json \
  --rpc-url YOUR_RPC_URL \
  --threads 4
```

> **Tip:** Apple Silicon Macs (M1/M2/M3/M4) have high single-core performance and are well-suited to Equihash mining. Use `--threads` set to your core count for best results (check with `sysctl -n hw.physicalcpu`).

---

## Running in the Background

To keep the miner running after closing your terminal, use a new Terminal window or tab, or run it via `nohup`:

```bash
nohup ./target/release/equium-miner \
  --keypair ~/.config/solana/eqm.json \
  --rpc-url YOUR_RPC_URL \
  > ~/equium-miner.log 2>&1 &
```

Check the log anytime with:

```bash
tail -f ~/equium-miner.log
```

Stop it with:

```bash
pkill equium-miner
```
