#!/usr/bin/env bash
# build.sh — compile vuln.cpp dengan beberapa level proteksi buat latihan
set -e

echo "[*] Compiling vuln_easy (no canary, no PIE, execstack) ..."
g++ -no-pie -fno-stack-protector -z execstack -o vuln_easy vuln.cpp

echo "[*] Compiling vuln_nopie (no canary, no PIE)..."
g++ -no-pie -fno-stack-protector -o vuln_nopie vuln.cpp

echo "[*] Compiling vuln_canary (canary on, no PIE)..."
g++ -no-pie -o vuln_canary vuln.cpp

echo "[*] Compiling vuln_full (semua proteksi default modern gcc: PIE+canary+NX+RELRO)..."
g++ -o vuln_full vuln.cpp

echo "[+] Done. Binaries: vuln_easy, vuln_nopie, vuln_canary, vuln_full"
echo "[+] Cek proteksi masing-masing pakai: checksec --file=<binary>"
