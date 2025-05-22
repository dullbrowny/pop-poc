# Tiger One PoP POC

This repository contains:

- **docs/**: Architecture and design docs
- **scripts/**: Utility scripts (bootstrap, setup-structure, setup-venv)
- **gitops/**: ArgoCD manifests (AppOfApps + sub-apps)
  - **core/**: Core kernel services (metadata, policy)
  - **modules/**: PoP modules (ingestion, messaging, feature store, etc.)
- **helm/**: Shared Helm values and umbrella charts
- **requirements.txt**: Python dependencies
