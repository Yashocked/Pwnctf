#!/usr/bin/env bash
# build.sh — Termux/Android-native binary compilation
# Position Independent Executable (PIE) is MANDATORY on Android
# This script generates multiple difficulty tiers for training
set -e

echo "[*] Pwnctf Binary Build System (Termux/Android)"
echo "==============================================="
echo ""

if [ ! -f vuln.cpp ]; then
    echo "[-] ERROR: vuln.cpp not found in current directory!"
    exit 1
fi

echo "[*] Detected architecture: $(uname -m)"
echo "[*] Using compiler: $(clang++ --version | head -1)"
echo ""

# Key Android/Termux notes:
# - PIE (Position Independent Executable) is FORCED by Android OS
# - We DO NOT use -no-pie; it will cause linker errors on Android
# - Stack canaries (-fstack-protector*) work fine on ARM64
# - execstack (-z execstack) disables NX bit (makes ROP easier)

echo "[*] Compiling vuln_easy (baseline: no canary, execstack enabled)..."
clang++ -fno-stack-protector -z execstack -g -o vuln_easy vuln.cpp
echo "    [+] vuln_easy created"

echo "[*] Compiling vuln_nopie (intermediate: no canary)..."
clang++ -fno-stack-protector -g -o vuln_nopie vuln.cpp
echo "    [+] vuln_nopie created"

echo "[*] Compiling vuln_canary (moderate: stack canary enabled)..."
clang++ -fstack-protector -g -o vuln_canary vuln.cpp
echo "    [+] vuln_canary created"

echo "[*] Compiling vuln_full (hardened: full protections)..."
clang++ -fstack-protector-all -g -o vuln_full vuln.cpp
echo "    [+] vuln_full created"

echo ""
echo "[+] BUILD SUCCESSFUL!"
echo ""
echo "Generated binaries:"
echo "  - vuln_easy   : No protections (easiest)"
echo "  - vuln_nopie  : No canary, but PIE (Android default)"
echo "  - vuln_canary : Stack canary enabled"
echo "  - vuln_full   : Full hardening (most difficult)"
echo ""
echo "Verify protections with:"
echo "  $ checksec --file=vuln_easy"
echo "  $ checksec --file=vuln_full"
echo ""
