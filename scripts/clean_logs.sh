#!/usr/bin/env bash
set -euo pipefail

# Deterministic Path Resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="."
CLEAN_ALL=false

# Usage information
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [TARGET_DIR]

Clean up hook logs and telemetry from the Agent Bus.

Arguments:
  TARGET_DIR        Target workspace directory (default: current directory)

Options:
  -a, --all         Also clean task briefs (.agent-bus/tasks/*.md) and results (.agent-bus/results/*.json)
  -h, --help        Show this help message

Examples:
  $(basename "$0")                  # Deletes .agent-bus/hooks.log in current directory
  $(basename "$0") --all            # Deletes logs, tasks, and results
  $(basename "$0") /path/to/project # Deletes logs in specified project
EOF
    exit 0
}

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all)
            CLEAN_ALL=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "❌ Unknown option: $1" >&2
            usage
            ;;
        *)
            TARGET_DIR="$1"
            shift
            ;;
    esac
done

BUS_DIR="$TARGET_DIR/.agent-bus"

if [ ! -d "$BUS_DIR" ]; then
    echo "ℹ️  No .agent-bus directory found at: $TARGET_DIR/.agent-bus"
    exit 0
fi

echo "🧹 Cleaning Agent Bus logs in $BUS_DIR..."

LOG_COUNT=0
# Remove hook logs
if [ -f "$BUS_DIR/hooks.log" ]; then
    rm -f "$BUS_DIR/hooks.log"
    echo "  ✓ Removed hooks.log"
    LOG_COUNT=$((LOG_COUNT + 1))
fi

# Remove any other *.log files in .agent-bus
while IFS= read -r log_file; do
    if [ -n "$log_file" ]; then
        rm -f "$log_file"
        echo "  ✓ Removed $(basename "$log_file")"
        LOG_COUNT=$((LOG_COUNT + 1))
    fi
done < <(find "$BUS_DIR" -maxdepth 1 -name "*.log" 2>/dev/null || true)

if [ "$LOG_COUNT" -eq 0 ]; then
    echo "  ℹ️  No log files found to clean."
fi

# If --all flag was provided, clean tasks and results
if [ "$CLEAN_ALL" = true ]; then
    echo "🧹 Cleaning tasks and results..."
    
    TASK_COUNT=$(find "$BUS_DIR/tasks" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$TASK_COUNT" -gt 0 ]; then
        find "$BUS_DIR/tasks" -type f -name "*.md" -delete 2>/dev/null || true
        echo "  ✓ Removed $TASK_COUNT task file(s) in $BUS_DIR/tasks/"
    fi

    RESULT_COUNT=$(find "$BUS_DIR/results" -type f -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$RESULT_COUNT" -gt 0 ]; then
        find "$BUS_DIR/results" -type f -name "*.json" -delete 2>/dev/null || true
        echo "  ✓ Removed $RESULT_COUNT result receipt(s) in $BUS_DIR/results/"
    fi
fi

echo "✨ Log cleanup completed successfully!"
