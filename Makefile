# Makefile for OpenTofu/CDKTF Container Management using macOS 'container' CLI

# --- Configuration Variables ---
ifdef CI
CONTAINER_CLI = docker
else
CONTAINER_CLI = container
endif
CONTAINER_NAME = opentofu-site-container
IMAGE_NAME = opentofu-cdktf-site
DOCKERFILE = Dockerfile
NODEVER ?= 24

# --- Core Commands ---

.PHONY: build run dev start stop clean shell synth deploy plan destroy all clean-image info logs test inspect sync clean-local

# Build the container image
build:
	@echo "🛠️ Building container image: $(IMAGE_NAME) with Node $(NODEVER)..."
	$(CONTAINER_CLI) build --no-cache --build-arg NODEVER=$(NODEVER) -t $(IMAGE_NAME) -f $(DOCKERFILE) .
	@echo "✅ Build complete."

# Run container WITHOUT volume mount (uses built-in code)
run: stop clean
	@echo "🚀 Running container: $(CONTAINER_NAME)..."
	$(CONTAINER_CLI) run -d \
		--name $(CONTAINER_NAME) \
		$(IMAGE_NAME)
	@echo "✅ Container is running (using built-in code)."
	@echo "💡 Use 'make shell' to connect"
	@echo "💡 Use 'make synth' to synthesize"

# Run container in development mode
dev: stop clean clean-local
	@echo "🚀 Running container: $(CONTAINER_NAME)..."
	$(CONTAINER_CLI) run -d \
		--name $(CONTAINER_NAME) \
		$(IMAGE_NAME)
	@echo "✅ Container is running."
	@echo ""
	@echo "🎯 Development Workflow:"
	@echo "  1. Edit files locally in VSCode"
	@echo "  2. make sync          - Copy changes to container"
	@echo "  3. make synth         - Run synth"
	@echo "  4. make shell         - Interactive shell"

# Start a stopped container
start:
	@echo "▶️ Starting container: $(CONTAINER_NAME)..."
	$(CONTAINER_CLI) start $(CONTAINER_NAME)

# Stop the running container
stop:
	@echo "🛑 Stopping container: $(CONTAINER_NAME)..."
	-$(CONTAINER_CLI) stop $(CONTAINER_NAME) 2>/dev/null || true

# Delete the container
clean:
	@echo "🗑️ Deleting container: $(CONTAINER_NAME)..."
	-$(CONTAINER_CLI) rm $(CONTAINER_NAME) 2>/dev/null || true

# Clean local node_modules that shouldn't be there
clean-local:
	@echo "🧹 Cleaning local generated files..."
	@rm -rf ./app/node_modules
	@rm -rf ./app/.gen
	@rm -rf ./app/cdktf.out

# --- Development Commands ---

# Sync local files to container
sync:
	@echo "📤 Syncing local files to container..."
	@$(CONTAINER_CLI) cp ./app/main.ts $(CONTAINER_NAME):/usr/src/app/main.ts
	@$(CONTAINER_CLI) cp ./app/cdktf.json $(CONTAINER_NAME):/usr/src/app/cdktf.json
	@$(CONTAINER_CLI) cp ./app/package.json $(CONTAINER_NAME):/usr/src/app/package.json
	@echo "✅ Files synced to container"

# Execute interactive shell
shell:
	@echo "💻 Opening shell in container..."
	@echo ""
	$(CONTAINER_CLI) exec -it $(CONTAINER_NAME) /bin/bash

# Run cdktf synth
synth:
	@echo "✨ Running cdktf synth in container..."
	$(CONTAINER_CLI) exec $(CONTAINER_NAME) cdktf synth
	@echo "✅ Synth complete. View output with 'make inspect'"

# Sync and synth in one command
sync-synth: sync synth

# Deploy infrastructure
deploy:
	@echo "🚀 Deploying infrastructure..."
	$(CONTAINER_CLI) exec -it $(CONTAINER_NAME) cdktf deploy --auto-approve

# Plan infrastructure changes
plan:
	@echo "📋 Planning infrastructure changes..."
	$(CONTAINER_CLI) exec -it $(CONTAINER_NAME) cdktf plan

# Show diff
diff:
	@echo "🔍 Showing infrastructure diff..."
	$(CONTAINER_CLI) exec -it $(CONTAINER_NAME) cdktf diff

# Destroy infrastructure
destroy:
	@echo "💥 Destroying infrastructure..."
	$(CONTAINER_CLI) exec -it $(CONTAINER_NAME) cdktf destroy

# View container logs
logs:
	@echo "📜 Container logs..."
	$(CONTAINER_CLI) logs $(CONTAINER_NAME)

# Follow logs
logs-follow:
	@echo "📜 Following container logs (Ctrl+C to stop)..."
	$(CONTAINER_CLI) logs -f $(CONTAINER_NAME)

# Copy cdktf.out from container to local for inspection
inspect:
	@echo "📦 Copying cdktf.out from container to local..."
	@mkdir -p ./cdktf.out
	$(CONTAINER_CLI) cp $(CONTAINER_NAME):/usr/src/app/cdktf.out/. ./cdktf.out/
	@echo "✅ Output available in ./cdktf.out/"
	@echo "📂 View in VSCode or run: ls -la ./cdktf.out/"

# Synth and inspect in one command
synth-inspect: synth inspect

# Full workflow: sync, synth, inspect
dev-cycle: sync synth inspect
	@echo "🎉 Development cycle complete!"

# --- Testing Commands ---

# Verify installations
test:
	@echo "🔍 Testing installations in container..."
	@echo ""
	@echo "CDKTF version:"
	@$(CONTAINER_CLI) exec $(CONTAINER_NAME) cdktf --version
	@echo ""
	@echo "OpenTofu version:"
	@$(CONTAINER_CLI) exec $(CONTAINER_NAME) tofu --version
	@echo ""
	@echo "Node version:"
	@$(CONTAINER_CLI) exec $(CONTAINER_NAME) node --version
	@echo ""
	@echo "✅ All tools installed correctly"

# List running containers
ps:
	@echo "📋 Running containers..."
	$(CONTAINER_CLI) ps

# Show container info and helpful commands
info:
	@echo "📊 Container Information:"
	@echo "  Name: $(CONTAINER_NAME)"
	@echo "  Image: $(IMAGE_NAME)"
	@echo ""
	@echo "🎯 Development Workflow:"
	@echo "  1. Edit files in VSCode (main.ts, cdktf.json, etc.)"
	@echo "  2. make sync          - Copy changes to container"
	@echo "  3. make synth         - Run synthesis"
	@echo "  4. make inspect       - View output locally"
	@echo ""
	@echo "⚡ Quick Commands:"
	@echo "  make dev-cycle     - sync + synth + inspect (full cycle)"
	@echo "  make sync-synth    - sync + synth"
	@echo "  make shell         - Interactive shell"
	@echo "  make test          - Verify installations"

# --- Cleanup Commands ---

clean-image: clean
	@echo "🗑️ Deleting image: $(IMAGE_NAME)..."
	-$(CONTAINER_CLI) rmi $(IMAGE_NAME) 2>/dev/null || true

clean-all: stop clean clean-local
	@echo "🗑️ Removing local cdktf.out..."
	@rm -rf ./cdktf.out
	@echo "✅ Complete cleanup done."

# --- Convenience Targets ---

# Build and run
all: build dev info