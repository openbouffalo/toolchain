#!/usr/bin/env bash
set -euo pipefail

# Run the GitHub Actions workflow locally using `act`
# This runs only for the host architecture (and skips the release stage)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_FILE="${SCRIPT_DIR}/.github/workflows/build-toolchain.yml"

# Detect host architecture
HOST_ARCH=$(uname -m)
case "${HOST_ARCH}" in
    x86_64|amd64)
        ACT_ARCH="x86_64"
        ;;
    aarch64|arm64)
        ACT_ARCH="aarch64"
        ;;
    *)
        echo "Unsupported architecture: ${HOST_ARCH}"
        exit 1
        ;;
esac

echo "Running workflow for host architecture: ${ACT_ARCH}"

# Check if act is installed
if ! command -v act &> /dev/null; then
    echo "Error: 'act' is not installed."
    exit 1
fi

# Create a temporary event file for workflow_dispatch with version input
EVENT_FILE=$(mktemp)
cat > "${EVENT_FILE}" <<EOF
{
  "inputs": {
    "version": "V3.0.1"
  }
}
EOF

# Run act with the build job only for the current architecture
# We use --job to run only the build job, and filter matrix by architecture
echo "Starting act..."
act workflow_dispatch \
    --workflows "${WORKFLOW_FILE}" \
    --eventpath "${EVENT_FILE}" \
    --job build \
    --matrix "arch:${ACT_ARCH}" \
    --container-architecture linux/${ACT_ARCH} \
    "$@"

# Cleanup
rm -f "${EVENT_FILE}"

echo ""
echo "Local build completed for ${ACT_ARCH}!"
echo "Check the output above for any errors."
