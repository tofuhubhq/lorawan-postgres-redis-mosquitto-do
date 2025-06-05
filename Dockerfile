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
RUN apt-get update && apt-get install curl -y && curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh && chmod +x install-opentofu.sh && ./install-opentofu.sh --install-method deb && rm -f install-opentofu.sh

# Working directory where project gets mounted
WORKDIR /app

# Default command: run tofu apply
CMD ['sh', '-c', 'tofu init -backend-config="path=/app/state/terraform.tfstate" && tofu apply -state=/app/state/terraform.tfstate -var-file=/app/vars/variables.tfvars -auto-approve']
