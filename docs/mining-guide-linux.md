# Equium ($EQM) Mining Guide — Linux CLI

## Prerequisites

A Solana RPC URL from a provider such as [Helius](https://helius.dev) or [Alchemy](https://alchemy.com).

---

## Step 1: Install Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

---

## Step 2: Install System Dependencies

```bash
sudo apt update
sudo apt install -y build-essential pkg-config libssl-dev
```

---

## Step 3: Clone and Build the Miner

```bash
git clone https://github.com/HannaPrints/equium
cd equium
cargo build -p equium-cli-miner --release
```

The binary will be created at `./target/release/equium-miner`.

---

## Step 4: Generate a Solana Wallet

> **Important:** Save the seed phrase shown after running this — it is the only way to recover your wallet.

```bash
solana-keygen new -o ~/.config/solana/eqm.json
```

Fund this wallet with approximately **0.02 SOL** to cover transaction fees.

---

## Step 5: Start Mining

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

---

## Running in the Background (tmux)

To keep the miner running after closing your terminal:

```bash
tmux new -s equium
./target/release/equium-miner --keypair ~/.config/solana/eqm.json --rpc-url YOUR_RPC_URL
```

Press `Ctrl+B` then `D` to detach. Reconnect anytime with:

```bash
tmux attach -t equium
```
