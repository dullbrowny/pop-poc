#!/usr/bin/env bash
set -euo pipefail

# Create venv directory
python3 -m venv .venv
# Activate venv
source .venv/bin/activate
# Upgrade pip
pip install --upgrade pip
# Install requirements if any
if [ -f requirements.txt ]; then
  pip install -r requirements.txt
fi

echo "✅ Python virtual environment (.venv) created and dependencies installed."
