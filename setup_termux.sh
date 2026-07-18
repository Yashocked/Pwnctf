#!/usr/bin/env bash
# setup_termux.sh — install semua tools pwn CTF di Termux
set -e

echo "[*] Update repo..."
pkg update -y && pkg upgrade -y

echo "[*] Install compiler & basic tools..."
pkg install -y clang python git binutils gdb

echo "[*] Install pip & pwntools..."
pip install --upgrade pip
pip install pwntools

echo "[*] Install ROPgadget & ropper (cari ROP gadget)..."
pip install ropgadget ropper

echo "[*] Install pwninit (opsional, auto-setup soal pwn dari binary+libc)..."
pkg install -y rust
cargo install pwninit || echo "[!] pwninit gagal install, skip (opsional)"

echo ""
echo "[+] Selesai! Tools yang keinstall:"
echo "    - g++/clang (compile C++)"
echo "    - gdb (debugging)"
echo "    - python3 + pwntools (exploit dev)"
echo "    - ROPgadget / ropper (cari ROP gadget)"
echo ""
echo "[!] Catatan Termux:"
echo "    - checksec pwntools kadang butuh 'file' & 'objdump', pastikan ada:"
echo "        pkg install file binutils"
echo "    - gdb di Termux ARM64 kadang perlu 'termux-exec' & permission storage."
echo "    - Kalau mau gdb attach otomatis dari pwntools (gdb.debug), pastikan"
echo "      gdbserver ikut keinstall: pkg install gdb"
