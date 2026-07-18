# Pwnctf 🚀

[![License: MIT](https://shields.io)](https://opensource.org)
[![Supported OS: Termux & Linux](https://shields.io)](#)
[![Tech Stack: C++ & Python](https://shields.io)](#)

**Pwnctf** is a lightweight, all-in-one binary exploitation (Pwn) practice toolkit and development framework tailored for CTF (*Capture The Flag*) players. It is fully optimized to run natively on **Android Termux** environments as well as traditional Linux systems.

This repository provides a multi-vulnerability testing binary (`vuln.cpp`), compiler scripts with **Android-compatible security mitigations**, a full-featured Python `pwntools` exploit boilerplate with Termux integration, and a standalone header-only C++ helper engine.

---

## 📁 Repository Blueprint

```text
├── vuln.cpp                 # Multi-vulnerability practice target binary (4 bug classes)
├── build.sh                 # Compilation automation (Android Termux compatible - no -no-pie)
├── exploit_template.py      # Full-featured pwntools boilerplate with Termux/ARM64 support
├── pwn_helper.hpp           # Header-only mini "pwntools" engine written in native C++
├── exploit.cpp              # Reference exploit written in C++ using pwn_helper.hpp
├── setup_termux.sh          # Dependency environment installer for Termux systems
├── Dockerfile               # Production-grade socat sandbox deployment container
├── docker-compose.yml       # Local orchestration for sandbox hosting & resource limiting
└── .gitignore               # Strict path exclusions (guards flags and binary artifacts)
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
Initialize the development toolkit with Termux-optimized dependencies:
```bash
chmod +x setup_termux.sh build.sh
./setup_termux.sh          # Provisions clang, gdb, python3, pwntools, ropgadget, and pwninit
./build.sh                 # Compiles vuln.cpp into FOUR tiers (Android/ARM64 compatible)
```

**Binary Tiers Generated (Termux Android):**
- `vuln_easy` — No stack canary, execstack enabled (baseline exploitation)
- `vuln_nopie` — No stack canary (intermediate difficulty)
- `vuln_canary` — Stack canary enabled (moderate protection)
- `vuln_full` — Full modern protections (PIE+canary+NX+RELRO on ARM64)

Verify protections:
```bash
checksec --file=vuln_easy
checksec --file=vuln_full
```

### 2. Interactive GDB Debugging on Termux (TMUX Required)
Run exploit with automatic GDB attachment in split tmux window:
```bash
# First, start tmux session
tmux new-session -d -s work

# Then run exploit with GDB mode
python3 exploit_template.py gdb
```

The template auto-detects TMUX environment and opens GDB in a right-split window.

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

### 5. Pure C++ Exploitation (No Python)
Compile and run the native C++ exploit:
```bash
g++ -std=c++17 -o exploit exploit.cpp
./exploit                       # Local attack
./exploit remote 127.0.0.1 1337 # Remote attack
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

| Function | Purpose |
| :--- | :--- |
| `exploit_stack_overflow()` | ret2win attack with dynamic symbol resolution |
| `exploit_format_string()` | Format string leak & write automation |
| `exploit_ret2libc()` | ROP chain construction + system("/bin/sh") |
| `leak_addr(io, prompt, label)` | Extract leaked addresses (ARM64-aware) |
| `find_offset_cyclic(pattern_length)` | Interactive offset discovery with Termux GDB |

**Example: Finding Buffer Offset on Termux**
```python
# Auto-detects crash, prompts for RIP/EIP value
offset = find_offset_cyclic()
log.success(f"Offset found: {offset}")
```

### C++ Helper Engine Architecture (`pwn_helper.hpp`)
A modular `namespace pwn` abstraction built purely upon Linux system calls (`poll`, `fork`, `pipe`, `socket`) to execute stable exploit flows natively within C++.

#### Data Packaging & Manipulation (Little Endian)
* `pwn::p32(uint32_t v)` / `pwn::p64(uint64_t v)` – Serializes integers into little-endian byte streams.
* `pwn::u32(string s)` / `pwn::u64(string s)` – Deserializes little-endian byte inputs into integers.
* `pwn::cyclic(size_t length)` – Generates low-collision sequences to compute memory buffer crash offsets.

#### The `pwn::Tube` Connection Handler

| Method Wrapper | Underlying Subsystem / Behavior |
| :--- | :--- |
| `connect_remote(host, port)` | Establishes a remote socket interface connection (`getaddrinfo` / `connect`). |
| `spawn_local(path)` | Spawns a local execution binary child process over managed IPC communication pipes (`fork` / `dup2` / `execl`). |
| `send(data)` / `sendline(data)` | Writes raw string structures directly to the outgoing target input file descriptor. |
| `recv(n)` | Reads a stream containing up to `n` data bytes from the input descriptor. |
| `recvuntil(delim)` | Progressively polls single-byte structures until matching a specified delimiter. |
| `interactive()` | Handshakes I/O operations between standard paths using persistent multiplexing (`poll`). |

---

## ⚠️ Critical Architectural Gotcha: Stack Alignment

During local execution testing of this framework, an essential architectural behavior was verified regarding x86_64 Calling Conventions and `system()` calls:

When overwriting a saved return pointer directly to a `win()` or shell-spawning function, **the stack pointer (RSP) can become misaligned by 8 bytes** compared to a standard branch sequence initialization via `call` instruction.

* **The Symptom:** The target execution transfers successfully (e.g., standard print logs execute), but nested routines like `system("/bin/sh")` will silently drop input context or crash inside internal libc machinery.
* **The Remediating Fix:** Always introduce an empty standalone `ret` instruction gadget into your ROP string array *prior* to injecting the target execution address. This increments the stack pointer back to 16-byte alignment.

```python
# Rectifying stack parity before calling system()
payload = b"A" * OFFSET
payload += elf.pack(ret_gadget)   # Pad stack pointer alignment (Mandatory)
payload += elf.pack(win_addr)     # Transfer execution flow cleanly
```

**Note on Android/ARM64:** ARM64 has different stack alignment requirements than x86_64. The template uses `elf.pack()` to handle architecture-specific packing automatically.

---

## 🐳 Isolated Server Deployment (Docker + Socat)

The repository provides production-grade deployment tools mirroring contemporary CTF event hosting standards (such as CTFd and pwn.college) to isolate applications within restricted security sandboxes.

### Testing the Sandbox Infrastructure Locally
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

## 🔧 Termux-Specific Notes

### Why No `-no-pie`?
Android enforces **Position Independent Executable (PIE)** at the OS level. The updated `build.sh` removes `-no-pie` flags and uses `-fstack-protector` alternatives that are fully compatible with ARM64 architecture.

### GDB on Termux
Use TMUX for debugging split windows:
```bash
apt install tmux
python3 exploit_template.py gdb
```

### Binary Compatibility
All generated binaries run natively on ARM64 Android devices without cross-compilation.

---

Maintained and Developed 💻 By Yashocked 🚀
