#!/usr/bin/env bash
# Monitor a file and speak its contents with Piper TTS when it changes.
# Usage: speak_file_on_change.sh <file> [piper_model]
#   file        - Path to text file to monitor
#   piper_model - Optional: path to Piper .onnx model (default: ~/en_US-ryan-high.onnx)

set -e

usage() {
    echo "Usage: $0 <file> [piper_model]"
    echo "  file        - Path to text file to monitor"
    echo "  piper_model - Optional: path to Piper .onnx model (default: ~/en_US-ryan-high.onnx)"
    exit 1
}

# if [[ $# -lt 1 ]]; then
#     usage
# fi

FILE="text.txt"
MODEL="$HOME/en_US-ryan-high.onnx"
CONFIG="${MODEL}.json"

# if [[ ! -f "$FILE" ]]; then
#     echo "Error: File not found: $FILE" >&2
#     exit 1
# fi

# if [[ ! -f "$MODEL" ]]; then
#     echo "Error: Piper model not found: $MODEL" >&2
#     exit 1
# fi

# if [[ ! -f "$CONFIG" ]]; then
#     echo "Error: Piper config not found: $CONFIG" >&2
#     exit 1
# fi

if ! command -v inotifywait &>/dev/null; then
    echo "Error: inotifywait not found. Install inotify-tools." >&2
    exit 1
fi

if ! command -v piper &>/dev/null; then
    echo "Error: piper not found." >&2
    exit 1
fi

speak() {
    echo "Speaking: $FILE"
    piper -m "$MODEL" -c "$CONFIG" -i "$FILE" 
}

echo "Monitoring: $FILE"
echo "Model: $MODEL"
echo "Speak on change: Ctrl+C to stop"
echo "---"

# Speak initial contents if non-empty
speak "$FILE"

# Monitor for close_write only (one event per save; modify fires multiple times)
export FILE MODEL CONFIG
export -f speak
inotifywait -m -e close_write --format '%e' "$FILE" | xargs -I {} bash -c 'speak "$FILE"'
