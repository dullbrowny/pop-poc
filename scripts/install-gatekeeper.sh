#!/usr/bin/env bash
set -euo pipefail

GATEKEEPER_VER=v3.19.1

echo "🚀 Installing OPA Gatekeeper CRDs + controller (v${GATEKEEPER_VER})…"
kubectl create namespace gatekeeper-system --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "https://raw.githubusercontent.com/open-policy-agent/gatekeeper/${GATEKEEPER_VER}/deploy/gatekeeper.yaml"

echo "⏳ Waiting for Gatekeeper to be ready…"
kubectl rollout status -n gatekeeper-system deployment/gatekeeper-controller-manager --timeout=2m

echo "🔄 Refreshing ArgoCD pop-root…"
kubectl annotate application pop-root \
  -n argocd \
  argocd.argoproj.io/refresh='hard' \
  --overwrite

echo "✅ Gatekeeper installed and ArgoCD refreshed!"

