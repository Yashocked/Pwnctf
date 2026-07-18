# Pwnctf 🚀

[![License: MIT](https://shields.io)](https://opensource.org)
[![Supported OS: Termux & Linux](https://shields.io)](#)
[![Tech Stack: C++ & Python](https://shields.io)](#)

**Pwnctf** is a lightweight, all-in-one binary exploitation (Pwn) practice toolkit and development framework tailored for CTF (*Capture The Flag*) players. It is fully optimized to run natively on Termux/Android and Linux systems.

This repository provides:
- Multi-vulnerability testing binary (`vuln.cpp`) with 4 exploitation challenges
- Compiler scripts with **Android-compatible security mitigations** (no `-no-pie` on ARM64)
- Full-featured Python `pwntools` exploit templates with **Termux/ARM64 support**
- Native C++ exploitation library with dynamic symbol resolution
- Production-grade Docker deployment for CTF challenge hosting

---

## 📁 Repository Blueprint

```text
├── vuln.cpp                 # Multi-vulnerability practice target binary (4 bug classes)
├── build.sh                 # Compilation automation (Android Termux compatible - clang++, no -no-pie)
├── exploit_template.py      # Full-featured pwntools boilerplate with Termux/ARM64 support
├── pwn_helper.hpp           # Header-only mini "pwntools" engine written in native C++
├── exploit.cpp              # Reference exploit written in C++ using pwn_helper.hpp
├── setup_termux.sh          # Dependency environment installer for Termux (binary wheels only)
├── Dockerfile               # Production-grade socat sandbox deployment container
├── docker-compose.yml       # Local orchestration for sandbox hosting & resource limiting
├── .gitignore               # Strict path exclusions (guards flags and binary artifacts)
└── README.md                # This file
```

---

## 🎯 Target Playground: `vuln.cpp`

The target executable implements an interactive menu specifically crafted to simulate four major architectural software security vulnerabilities for progressive training:

1. **Stack Buffer Overflow:** Uses an unbounded string processing function (`unsafe_gets`) to easily trigger instruction pointer overwrites.
2. **Format String Vulnerability:** Passes raw runtime user inputs directly into `printf()` without a structural format specifier (`%s`), enabling arbitrary memory leaks and pointer writes.
3. **Integer Overflow to Heap Overflow:** Forces mathematical signed integer limits to bypass size constraint verifications, creating an asymmetric buffer limit for heap memory allocations.
4. **Use-After-Free (UAF):** Preserves dangling references to a cluster memory block after executing a `free()` call, enabling post-deallocation data manipulation.

---

## 🚀 Quick Start Guide (Termux Android Native)

### 1. Environment Deployment (Android Termux)

Initialize the development toolkit with Termux-optimized dependencies (**binary wheels only** to prevent compilation errors):

```bash
chmod +x setup_termux.sh build.sh
./setup_termux.sh          # Installs clang, gdb, python3, pwntools (binary wheels), ropgadget, ropper
./build.sh                 # Compiles vuln.cpp into FOUR tiers (Android/ARM64 compatible)
```

**What `setup_termux.sh` does:**
- Updates Termux package manager
- Installs core compilation toolchain (clang, binutils)
- **Upgrades pip for binary wheel support** (critical for psutil compatibility)
- **Installs pwntools with `--only-binary :all:`** (prevents "platform android not supported" error)
- Installs ROPgadget and ropper for gadget hunting
- Installs tmux for GDB debugging support
- Provides installation verification checklist

**Binary Tiers Generated (Termux Android):**
- `vuln_easy` — No stack canary, execstack enabled (baseline exploitation)
- `vuln_nopie` — No stack canary (intermediate difficulty)
- `vuln_canary` — Stack canary enabled (moderate protection)
- `vuln_full` — Full hardening protections (PIE+canary+NX on ARM64)

Verify protections:
```bash
checksec --file=vuln_easy
checksec --file=vuln_full
```

### 2. Interactive GDB Debugging on Termux (TMUX Required)

Run exploit with automatic GDB attachment in split tmux window:

```bash
# First, start tmux session (only once per session)
tmux new-session -d -s work

# Then run exploit with GDB mode
python3 exploit_template.py gdb
```

The template auto-detects TMUX environment and opens GDB in a right-split window for real-time debugging on ARM64 Android.

### 3. Local Process Execution

Attack the local binary without debugging:

```bash
python3 exploit_template.py          # Default: local process mode
```

### 4. Remote Server Exploitation

Connect to a remote CTF challenge server:

```bash
python3 exploit_template.py remote   # Connects to HOST:PORT configured in script
```

Edit `exploit_template.py` to change `HOST` and `PORT` for your specific CTF challenge.

### 5. Pure C++ Exploitation (No Python)

Compile and run the native C++ exploit:

```bash
# Compile (Termux uses clang++ via g++ alias)
clang++ -std=c++17 -o exploit exploit.cpp

# Local attack
./exploit

# Remote attack against CTF server
./exploit remote 127.0.0.1 1337
```

---

## 🛠️ Exploit Developer References

### Python Template Configuration (`exploit_template.py`) — Termux Optimized

The framework provides **full-featured exploitation routines** with Termux/Android support:

```python
# Termux GDB Integration (auto-detects TMUX)
if "TMUX" in os.environ:
    context.terminal = ['tmux', 'splitw', '-h']

# Architecture-agnostic packing (works on ARM64 & x86_64)
context.binary = elf = ELF("./vuln_easy", checksec=False)
context.log_level = "info"

def start():
    if args.REMOTE or "remote" in sys.argv:
        return remote(HOST, PORT)
    elif args.GDB or "gdb" in sys.argv:
        return gdb.debug([BINARY], gdbscript=GDB_SCRIPT)
    return process([BINARY])
```

**Built-in Helpers (Termux-Compatible):**

| Function | Purpose | Termux Notes |
| :--- | :--- | :--- |
| `exploit_stack_overflow()` | ret2win attack with dynamic symbol resolution | ✅ Full ARM64 support |
| `exploit_format_string()` | Format string leak & write automation | ✅ Full ARM64 support |
| `exploit_ret2libc()` | ROP chain construction + system("/bin/sh") | ✅ Full ARM64 support |
| `leak_addr(io, prompt, label)` | Extract leaked addresses | ✅ ARM64-aware parsing |
| `find_offset_cyclic(pattern_length)` | Interactive offset discovery with manual input | ✅ Termux GDB compatible |

**Example: Finding Buffer Offset on Termux**
```python
# Run interactively with GDB to find crash offset
offset = find_offset_cyclic()
log.success(f"Offset found: {offset}")
```

### C++ Helper Engine Architecture (`pwn_helper.hpp`)

A modular `namespace pwn` abstraction built purely upon POSIX system calls (`poll`, `fork`, `pipe`, `socket`) to execute stable exploit flows natively within C++. Works on ARM64 and x86_64 architectures.

#### Data Packaging & Manipulation (Little Endian)
* `pwn::p32(uint32_t v)` / `pwn::p64(uint64_t v)` – Serializes integers into little-endian byte streams (auto-sized for architecture).
* `pwn::u32(string s)` / `pwn::u64(string s)` – Deserializes little-endian byte inputs into integers.
* `pwn::cyclic(size_t length)` – Generates low-collision sequences to compute memory buffer crash offsets.

#### The `pwn::Tube` Connection Handler

| Method Wrapper | Underlying Subsystem / Behavior | Termux Support |
| :--- | :--- | :--- |
| `connect_remote(host, port)` | Establishes a remote socket interface connection (`getaddrinfo` / `connect`). | ✅ Full support |
| `spawn_local(path)` | Spawns a local execution binary child process over managed IPC communication pipes (`fork` / `dup2` / `execl`). | ✅ Full support |
| `send(data)` / `sendline(data)` | Writes raw string structures directly to the outgoing target input file descriptor. | ✅ Full support |
| `recv(n)` | Reads a stream containing up to `n` data bytes from the input descriptor. | ✅ Full support |
| `recvuntil(delim)` | Progressively polls single-byte structures until matching a specified delimiter. | ✅ Full support |
| `interactive()` | Handshakes I/O operations between standard paths using persistent multiplexing (`poll`). | ✅ Full support |

---

## ⚠️ Critical Architectural Gotcha: Stack Alignment

During local execution testing of this framework, an essential architectural behavior was verified regarding x86_64 Calling Conventions and `system()` calls (also applies to ARM64):

When overwriting a saved return pointer directly to a `win()` or shell-spawning function, **the stack pointer (RSP/SP) can become misaligned** compared to a standard branch sequence initialization.

* **The Symptom:** The target execution transfers successfully (e.g., standard print logs execute), but nested routines like `system("/bin/sh")` will silently drop input context or crash inside libc.
* **The Remediating Fix:** Always introduce an empty standalone `ret` instruction gadget into your ROP string array *prior* to injecting the target execution address. This increments the stack pointer and re-aligns it.

```python
# Rectifying stack parity before calling system()
payload = b"A" * OFFSET
payload += elf.pack(ret_gadget)   # Pad stack pointer alignment (Mandatory)
payload += elf.pack(win_addr)     # Transfer execution flow cleanly
```

**Note on Android/ARM64:** ARM64 has different stack alignment requirements than x86_64 (16-byte vs 8-byte). The template and `exploit.cpp` use dynamic symbol resolution and `elf.pack()` to handle architecture-specific packing automatically. The build script (`build.sh`) and exploit code work transparently on both architectures.

---

## 🐳 Isolated Server Deployment (Docker + Socat)

The repository provides production-grade deployment tools mirroring contemporary CTF event hosting standards (such as CTFd and pwn.college) to isolate applications within restricted security sandboxes.

**Note:** Docker deployment requires a Linux host. Termux on Android cannot run Docker natively, but you can use this on a Linux server to host CTF challenges that your Termux exploits target.

### Testing the Sandbox Infrastructure Locally (Linux)

Spin up an isolated container cluster using Docker Compose:
```bash
docker compose up --build
```

In an external alternate console shell, establish your pipeline network connection using standard Netcat tools:
```bash
nc localhost 1337
```

### Production Deployment Strategy

Build your target stack using runtime environment build arguments to inject dynamic infrastructure flags without persistent tracking:
```bash
docker build --build-arg FLAG="CTF{your_real_secret_flag}" -t pwn-challenge .
```

Deploy the isolated challenge background daemon with explicit memory allocations, cpu quotas, and active processing resource boundaries to prevent fork-bomb or DoS stability issues:
```bash
docker run -d -p 1337:1337 --restart unless-stopped \
  --memory=256m --pids-limit=50 --cpus=0.5 \
  pwn-challenge
```

### 🔒 Operational Security Compliance Checkpoints
1. **Repository Hygiene:** The configuration maps path rules inside `.gitignore` to prevent tracking runtime secrets, environment configurations, and artifacts (`flag.txt`, `.env`, core dumps).
2. **Privilege Isolation:** The Docker build uses explicit `USER ctf` separation structures to prevent arbitrary root shell escalation if underlying software flaws are exploited.
3. **Build Arguments:** Always utilize `--build-arg FLAG=...` during runtime builds to prevent saving the true target flag into your public repository cache history.

---

## 🔧 Termux-Specific Notes & Features

### Binary Wheel Installation (No Compilation Errors)

**What changed:** The original setup tried to compile `psutil` from source, which fails on Android because psutil requires Linux interfaces not available on Android.

**Solution:** `setup_termux.sh` now uses `pip install --only-binary :all: pwntools` to force installation of pre-compiled binary wheels.

**Result:** ✅ Zero "platform android is not supported" errors

### Why No `-no-pie`?

Android enforces **Position Independent Executable (PIE)** at the OS level (required for all ARM64 binaries). The updated `build.sh` uses `clang++` (Termux's native compiler) and **does NOT use `-no-pie`** flags. Instead, it relies on architecture-agnostic compilation flags (`-fstack-protector*`) that are fully compatible with ARM64 PIE binaries.

### GDB on Termux

Use TMUX for debugging split windows:
```bash
# Install tmux (one-time)
pkg install tmux

# Start a tmux session
tmux new-session -d -s work

# Run exploit with GDB (opens in split window)
python3 exploit_template.py gdb
```

**Note:** GDB runs natively on ARM64 Termux with full breakpoint and symbol support.

### Binary Compatibility

All generated binaries run natively on ARM64 Android devices without cross-compilation. The `build.sh` automatically detects your architecture and compiles for it.

### Architecture Detection

The `exploit_template.py` and `exploit.cpp` automatically detect your architecture (ARM64 or x86_64) and adjust:
- Pointer packing (p32 vs p64)
- Gadget search patterns
- Stack alignment logic
- Register naming in GDB output

### Optional: pwninit (Rust-based tool)

**Status:** Available but optional. The `setup_termux.sh` will try to install it, but if `cargo` is unavailable on your Termux setup, it gracefully skips it.

```bash
# If you want to use pwninit for binary setup:
cargo install pwninit
```

**What pwninit does:** Auto-extracts symbols, libc, and generates exploit templates from binary+libc pairs. Not required for this toolkit but useful for CTF challenges that provide libc.so.

---

## ✅ Feature Compatibility Matrix

| Feature | Termux ARM64 | Linux x86_64 | Notes |
| :--- | :--- | :--- | :--- |
| Binary compilation | ✅ | ✅ | clang++, no -no-pie on ARM64 |
| Python exploits | ✅ | ✅ | Full pwntools support via binary wheels |
| C++ exploits | ✅ | ✅ | Dynamic symbol resolution works on both |
| GDB debugging | ✅ | ✅ | Requires tmux on Termux |
| Remote CTF connection | ✅ | ✅ | Full socket support |
| Format string exploit | ✅ | ✅ | Architecture-agnostic |
| ROP gadget search | ✅ | ✅ | ropgadget / ropper installed |
| Docker deployment | ❌ | ✅ | Termux cannot run Docker; use as client only |
| pwninit (optional) | ⚠️ | ✅ | Requires cargo; optional for toolkit |
| ROPgadget | ✅ | ✅ | Full binary wheel support |
| Ropper | ✅ | ✅ | Full binary wheel support |

---

## 📋 Installation Troubleshooting

### psutil Compilation Error
**Error:** `platform android is not supported`

**Solution:** Already fixed in `setup_termux.sh` via `--only-binary :all:`. If you see this, ensure:
```bash
pip install --upgrade pip setuptools wheel
pip install --only-binary :all: psutil pwntools
```

### GDB Not Attaching
**Error:** GDB doesn't split window or attach

**Solution:** Ensure tmux is running:
```bash
pkg install tmux
tmux new-session -d -s work
python3 exploit_template.py gdb  # Now it should work
```

### Binary Permission Denied
**Error:** `Permission denied: './vuln_easy'`

**Solution:** Make build script executable:
```bash
chmod +x build.sh
./build.sh
```

### checksec Not Found
**Error:** `checksec: command not found`

**Solution:** It's part of pwntools but may not be in PATH:
```bash
python -m pwntools.checksec ./vuln_easy
# Or install via apt:
pip install checksec
```

---

## 🎓 Learning Resources

1. **Stack Overflow Basics:** Start with `vuln_easy` and `exploit_stack_overflow()`
2. **Format Strings:** Move to `vuln_easy` and `exploit_format_string()`
3. **ROP Chains:** Use `vuln_canary` and `exploit_ret2libc()`
4. **UAF & Heap:** Advanced exercises on `vuln_full`

---

Maintained and Developed 💻 By Yashocked 🚀

**Last Updated:** 2026-07-18 | **Fully Termux/Android Compatible** ✅
