# Define the Node.js version as a build argument at the top
ARG NODEVER=24

# --------------------
# Stage 0: OpenTofu Source
# --------------------
FROM ghcr.io/opentofu/opentofu:minimal AS tofu_source


# --------------------
# Stage 1: Build & Install Dependencies (AS build)
# --------------------
FROM node:${NODEVER} AS build

WORKDIR /usr/src/app

# Install build-essential for native Node.js module compilation
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        python3 \
        ca-certificates \
        && \
    rm -rf /var/lib/apt/lists/*

# Copy OpenTofu binary and create terraform symlink
COPY --from=tofu_source /usr/local/bin/tofu /usr/local/bin/tofu
RUN chmod +x /usr/local/bin/tofu && \
    ln -s /usr/local/bin/tofu /usr/local/bin/terraform

# Install CDKTF CLI globally
RUN npm install -g cdktf-cli

# Install project dependencies
COPY app/package.json ./
RUN npm i

# Copy application source code
COPY app/ .

# Synthesize the Terraform code
RUN cdktf synth


# --------------------
# Stage 2: Development Runtime (AS release)
# --------------------
ARG NODEVER=24

FROM node:${NODEVER}-slim AS release

WORKDIR /usr/src/app

# Install dev tools AND build requirements for CDKTF + CA certificates for SSL
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        python3 \
        ca-certificates \
        git \
        vim \
        nano \
        curl \
        procps \
        && \
    update-ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy the OpenTofu binary and create symlink
COPY --from=tofu_source /usr/local/bin/tofu /usr/local/bin/tofu
RUN chmod +x /usr/local/bin/tofu && \
    ln -s /usr/local/bin/tofu /usr/local/bin/terraform

# Install CDKTF CLI globally (now Python and CA certs are available)
RUN npm install -g cdktf-cli

# Copy entire application from build stage
COPY --from=build /usr/src/app /usr/src/app

# Keep container running
CMD ["tail", "-f", "/dev/null"]