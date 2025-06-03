# Base image
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    gnupg \
    git \
    postgresql-client \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install OpenTofu
RUN curl -LO https://github.com/opentofu/opentofu/releases/latest/download/tofu_Linux_x86_64.zip && \
    unzip tofu_Linux_x86_64.zip && \
    mv tofu /usr/local/bin/tofu && \
    chmod +x /usr/local/bin/tofu && \
    rm tofu_Linux_x86_64.zip

# Working directory where project gets mounted
WORKDIR /app

# Default command: run tofu apply
ENTRYPOINT ["sh", "-c", "tofu init && tofu apply -auto-approve"]
