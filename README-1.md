# Pwn CTF Toolkit (C++ edition, Termux-ready)

Isi paket ini:

| File | Fungsi |
|---|---|
| `vuln.cpp` | Target latihan — punya 4 bug class: stack overflow, format string, heap overflow, use-after-free |
| `build.sh` | Compile `vuln.cpp` dengan level proteksi berbeda (easy s/d full protection) |
| `exploit_template.py` | Template exploit pakai **pwntools** (Python) — paling umum dipakai di CTF |
| `pwn_helper.hpp` | Mini "pwntools" versi C++ — kalau mau nulis exploit murni di C++ |
| `exploit.cpp` | Contoh pakai `pwn_helper.hpp` buat solve `vuln.cpp` |
| `setup_termux.sh` | Install semua tools yang dibutuhin di Termux |

## Quick start (Termux)

```bash
chmod +x setup_termux.sh build.sh
./setup_termux.sh          # install gcc, gdb, pwntools, ropgadget, dll
./build.sh                 # compile vuln.cpp jadi beberapa versi proteksi
checksec --file=vuln_easy  # cek proteksi binary
```

Exploit pakai Python (rekomendasi, paling gampang & powerful):
```bash
python3 exploit_template.py          # local
python3 exploit_template.py remote   # connect ke server soal
python3 exploit_template.py gdb      # local + auto attach gdb
```

Exploit pakai C++ (kalau tim lo emang mau full C++):
```bash
g++ -std=c++17 -o exploit exploit.cpp
./exploit                       # local
./exploit remote 1.2.3.4 1337   # remote
```

## ⚠️ Gotcha penting: stack alignment pas ret2win manggil system()

Ini kejadian nyata pas nge-test toolkit ini, jadi penting dicatet:

Kalau fungsi target (`win()`) manggil `system()`/`execve()` di dalemnya, dan lo
loncat ke situ dengan **overwrite return address doang**, RSP jadi misaligned
(beda parity dibanding kalau `win()` dipanggil normal lewat `call`).

Akibatnya **bukan crash langsung** — lebih jahat dari itu: shell tetap
ke-spawn dan keliatan berhasil (`[win] WOW kamu berhasil...` muncul), tapi
command yang lo kirim abis itu **gak pernah dieksekusi**. Programnya baru
crash belakangan pas fungsi itu selesai. Ini gampang bikin lo mikir exploit-nya
gagal padahal cuma kurang satu langkah.

**Fix:** sisipin satu gadget `ret` polos sebelum alamat target, buat re-align
stack ke kelipatan 16 yang bener:

```python
payload = b'A' * OFFSET
payload += p64(ret_gadget)   # <-- alignment fix, WAJIB kalau target manggil system()
payload += p64(win_addr)
```

Cari gadget `ret` polos: `objdump -d chall | grep 'ret$' | head -1` atau
`ROPgadget --binary chall --only "ret"`.

Kalau target fungsi cuma `puts()`/print doang (gak manggil `system`), biasanya
gak butuh fix ini.

## Deploy sebagai soal CTF beneran (Docker + socat)

File tambahan buat ini: `Dockerfile`, `docker-compose.yml`, `.gitignore`.

Ini pattern standar yang dipake hampir semua platform CTF (CTFd, pwn.college, dll):
binary di-compile di dalam container, dijalanin sebagai user non-root, terus
di-expose lewat `socat` biar orang bisa connect via `nc host port` kayak
biasanya soal pwn.

### Test lokal

```bash
docker compose up --build
# di terminal lain:
nc localhost 1337
```

### Deploy beneran (VPS/server)

```bash
docker build --build-arg FLAG="CTF{flag_asli_lo}" -t pwn-challenge .
docker run -d -p 1337:1337 --restart unless-stopped \
  --memory=256m --pids-limit=50 --cpus=0.5 \
  pwn-challenge
```

### ⚠️ Hal penting sebelum publish ke GitHub

1. **Jangan commit flag asli.** `.gitignore` udah exclude `flag.txt`, dan
   Dockerfile pakai `ARG FLAG` (bukan hardcoded) — isi flag asli cuma pas
   `docker build --build-arg FLAG=...`, gak pernah masuk ke git history.
