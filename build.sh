#!/usr/bin/env bash
# build.sh — Versi koreksi khusus Android Termux
set -e

if [ ! -f vuln.cpp ]; then
    echo "[-] Error: File vuln.cpp tidak ditemukan!"
    exit 1
fi

# Di Android, bendera "-no-pie" DILARANG oleh sistem operasi.
# Kita gunakan compiler bawaan Termux (clang++ melalui alias g++) dengan pengaman yang dimatikan.

echo "[*] Compiling vuln_easy (no canary, execstack) ..."
g++ -fno-stack-protector -z execstack -o vuln_easy vuln.cpp

echo "[*] Compiling vuln_nopie (no canary) ..."
g++ -fno-stack-protector -o vuln_nopie vuln.cpp

echo "[*] Compiling vuln_canary (canary on) ..."
g++ -fstack-protector -o vuln_canary vuln.cpp

echo "[*] Compiling vuln_full (Proteksi penuh Android modern) ..."
g++ -fstack-protector-all -o vuln_full vuln.cpp

echo "[+] Selesai! Semua biner berhasil dibuat."
