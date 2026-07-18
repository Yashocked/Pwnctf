// pwn_helper.hpp — mini "pwntools" versi C++ (Termux/Android Compatible)
// Buat lo yang mau nulis exploit langsung di C++ (bukan Python).
// Header-only, tinggal #include "pwn_helper.hpp"
//
// TERMUX/ANDROID: File ini 100% compatible dengan ARM64 Termux karena hanya
// menggunakan POSIX system calls yang tersedia di semua platform Unix/Linux.
//
// Fitur:
//   - connect ke remote (socket) atau spawn local process (pipe)
//   - send / recvuntil / recvline
//   - p32/p64/u32/u64 (packing address, little endian — architecture-agnostic)
//   - cyclic pattern generator (buat cari offset overflow)
//   - interactive() -> jadi kayak nc manual

#pragma once
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <poll.h>

namespace pwn {

// ---------- packing helpers (little endian, kayak p32/p64 di pwntools) ----------
inline std::string p32(uint32_t v) {
    std::string s(4, 0);
    memcpy(&s[0], &v, 4);
    return s;
}
inline std::string p64(uint64_t v) {
    std::string s(8, 0);
    memcpy(&s[0], &v, 8);
    return s;
}
inline uint32_t u32(const std::string &s) {
    uint32_t v = 0;
    memcpy(&v, s.data(), 4);
    return v;
}
inline uint64_t u64(const std::string &s) {
    uint64_t v = 0;
    memcpy(&v, s.data(), 8);
    return v;
}

// ---------- cyclic pattern (buat nyari offset overflow) ----------
inline std::string cyclic(size_t length) {
    std::string result;
    std::string charset = "abcdefghijklmnopqrstuvwxyz";
    size_t a = 0, b = 0, c = 0;
    while (result.size() < length) {
        result += charset[a];
        result += charset[b];
        result += charset[c];
        result += "0"; // simple 4-char cycle, cukup buat cari offset kasar
        c++;
        if (c >= 26) { c = 0; b++; }
        if (b >= 26) { b = 0; a++; }
    }
    return result.substr(0, length);
}

// ---------- I/O channel: bisa local process atau remote socket ----------
class Tube {
public:
    int fd_in = -1, fd_out = -1;
    pid_t child_pid = -1;
    bool is_socket = false;

    // connect ke remote host:port (kayak remote() di pwntools)
    bool connect_remote(const std::string &host, int port) {
        struct addrinfo hints{}, *res;
        hints.ai_family = AF_INET;
        hints.ai_socktype = SOCK_STREAM;
        std::string port_str = std::to_string(port);
        if (getaddrinfo(host.c_str(), port_str.c_str(), &hints, &res) != 0) {
            perror("getaddrinfo");
            return false;
        }
        int sock = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
        if (sock < 0) { perror("socket"); return false; }
        if (::connect(sock, res->ai_addr, res->ai_addrlen) < 0) {
            perror("connect");
            return false;
        }
        freeaddrinfo(res);
        fd_in = fd_out = sock;
        is_socket = true;
        return true;
    }

    // spawn local process (kayak process() di pwntools), pakai pipe
    bool spawn_local(const std::string &path) {
        int in_pipe[2], out_pipe[2];
        pipe(in_pipe);
        pipe(out_pipe);

        pid_t pid = fork();
        if (pid == 0) {
            dup2(in_pipe[0], STDIN_FILENO);
            dup2(out_pipe[1], STDOUT_FILENO);
            dup2(out_pipe[1], STDERR_FILENO);
            close(in_pipe[1]); close(out_pipe[0]);
            execl(path.c_str(), path.c_str(), (char*)nullptr);
            perror("execl");
            _exit(1);
        }
        close(in_pipe[0]); close(out_pipe[1]);
        fd_out = in_pipe[1];  // kita nulis ke stdin anak
        fd_in = out_pipe[0];  // kita baca dari stdout anak
        child_pid = pid;
        return true;
    }

    void send(const std::string &data) {
        write(fd_out, data.data(), data.size());
    }
    void sendline(const std::string &data) {
        send(data + "\n");
    }

    std::string recv(size_t n = 4096) {
        std::vector<char> buf(n);
        ssize_t r = read(fd_in, buf.data(), n);
        if (r <= 0) return "";
        return std::string(buf.data(), r);
    }

    // baca sampai ketemu delimiter tertentu
    std::string recvuntil(const std::string &delim) {
        std::string result;
        char c;
        while (true) {
            ssize_t r = read(fd_in, &c, 1);
            if (r <= 0) break;
            result += c;
            if (result.size() >= delim.size() &&
                result.compare(result.size() - delim.size(), delim.size(), delim) == 0)
                break;
        }
        return result;
    }

    std::string recvline() {
        return recvuntil("\n");
    }

    // interactive shell — kayak io.interactive() di pwntools
    void interactive() {
        fprintf(stderr, "[*] Switching to interactive mode\n");
        struct pollfd fds[2];
        fds[0].fd = fd_in;  fds[0].events = POLLIN;
        fds[1].fd = STDIN_FILENO; fds[1].events = POLLIN;

        char buf[4096];
        while (true) {
            int ret = poll(fds, 2, -1);
            if (ret < 0) break;

            if (fds[0].revents & POLLIN) {
                ssize_t n = read(fd_in, buf, sizeof(buf));
                if (n <= 0) { fprintf(stderr, "[*] Connection closed\n"); break; }
                write(STDOUT_FILENO, buf, n);
            }
            if (fds[1].revents & POLLIN) {
                ssize_t n = read(STDIN_FILENO, buf, sizeof(buf));
                if (n <= 0) break;
                write(fd_out, buf, n);
            }
        }
    }

    ~Tube() {
        if (is_socket && fd_in >= 0) close(fd_in);
        else {
            if (fd_in >= 0) close(fd_in);
            if (fd_out >= 0) close(fd_out);
            if (child_pid > 0) waitpid(child_pid, nullptr, 0);
        }
    }
};

} // namespace pwn
