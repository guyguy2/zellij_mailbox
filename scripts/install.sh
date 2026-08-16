#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_GLOBAL_DIR="$HOME/.gemini/config/plugins/zellij-orchestrator"
BIN_DIR="$HOME/.local/bin"

echo "📦 Installing Zellij Orchestrator Plugin..."

# Make all scripts executable
chmod +x "$PLUGIN_DIR"/scripts/*.sh "$PLUGIN_DIR"/skills/zellij-orchestrator/scripts/*.sh

# Create target global plugin directory
mkdir -p "$HOME/.gemini/config/plugins"

# Remove existing symlink/directory if present
rm -rf "$TARGET_GLOBAL_DIR"

# Symlink this repo to global plugins for automatic updates
ln -s "$PLUGIN_DIR" "$TARGET_GLOBAL_DIR"
echo "✅ Symlinked plugin to: $TARGET_GLOBAL_DIR"

# Install global agy-multi command if bin dir exists or create it
mkdir -p "$BIN_DIR"
cat <<'EOF' > "$BIN_DIR/agy-multi"
#!/usr/bin/env bash
exec "$HOME/.gemini/config/plugins/zellij-orchestrator/skills/zellij-orchestrator/scripts/launch.sh" "$@"
EOF
chmod +x "$BIN_DIR/agy-multi"

echo "✅ Created global CLI command: $BIN_DIR/agy-multi"
echo ""
echo "🎉 Installation Complete!"
echo "You can now run 'agy-multi' from any project directory to launch a multi-agent orchestration session."
