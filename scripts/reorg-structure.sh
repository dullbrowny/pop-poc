#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Fixing .gitignore and staging manifest files..."

# 1. Backup original .gitignore
cp .gitignore .gitignore.bak

echo "✔️ Backed up .gitignore to .gitignore.bak"

# 2. Remove the catch-all YAML ignore
#    Deletes any line that is exactly '*.yaml'
sed -i '' '/^\*\.yaml$/d' .gitignore

echo "✔️ Removed '*.yaml' ignore from .gitignore"

# 3. Stage the updated .gitignore
git add .gitignore

echo "✔️ Staged updated .gitignore"

# 4. Force-add the YAML manifest files that were previously ignored
for file in \
  gitops/core/policy-app.yaml \
  gitops/modules/feature/app.yaml \
  gitops/modules/ingestion/app.yaml \
  gitops/modules/messaging/app.yaml; do
  if [ -f "$file" ]; then
    git add -f "$file"
    echo "✔️ Force-added $file"
  else
    echo "⚠️ File not found: $file"
  fi
done

# 5. Commit and push the fix
git commit -m "fix: update .gitignore and add manifest files"
git push

echo "🎉 .gitignore fixed and files committed."

set -euo pipefail

echo "🔧 Reorganizing PoP POC repository structure..."

# 1. Move legacy pop-poc-script.sh into scripts/ if present
echo "1️⃣ Moving legacy script (if exists)..."
if [ -f pop-poc-script.sh ]; then
  mv pop-poc-script.sh scripts/
  echo "   ✔️ Moved pop-poc-script.sh → scripts/"
else
  echo "   ⚠️ No pop-poc-script.sh found at repo root"
fi

# 2. Add Gatekeeper ConstraintTemplate
echo "2️⃣ Adding Gatekeeper ConstraintTemplate..."
cat > gitops/core/policy/constraint-template.yaml <<'EOF'
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
  targets:
  - target: admission.k8s.gatekeeper.sh
    rego: |
      package k8srequiredlabels
      violation[{"msg": msg}] {
        provided := {label | input.review.object.metadata.labels[label]}
        missing := {"team"} - provided
        count(missing) > 0
        msg := sprintf("you must provide labels: %v", [missing])
      }
EOF
echo "   ✔️ Created constraint-template.yaml"

# 3. Hoist Gatekeeper manifests into manifests/ directory
echo "3️⃣ Organizing Gatekeeper manifests..."
mkdir -p gitops/core/policy/manifests
if [ -f gitops/core/policy/gatekeeper.yaml ]; then
  mv gitops/core/policy/gatekeeper.yaml gitops/core/policy/manifests/
  echo "   ✔️ Moved gatekeeper.yaml → gitops/core/policy/manifests/"
else
  echo "   ⚠️ gatekeeper.yaml not found in gitops/core/policy/"
fi
mv gitops/core/policy/constraint-template.yaml gitops/core/policy/manifests/

echo "   ✔️ Moved constraint-template.yaml → gitops/core/policy/manifests/"

# 4. Update policy-app.yaml to point at manifests/ and recurse
echo "4️⃣ Patching policy-app.yaml..."
sed -i '' \
  -e 's|path: gitops/core/policy|path: gitops/core/policy/manifests|' \
  gitops/core/policy-app.yaml
sed -i '' '/path: gitops\/core\/policy\/manifests/ a\
    directory:\
      recurse: true' \
  gitops/core/policy-app.yaml

echo "   ✔️ Updated path and enabled recursive sync in policy-app.yaml"

# 5. Move module app manifests into their folders
echo "5️⃣ Structuring module directories..."
for mod in ingestion messaging feature; do
  src="gitops/modules/${mod}-app.yaml"
  dest_dir="gitops/modules/${mod}"
  dest="${dest_dir}/app.yaml"
  if [ -f "$src" ]; then
    mkdir -p "$dest_dir"
    mv "$src" "$dest"
    echo "   ✔️ Moved ${mod}-app.yaml → ${mod}/app.yaml"
  else
    echo "   ⚠️ ${src} not found"
  fi
done

# 6. Stage & commit changes
echo "6️⃣ Committing changes..."
git add scripts/pop-poc-script.sh \
        gitops/core/policy/manifests \
        gitops/core/policy-app.yaml \
        gitops/modules/*/app.yaml

git commit -m "chore: reorganize policy into manifests/, add constraint-template, restructure module apps"
git push

echo "🎉 Reorganization complete!"

