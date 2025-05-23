#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Backing up bootstrap-pop.sh..."
cp scripts/bootstrap-pop.sh scripts/bootstrap-pop.sh.bak

echo "🔧 Patching namespace creation commands to use 'create || true'..."

# Perl replaces each 'kubectl create namespace NAME --dry-run=client -o yaml | kubectl apply -f -' with 'kubectl create namespace NAME || true'
perl -i -pe 's|kubectl create namespace\s+([^\s]+)\s+--dry-run=client -o yaml \| kubectl apply -f -|kubectl create namespace $1 || true|g' scripts/bootstrap-pop.sh

echo "✔️  Namespace creation commands patched in scripts/bootstrap-pop.sh"

echo "Next, rerun:"
echo "  bash scripts/bootstrap-pop.sh"

