#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Setting up PoP POC repository structure..."

# 1. Create directories
mkdir -p docs scripts gitops/core gitops/modules helm

echo "✅ Directories created: docs/ scripts/ gitops/{core,modules}/ helm/"

# 2. Root-level files
cat > README.md <<EOF
# Tiger One PoP POC

This repository contains:

- **docs/**: Architecture and design docs
- **scripts/**: Utility scripts (bootstrap, setup-structure, setup-venv)
- **gitops/**: ArgoCD manifests (AppOfApps + sub-apps)
  - **core/**: Core kernel services (metadata, policy)
  - **modules/**: PoP modules (ingestion, messaging, feature store, etc.)
- **helm/**: Shared Helm values and umbrella charts
- **requirements.txt**: Python dependencies
EOF

echo "✅ README.md created"

# 3. .gitignore
cat > .gitignore <<EOF
# OS artifacts
.DS_Store

# Terraform
*.tfstate
*.tfstate.backup

# Kubernetes manifests
*.yaml

# GitOps secrets
gitops/.env

# Helm
charts/*.tgz

# Node modules
node_modules/

# Python venv
.venv/
EOF

echo "✅ .gitignore created"

# 4. LICENSE stub
cat > LICENSE <<EOF
MIT License

<Insert license text here>
EOF

echo "✅ LICENSE created"

# 5. Documentation stub
cat > docs/architecture.md <<EOF
# Tiger One PoP Platform Architecture

(Insert detailed architecture overview here.)

## Layers
- Core Kernel Services
- North (Modules)
- Fabric
- South (Adapters)
- Cross-cutting (Security, Observability, GitOps)
EOF

echo "✅ docs/architecture.md created"

# 6. Copy bootstrap script placeholder
cat > scripts/bootstrap-pop.sh <<EOF
#!/usr/bin/env bash
# (Bootstrap script to provision local demo environment)
EOF
chmod +x scripts/bootstrap-pop.sh

echo "✅ scripts/bootstrap-pop.sh placeholder created"

# 7. GitOps AppOfApps
cat > gitops/argocd-apps.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: pop-root
  namespace: argocd
spec:
  project: default
  source:
    repoURL: "<REPLACE_WITH_YOUR_GIT_URL>"
    path: gitops
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated: {}
EOF

echo "✅ gitops/argocd-apps.yaml created"

# 8. Core kernel apps
cat > gitops/core/metadata-app.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: metadata-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: "<REPLACE_WITH_YOUR_GIT_URL>"
    path: gitops/core/metadata
  destination:
    server: https://kubernetes.default.svc
    namespace: metadata
  syncPolicy:
    automated: {}
EOF

echo "✅ gitops/core/metadata-app.yaml created"

cat > gitops/core/policy-app.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: policy-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: "<REPLACE_WITH_YOUR_GIT_URL>"
    path: gitops/core/policy
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated: {}
EOF

echo "✅ gitops/core/policy-app.yaml created"

# 9. Module stubs
for mod in ingestion messaging feature; do
  mkdir -p gitops/modules/$mod
  cat > gitops/modules/${mod}-app.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${mod}-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: "<REPLACE_WITH_YOUR_GIT_URL>"
    path: gitops/modules/${mod}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${mod}
  syncPolicy:
    automated: {}
EOF
  echo "✅ gitops/modules/${mod}-app.yaml created"
done

# 10. Shared Helm values
cat > helm/values.yaml <<EOF
# Shared Helm values for PoP POC
global:
  imagePullPolicy: IfNotPresent
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi
EOF

echo "✅ helm/values.yaml created"

# 11. Python virtual environment setup
echo "🔧 Creating Python virtual environment setup..."
cat > requirements.txt <<EOF
# Add Python dependencies here
# e.g. fastapi, pyyaml, kubernetes, apache-airflow, feast, click
EOF

echo "✅ requirements.txt created"

cat > scripts/setup-venv.sh <<EOF
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
EOF
chmod +x scripts/setup-venv.sh

echo "✅ scripts/setup-venv.sh created"

echo "🎉 Repository structure scaffolded with venv support. Ready to commit!"

