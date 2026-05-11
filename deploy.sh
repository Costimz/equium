#!/usr/bin/env bash
# deploy.sh: one-shot setup for equium-miner on any Linux box (no GPU needed).
# Usage: bash deploy.sh <RPC_HTTPS_URL> [KEYPAIR_JSON]
#
# RPC_HTTPS_URL  - Helius or other Solana RPC, e.g.
#                  https://mainnet.helius-rpc.com/?api-key=YOUR_KEY
# KEYPAIR_JSON   - optional: paste the contents of an existing keypair JSON
#                  array (64 numbers). If omitted, a new wallet is generated.

set -euo pipefail

RPC_URL="${1:-}"
KEYPAIR_IMPORT="${2:-}"

if [[ -z "$RPC_URL" ]]; then
    echo "Usage: bash deploy.sh <https://rpc-url> [keypair-json-array]"
    exit 1
fi

REPO_DIR="$HOME/equium"
KEYPAIR_PATH="$HOME/.config/solana/id.json"

# ── 1. Rust ────────────────────────────────────────────────────────────────────
if ! command -v cargo &>/dev/null; then
    echo "[1/5] Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "[1/5] Rust already installed ($(rustc --version))"
    source "$HOME/.cargo/env" 2>/dev/null || true
fi

# ── 2. System deps ────────────────────────────────────────────────────────────
echo "[2/5] Checking system deps..."
if command -v apt-get &>/dev/null; then
    apt-get update -qq && apt-get install -y -qq build-essential pkg-config libssl-dev curl git 2>/dev/null
fi

# ── 3. Clone / update repo ────────────────────────────────────────────────────
echo "[3/5] Cloning repo..."
if [[ -d "$REPO_DIR/.git" ]]; then
    git -C "$REPO_DIR" pull --ff-only
else
    git clone https://github.com/HannaPrints/equium.git "$REPO_DIR"
fi
cd "$REPO_DIR"

# ── 4. Build ──────────────────────────────────────────────────────────────────
echo "[4/5] Building equium-miner (this takes a few minutes)..."
cargo build -p equium-cli-miner --release 2>&1
echo "  Build complete."

# ── 5. Wallet ─────────────────────────────────────────────────────────────────
echo "[5/5] Setting up wallet..."
mkdir -p "$(dirname "$KEYPAIR_PATH")"

if [[ -n "$KEYPAIR_IMPORT" ]]; then
    echo "$KEYPAIR_IMPORT" > "$KEYPAIR_PATH"
    chmod 600 "$KEYPAIR_PATH"
    echo "  Imported existing keypair."
elif [[ ! -f "$KEYPAIR_PATH" ]]; then
    # Install solana-keygen if needed
    if ! command -v solana-keygen &>/dev/null; then
        sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)" -- --no-modify-path
        export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
    fi
    solana-keygen new --no-bip39-passphrase --outfile "$KEYPAIR_PATH"
else
    echo "  Existing keypair found at $KEYPAIR_PATH"
fi

# Print public key
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
PUBKEY=$(solana-keygen pubkey "$KEYPAIR_PATH" 2>/dev/null || python3 -c "
import json, base64, hashlib, struct
with open('$KEYPAIR_PATH') as f:
    kp = json.load(f)
priv = bytes(kp[:32])
# derive pubkey via ed25519 (rough display only)
print('(install solana-keygen for pubkey)')
" 2>/dev/null || echo "unknown")

# ── Write start script ────────────────────────────────────────────────────────
cat > "$REPO_DIR/start-miner.sh" <<SCRIPT
#!/usr/bin/env bash
cd "\$(dirname "\$0")"
source "\$HOME/.cargo/env" 2>/dev/null || true
export PATH="\$HOME/.local/share/solana/install/active_release/bin:\$PATH"
exec ./target/release/equium-miner \\
    --rpc-url "$RPC_URL" \\
    --keypair "$KEYPAIR_PATH" \\
    "\$@"
SCRIPT
chmod +x "$REPO_DIR/start-miner.sh"

echo ""
echo "════════════════════════════════════════════════════════"
echo " Setup complete!"
echo ""
echo " Wallet:  $PUBKEY"
echo " Keypair: $KEYPAIR_PATH"
echo ""
echo " Fund this address with a small amount of SOL for fees"
echo " (~0.01 SOL is plenty to start)."
echo ""
echo " To start mining:"
echo "   bash $REPO_DIR/start-miner.sh"
echo ""
echo " To run in the background (tmux):"
echo "   tmux new -s equium"
echo "   bash $REPO_DIR/start-miner.sh"
echo "   # Ctrl+B then D to detach"
echo "════════════════════════════════════════════════════════"
