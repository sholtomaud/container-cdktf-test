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

# The NODEVER-slim image is based on Debian Linux, not macOS.
FROM node:${NODEVER}-slim AS release

WORKDIR /usr/src/app

# Install dev tools and CA certificates for SSL
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        vim \
        nano \
        curl \
        procps \
        ca-certificates \
        && \
    update-ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy OpenTofu binary, terraform symlink and cdktf-cli from the build stage
COPY --from=build /usr/local/bin/tofu /usr/local/bin/tofu
COPY --from=build /usr/local/bin/terraform /usr/local/bin/terraform
COPY --from=build /usr/local/lib/node_modules/cdktf-cli /usr/local/lib/node_modules/cdktf-cli

# Create symlink for cdktf-cli
RUN ln -s /usr/local/lib/node_modules/cdktf-cli/bin/cdktf /usr/local/bin/cdktf

# Copy entire application from build stage
COPY --from=build /usr/src/app /usr/src/app

# Keep container running
CMD ["tail", "-f", "/dev/null"]