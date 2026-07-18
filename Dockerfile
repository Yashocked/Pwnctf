# Dockerfile — deploy vuln.cpp sebagai soal pwn CTF beneran
# Build:  docker build -t pwn-challenge .
# Run:    docker run -p 1337:1337 pwn-challenge
# Test:   nc localhost 1337

FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    socat \
    gcc g++ \
    && rm -rf /var/lib/apt/lists/*

# User non-root buat jalanin challenge (best practice: JANGAN jalanin binary
# soal sebagai root, biar kalau ada bug di luar dugaan efeknya kebatasin)
RUN useradd -m -s /bin/bash ctf

WORKDIR /home/ctf

# Copy source & compile dengan proteksi yang lo mau (ganti sesuai kesulitan soal)
COPY vuln.cpp .
RUN g++ -no-pie -fno-stack-protector -z execstack -o chall vuln.cpp \
    && chown ctf:ctf chall \
    && chmod 755 chall

# Flag: JANGAN hardcode flag asli di sini kalau repo public.
# Isi pakai build-arg pas deploy beneran:
#   docker build --build-arg FLAG="CTF{flag_asli_lo}" -t pwn-challenge .
ARG FLAG="CTF{ganti_flag_ini_pas_deploy_beneran}"
RUN echo "$FLAG" > /home/ctf/flag.txt \
    && chown ctf:ctf /home/ctf/flag.txt \
    && chmod 400 /home/ctf/flag.txt

USER ctf
EXPOSE 1337

# socat expose binary lewat TCP, ini yang bikin bisa diakses via `nc host port`
CMD ["socat", "-T60", "TCP-LISTEN:1337,reuseaddr,fork", "EXEC:/home/ctf/chall,pty,stderr,setsid,sigint,sane"]
