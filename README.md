# 1. Build the image
make build

# 2. Run in dev mode (with volume mounts for live editing)
make dev

# Option 1: Use VSCode Dev Containers (RECOMMENDED)
make build
# Then in VSCode: Cmd+Shift+P → "Dev Containers: Reopen in Container"
# You'll be inside the container with full VSCode features

# Clean everything
make clean-all
make clean-image

# Rebuild with new package.json
make build

# Start container
make dev

# Test synth
make synth-inspect

# 4. Inside the container (via VSCode terminal):
cdktf synth          # Synthesize
npm run dev          # Start dev server (if you have one)

# Or from your host:
make synth           # Run synth from outside
make logs            # View logs
make ssh             # Test SSH connection