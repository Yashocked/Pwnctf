# Pwnctf 🚀

[![License: MIT](https://shields.io)](https://opensource.org)
[![Supported OS: Termux](https://shields.io)](#)

**Pwnctf** adalah sebuah *framework* dan *tool* pembantu pribadi yang dirancang khusus untuk mempercepat proses eksploitasi *binary* (Pwn) dalam kompetisi CTF (*Capture The Flag*). Proyek ini dibuat agar fleksibel dan dapat dijalankan langsung melalui perangkat Android menggunakan lingkungan **Termux**, maupun di Linux modern.

## ✨ Fitur Utama

- 📱 **Termux Native Support** – Dilengkapi dengan skrip otomatisasi untuk konfigurasi *environment* eksploitasi langsung di Android.
- 📦 **Dockerized Sandboxing** – Menyediakan konfigurasi Docker untuk mensimulasikan lingkungan server CTF secara terisolasi dan aman.
- 🛠️ **C++ Helper Library** – File `pwn_helper.hpp` menyediakan fungsi-fungsi esensial untuk berinteraksi dan menganalisis memori atau biner.
- 🐍 **Python Exploit Template** – *Boilerplate* skrip Python siap pakai untuk menulis *payload* eksploitasi tanpa harus mulai dari nol.

## 📁 Struktur Repositori

```text
├── .gitignore.txt           # Konfigurasi Git ignore
├── Dockerfile               # Konfigurasi kontainer untuk environment uji coba
├── docker-compose.yml       # Orkestrasi kontainer Docker
├── build.sh                 # Skrip otomatisasi untuk kompilasi biner
├── setup_termux.sh          # Skrip setup otomatis untuk pengguna Termux
├── pwn_helper.hpp           # Library pembantu berbasis C++
├── exploit.cpp              # Kode sumber program eksploitasi berbasis C++
├── exploit_template-1.py    # Template dasar skrip eksploitasi Python
├── vuln.cpp                 # Contoh program rentan (vulnerable binary) untuk simulasi
└── LICENSE                  # Lisensi proyek (MIT License)
```

## 🚀 Panduan Memulai

### 1. Penggunaan di Termux (Android)
Untuk mempersiapkan lingkungan kerja Anda di Termux, jalankan skrip setup berikut:
```bash
chmod +x setup_termux.sh
./setup_termux.sh
```

### 2. Menjalankan Lingkungan Simulasi (Docker)
Jika Anda ingin mencoba mengeksploitasi program target `vuln.cpp` di lingkungan lokal terisolasi:
```bash
# Membangun dan menjalankan kontainer
docker-compose up --build
```

### 3. Kompilasi Program
Gunakan skrip `build.sh` untuk melakukan kompilasi otomatis terhadap biner yang sedang dikembangkan:
```bash
chmod +x build.sh
./build.sh
```

## 🛠️ Tech Stack

- **Languages:** C++ (59%), Python (25.6%), Shell Script (9.1%)
- **Tools:** Docker, Termux, Git

## 📜 Lisensi

Proyek ini dilisensikan di bawah **MIT License**. Lihat file [LICENSE](LICENSE) untuk informasi lebih lanjut.

---
*Dikembangkan dengan 💻 oleh [Yashocked](https://github.com).*

