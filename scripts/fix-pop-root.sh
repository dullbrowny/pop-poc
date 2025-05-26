#!/usr/bin/env bash
set -euo pipefail

# Script: fix-pop-root.sh
# Purpose: Sanity-check existence of the GitOps applications file,
#           patch the ArgoCD "pop-root" Application to point at it,
#           and trigger a sync.

# Configuration
APP_NAME="pop-root"
ARGO_NS="argocd"
NEW_APP_FILE="gitops/apps/applications.yaml"

# Check that the target file exists
if [[ ! -f "$NEW_APP_FILE" ]]; then
  echo "❌ File not found: $NEW_APP_FILE"
  echo "   Please ensure you have created ${NEW_APP_FILE} with your application manifests."
  exit 1
fi

echo "✅ Found $NEW_APP_FILE — proceeding to patch $APP_NAME"

# Patch the ArgoCD Application's source.path
echo "🔨 Patching Application $APP_NAME to use path '$NEW_APP_FILE'"
kubectl patch application "$APP_NAME" \
  -n "$ARGO_NS" \
  --type merge \
  -p "{\"spec\":{\"source\":{\"path\":\"$NEW_APP_FILE\"}}}"

echo "🔄 Triggering sync for Application $APP_NAME"
# Use ArgoCD CLI if available, otherwise fall back to kubectl
if command -v argocd &> /dev/null; then
  argocd app sync "$APP_NAME" --server localhost:8080 --insecure
else
  kubectl -n "$ARGO_NS" annotate application "$APP_NAME" \
    argocd.argoproj.io/sync-wave="0" --overwrite || true
  kubectl -n "$ARGO_NS" patch application "$APP_NAME" \
    --type merge -p "{\"spec\":{\"syncPolicy\":{\"automated\":{}}}}" || true
fi

echo "🎉 Done. Check status with:`kubectl get app $APP_NAME -n $ARGO_NS` or `argocd app get $APP_NAME` if using the CLI."