2. **Jalanin sebagai non-root** (`USER ctf` di Dockerfile) — best practice,
   biar kalau ada bug tak terduga di luar exploit yang dimaksud, dampaknya
   kebatas ke user biasa, bukan root container.
3. **Batasi resource** (`mem_limit`, `pids_limit`, `cpus`) — soal pwn publik
   gampang di-abuse buat fork bomb atau DoS kalau gak dibatasi.
4. **Ganti flag placeholder** di `docker-compose.yml` sebelum share ke orang
   lain, dan idealnya generate ulang tiap kali di-redeploy biar gak ke-cache
   di layer Docker lama.
5. Kalau soal-nya bakal diakses banyak orang bersamaan, `fork` di socat command
   udah handle multi-koneksi (tiap `nc` dapet instance proses baru).

## Alur kerja standar pas dapet soal pwn

1. **Recon binary**
   ```bash
   file chall
   checksec --file=chall     # cek NX, PIE, Canary, RELRO
   strings chall | less      # cari string mencurigakan (system, /bin/sh, dll)
   objdump -d chall          # liat disassembly
   ```

2. **Identifikasi bug class**
   - Ada `gets()`, `strcpy()`, `read()` tanpa bound check → **stack overflow**
   - `printf(user_input)` tanpa format specifier → **format string**
   - `malloc`/`free` dengan logic aneh → **heap bug** (UAF, double free, overflow)

3. **Cari offset overflow** (kalau stack overflow)
   ```python
   from pwn import *
   io = process('./chall')
   io.sendline(cyclic(200))
   io.wait()
   core = io.corefile
   offset = cyclic_find(core.read(core.esp, 4))   # 32-bit
   # atau untuk 64-bit, cek $rsp/$rbp di gdb pas crash
   ```

4. **Bikin payload** sesuai bug (lihat contoh di `exploit_template.py`):
   - **ret2win**: overwrite return address ke fungsi `win()`/`shell()`
   - **ret2libc**: leak alamat libc function → hitung base libc → panggil `system("/bin/sh")`
   - **ROP chain**: kalau NX aktif, gak bisa jalanin shellcode di stack, jadi harus chaining gadget

5. **Debug pakai gdb + pwndbg/gef** (install: `pkg install gdb`, lalu clone pwndbg/gef manual)
   ```bash
   gdb ./chall
   (gdb) break main
   (gdb) run
   (gdb) x/20xg $rsp    # liat stack
   ```

## Command cheat sheet

```bash
# Cari ROP gadget
ROPgadget --binary chall --only "pop|ret"
ropper --file chall --search "pop rdi"

# Cari offset "/bin/sh" di libc
python3 -c "from pwn import *; libc=ELF('libc.so.6'); print(hex(next(libc.search(b'/bin/sh'))))"

# Patch binary pakai libc soal (biar exploit akurat local)
pwninit   # auto detect binary+libc, patch otomatis (kalau keinstall)

# One-liner attach gdb dari pwntools
gdb.attach(io, gdbscript="break *0x401234\ncontinue")
```

## Catatan Termux

- `checksec` butuh `file` + `objdump`: `pkg install file binutils`
- `gdb.debug()` di pwntools butuh `gdbserver`, biasanya udah ikut paket `gdb`
- Kalau gdb/pwndbg berat di HP, alternatif: exploit dev di Termux, tapi **debugging** pindah ke laptop/PC kalau ada, baru balik ke Termux buat final run ke server soal.
- ARM64 Termux kadang beda behavior dikit dibanding x86_64 CTF server — pastiin architecture binary soal sesuai (`file chall`), jangan asumsi sama kayak device lo.

## Bug class yang ada di `vuln.cpp` (buat latihan)

1. **Stack overflow** — `gets()` di buffer 64 byte, gampang overwrite return address
2. **Format string** — `printf(buf)` langsung tanpa `%s`, bisa leak stack / write-what-where pakai `%n`
3. **Heap overflow** — integer overflow di `malloc(size)`, size negatif jadi `size_t` raksasa
4. **Use-after-free** — chunk di-`free()` tapi pointer masih dipakai buat `read()`

Latihan urutan: solve #1 dulu (paling gampang), baru #2, #3, #4.
