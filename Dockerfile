# Base image
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    gnupg \
    git \
    dnsutils \
    postgresql-client \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install OpenTofu
RUN apt-get update && apt-get install curl -y && curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh && chmod +x install-opentofu.sh && ./install-opentofu.sh --install-method deb && rm -f install-opentofu.sh

# Working directory where project gets mounted
WORKDIR /app

# Add entrypoint
COPY entrypoint.sh .

RUN chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
