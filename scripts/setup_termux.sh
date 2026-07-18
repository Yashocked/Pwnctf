#!/usr/bin/env bash
# setup_termux.sh — Complete Termux/Android environment setup
# Fully Termux-compatible with binary wheel installation (no compilation errors)
set -e

echo "[*] Termux/Android Setup for Pwnctf"
echo "====================================="
echo ""

# Step 1: Verify Termux storage access
echo "[*] Checking Termux storage access..."
if [ ! -d "$HOME" ]; then
    echo "[!] WARNING: Home directory not found. Run: termux-setup-storage"
fi

# Step 2: Update package manager
echo "[*] Updating package repositories..."
pkg update -y
pkg upgrade -y

# Step 3: Install core compilation tools
echo "[*] Installing compiler toolchain..."
pkg install -y clang make

# Step 4: Install Python and essential tools
echo "[*] Installing Python and binutils..."
pkg install -y python binutils gdb file

# Step 5: Upgrade pip to latest (CRITICAL for binary wheel support)
echo "[*] Upgrading pip, setuptools, and wheel..."
python -m pip install --upgrade pip setuptools wheel

# Step 6a: Pre-install capstone independently (CRITICAL FIX for Android)
# This resolves the "no matching distributions" error
echo "[*] Pre-installing capstone (dependency of pwntools)..."
pip install --only-binary :all: capstone 2>/dev/null || {
    echo "[!] Binary capstone unavailable, attempting from source..."
    pip install capstone || echo "[!] capstone installation failed - proceeding anyway"
}

# Step 6b: Install pwntools with BINARY WHEELS ONLY (no compilation)
# This prevents psutil "platform android is not supported" error
echo "[*] Installing pwntools (binary wheels only - no compile)..."
pip install --only-binary :all: pwntools

if [ $? -ne 0 ]; then
    echo "[!] pwntools binary wheel installation failed. Trying alternative approach..."
    pip install pwntools || echo "[!] pwntools installation incomplete"
fi

# Step 7: Install ROP gadget searching tools (binary wheels)
echo "[*] Installing ROPgadget and ropper..."
pip install --only-binary :all: ropgadget ropper 2>/dev/null || pip install ropgadget ropper

# Step 8: Optional: pwninit (Rust-based, optional)
echo "[*] Installing pwninit (optional)..."
if command -v cargo &> /dev/null; then
    cargo install pwninit --quiet 2>/dev/null || echo "[!] pwninit install skipped (cargo may be unavailable)"
else
    echo "[!] cargo not found, skipping pwninit"
fi

# Step 9: Install tmux for GDB debugging (HIGHLY RECOMMENDED)
echo "[*] Installing tmux for GDB debugging..."
pkg install -y tmux

# Step 10: Verify installations
echo ""
echo "[+] Installation complete! Verifying..."
echo ""
echo "Checking compiler: $(clang --version | head -1)"
echo "Checking Python: $(python --version)"
echo "Checking pip packages:"
pip show pwntools 2>/dev/null | grep Version || echo "  [!] pwntools not found"
pip show capstone 2>/dev/null | grep Version || echo "  [!] capstone not found"
pip show ropgadget 2>/dev/null | grep Version || echo "  [!] ropgadget not found"

echo ""
echo "[+] SETUP COMPLETE!"
echo ""
echo "========== QUICK START ==========="
echo "1. Build vulnerable binary:"
echo "   $ chmod +x build.sh && ./build.sh"
echo ""
echo "2. Verify binary protections:"
echo "   $ checksec --file=vuln_easy"
echo ""
echo "3. Run exploit locally:"
echo "   $ python exploit_template.py"
echo ""
echo "4. Debug with GDB (in tmux session):"
echo "   $ tmux new-session -d -s work"
echo "   $ python exploit_template.py gdb"
echo ""
echo "5. Exploit remote CTF server:"
echo "   $ python exploit_template.py remote"
echo ""
echo "========== IMPORTANT NOTES ==========="
echo "[!] First run might take time as pip downloads binary wheels"
echo "[!] If capstone/psutil fails, run: pip install --only-binary :all: capstone psutil"
echo "[!] For GDB: ensure tmux is running when using gdb.debug()"
echo "[!] ARM64 architecture is fully supported (auto-detected)"
echo "[!] On Termux, some pure-Python dependencies may be slower than compiled versions"
echo ""
