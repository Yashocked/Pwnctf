#!/usr/bin/env bash
# build.sh — Termux/Android-native binary compilation
# Jalanin dari mana aja: ./scripts/build.sh atau (cd scripts && ./build.sh)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/../src/vuln.cpp"
BIN_DIR="$SCRIPT_DIR/../bin"

echo "[*] Pwnctf Binary Build System (Termux/Android)"
echo "==============================================="
echo ""

if [ ! -f "$SRC" ]; then
    echo "[-] ERROR: vuln.cpp not found at $SRC!"
    exit 1
fi

mkdir -p "$BIN_DIR"

echo "[*] Detected architecture: $(uname -m)"
echo "[*] Using compiler: $(clang++ --version | head -1)"
echo ""

echo "[*] Compiling vuln_easy (baseline: no canary, execstack enabled)..."
clang++ -fno-stack-protector -z execstack -g -o "$BIN_DIR/vuln_easy" "$SRC"
echo "    [+] vuln_easy created"

echo "[*] Compiling vuln_nopie (intermediate: no canary)..."
clang++ -fno-stack-protector -g -o "$BIN_DIR/vuln_nopie" "$SRC"
echo "    [+] vuln_nopie created"

echo "[*] Compiling vuln_canary (moderate: stack canary enabled)..."
clang++ -fstack-protector -g -o "$BIN_DIR/vuln_canary" "$SRC"
echo "    [+] vuln_canary created"

echo "[*] Compiling vuln_full (hardened: full protections)..."
clang++ -fstack-protector-all -g -o "$BIN_DIR/vuln_full" "$SRC"
echo "    [+] vuln_full created"

echo ""
echo "[+] BUILD SUCCESSFUL!"
echo ""
echo "Generated binaries (in bin/):"
echo "  - vuln_easy   : No protections (easiest)"
echo "  - vuln_nopie  : No canary, but PIE (Android default)"
echo "  - vuln_canary : Stack canary enabled"
echo "  - vuln_full   : Full hardening (most difficult)"
echo ""
