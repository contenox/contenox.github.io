#!/usr/bin/env sh
# install.sh — Contenox installer
# Usage: curl -fsSL https://contenox.com/install.sh | sh
set -e

REPO="contenox/contenox"
BIN="contenox"

# ── Detect OS ────────────────────────────────────────────────────────────────
OS="$(uname -s)"
case "${OS}" in
  Linux*)  OS=linux  ;;
  Darwin*) OS=darwin ;;
  *)
    echo "Unsupported OS: ${OS}"
    echo "Please download manually from https://github.com/${REPO}/releases"
    exit 1
    ;;
esac

# ── Detect arch ──────────────────────────────────────────────────────────────
ARCH="$(uname -m)"
case "${ARCH}" in
  x86_64|amd64) ARCH=amd64 ;;
  arm64|aarch64) ARCH=arm64 ;;
  *)
    echo "Unsupported architecture: ${ARCH}"
    echo "Please download manually from https://github.com/${REPO}/releases"
    exit 1
    ;;
esac

# ── Fetch latest release tag ─────────────────────────────────────────────────
echo "Fetching latest Contenox release..."
if command -v curl >/dev/null 2>&1; then
  TAG="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | sed 's/.*"tag_name": *"\(.*\)".*/\1/')"
elif command -v wget >/dev/null 2>&1; then
  TAG="$(wget -qO- "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | sed 's/.*"tag_name": *"\(.*\)".*/\1/')"
else
  echo "Error: curl or wget is required to install contenox."
  exit 1
fi

if [ -z "${TAG}" ]; then
  echo "Error: could not determine latest release tag."
  echo "Please download manually from https://github.com/${REPO}/releases"
  exit 1
fi

echo "Latest version: ${TAG}"

# ── Download binary ──────────────────────────────────────────────────────────
ASSET="${BIN}-${TAG}-${OS}-${ARCH}"
URL="https://github.com/${REPO}/releases/download/${TAG}/${ASSET}"
TMP="$(mktemp)"

echo "Downloading ${ASSET}..."
if command -v curl >/dev/null 2>&1; then
  curl -fL --progress-bar --max-time 120 "${URL}" -o "${TMP}"
elif command -v wget >/dev/null 2>&1; then
  wget --show-progress -qO "${TMP}" "${URL}"
fi

chmod +x "${TMP}"

# ── Install ───────────────────────────────────────────────────────────────────
INSTALL_DIR="/usr/local/bin"
if [ -w "${INSTALL_DIR}" ]; then
  mv "${TMP}" "${INSTALL_DIR}/${BIN}"
elif command -v sudo >/dev/null 2>&1; then
  echo "Moving binary to ${INSTALL_DIR} (sudo required)..."
  sudo mv "${TMP}" "${INSTALL_DIR}/${BIN}"
else
  # Fall back to ~/bin
  INSTALL_DIR="${HOME}/bin"
  mkdir -p "${INSTALL_DIR}"
  mv "${TMP}" "${INSTALL_DIR}/${BIN}"
  echo ""
  echo "Note: installed to ${INSTALL_DIR}/${BIN}"
  echo "Make sure ${INSTALL_DIR} is in your PATH."
fi

echo ""
echo "✓ contenox ${TAG} installed to ${INSTALL_DIR}/${BIN}"
echo ""
echo "Get started:"
echo "  contenox --help"
echo "  contenox plan new \"describe your goal\""
