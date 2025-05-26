#!/usr/bin/env bash
set -e

REPO="https://github.com/dullbrowny/pop-poc"

echo "Fixing module apps…"
for f in gitops/modules/*/app.yaml; do
  sed -i '' \
    -e "s|<REPLACE_WITH_YOUR_GIT_URL>|$REPO|" \
    -e '/directory:/a\
      recurse: true
' "$f"
done

echo "Removing broken metadata-app…"
git rm -f gitops/core/metadata-app.yaml

echo "Updating argocd-apps.yaml to drop metadata-app and ensure umbrella repoURL…"
# remove any metadata-app entry; ensure pop-root is correct
sed -i '' -e '/metadata-app$/d' gitops/argocd-apps.yaml

# (make sure your pop-root block still has recurse: true under source.directory)

echo "Done. Please git add, commit & push."

