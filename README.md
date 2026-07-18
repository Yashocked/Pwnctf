# Pwnctf 🚀

[![License: MIT](https://shields.io)](https://opensource.org)
[![Supported OS: Termux & Linux](https://shields.io)](#)
[![Tech Stack: C++ & Python](https://shields.io)](#)

**Pwnctf** is a lightweight, all-in-one binary exploitation (Pwn) practice toolkit and development framework tailored for CTF (*Capture The Flag*) players. It is fully optimized to run natively on Android devices via **Termux** as well as standard **Linux x86_64** environments. 

This repository provides a multi-vulnerability testing binary (`vuln.cpp`), compiler scripts with scalable protection levels, a classic Python `pwntools` exploit boilerplate, and a standalone header-only C++ replica of pwntools for zero-dependency exploit automation.

---

## 📁 Repository Blueprint

```text
├── vuln.cpp                 # Multi-vulnerability practice target binary (4 bug classes)
├── build.sh                 # Compilation automation with scalable security mitigations
├── exploit_template.py      # Standard Python pwntools automation boilerplate
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

## 🚀 Quick Start Guide

### 1. Environment Deployment (Termux Native)
Initialize the development toolkit, installation dependencies, and toolchains directly on Termux:
```bash
chmod +x setup_termux.sh build.sh
./setup_termux.sh          # Provisions clang, gdb, python3, pwntools, ropgadget, and pwninit
./build.sh                 # Automates compilation of vuln.cpp into four distinct security tiers
```

Verify the active exploit mitigation configurations for the generated binaries via the `checksec` command:
```bash
checksec --file=vuln_easy
```

### 2. Launching Exploits via Python (Recommended Layout)
Interact with your target execution runtime using the feature-rich `exploit_template.py` architecture:
```bash
python3 exploit_template.py          # Executes against the local active target process
python3 exploit_template.py gdb      # Spawns local pipeline and auto-attaches a GDB debugger instance
python3 exploit_template.py remote   # Interacts directly with a remote hosted challenge architecture
```

### 3. Launching Exploits via Pure C++ (Zero Python Footprint)
Compile and launch your compiled exploit directly using the high-performance native `pwn_helper.hpp` pipeline:
```bash
g++ -std=c++17 -o exploit exploit.cpp
./exploit                       # Attacks the local host instance
./exploit remote 127.0.0.1 1337 # Attacks a remote hosted server
```

---

## 🛠️ Exploit Developer References

### Python Template Configuration (`exploit_template.py`)
The framework provides pre-built exploitation routines covering standard attack vectors including Stack Overflow (ret2win layout), Format String manipulation, and Return-to-libc (ret2libc) ROP chains:

```python
# Context initialization & dynamic mapping
context.binary = elf = ELF("./vuln_easy", checksec=True)
HOST, PORT = "127.0.0.1", 1337

def start():
    if args.REMOTE or "remote" in sys.argv:
        return remote(HOST, PORT)
    elif args.GDB or "gdb" in sys.argv:
        return gdb.debug([context.binary.path], gdbscript="break main\ncontinue")
    return process([context.binary.path])
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

When overwriting a saved return pointer directly to a `win()` or shell-spawning function, **the stack pointer (RSP) can become misaligned by 8 bytes** compared to a standard branch sequence initialized via a `call` instruction. 

* **The Symptom:** The target execution transfers successfully (e.g., standard print logs execute), but nested routines like `system("/bin/sh")` will silently drop input context or crash inside internal SIMD operations.
* **The Remediating Fix:** Always introduce an empty standalone `ret` instruction gadget into your ROP string array *prior* to injecting the target execution address. This increments the stack layout pointer by 8 bytes, restoring alignment cleanly to a 16-byte boundary.

```python
# Rectifying stack parity before calling system()
payload = b"A" * OFFSET
payload += p64(ret_gadget)   # Pad stack pointer alignment (Mandatory alignment patch)
payload += p64(win_addr)     # Transfer execution flow cleanly
```

---

## 🐳 Isolated Server Deployment (Docker + Socat)

The repository provides production-grade deployment tools mirroring contemporary CTF event hosting standards (such as CTFd and pwn.college) to isolate applications within restricted security sandboxes:

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

Maintained and Developed 💻 By Yashocked 🚀
