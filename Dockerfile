FROM ubuntu:22.04

# Dependências mínimas para Godot 4.3 headless no Linux
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libgles2 \
    libglib2.0-0 \
    libudev1 \
    libpulse0 \
    libxrandr2 \
    libx11-6 \
    ca-certificates \
    wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia o servidor exportado (gerado pelo Godot 4.3 → Export → Linux Server)
COPY server/cs02_server.x86_64 ./cs02_server
COPY server/cs02_server.pck    ./cs02_server.pck

RUN chmod +x ./cs02_server

# O Render injeta PORT automaticamente — nosso NetworkManager já lê $PORT
EXPOSE 8080

# Inicia em modo headless + servidor
CMD ["./cs02_server", "--headless", "--headless-server"]
