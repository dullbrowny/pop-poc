#!/usr/bin/env bash
set -euo pipefail

echo "## Bootstrapping Local PoP Demo on MacBook (Clean Start) ##"

# 1. Delete any old 'pop-demo' cluster
echo "🗑️  Deleting any old 'pop-demo' cluster…"
kind delete cluster --name pop-demo || true

# 2. Clean up Docker
echo "🧹 Cleaning up Docker…"
docker rm -f pop-demo-control-plane pop-demo-worker 2>/dev/null || true
docker system prune -af 2>/dev/null || true

# 3. Create new Kind cluster
echo "➕ Creating new 'pop-demo' cluster…"
cat <<EOF | kind create cluster --name pop-demo --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
EOF

# 4. Switch kubectl context
echo "🔀 Setting kubectl context to kind-pop-demo"
kubectl config use-context kind-pop-demo

# 5. Add & update Helm repos
echo "🔄 Adding/updating Helm repos…"
helm repo add argo       https://argoproj.github.io/argo-helm --force-update
helm repo add codecentric https://codecentric.github.io/helm-charts --force-update
helm repo add bitnami    https://charts.bitnami.com/bitnami --force-update
helm repo add strimzi    https://strimzi.io/charts/       --force-update
helm repo add airbyte    https://airbytehq.github.io/helm-charts --force-update
helm repo add minio      https://charts.min.io/          --force-update
helm repo update

# 6. Install ArgoCD
echo "🚀 Installing ArgoCD…"
kubectl create namespace argocd || true
helm upgrade --install argocd argo/argo-cd --namespace argocd

# 7. Install Keycloak
echo "🚀 Installing Keycloak…"
kubectl create namespace auth || true
helm upgrade --install keycloak codecentric/keycloak --namespace auth \
  --set keycloak.username=admin \
  --set keycloak.password=Admin123!

# 8. Install Neo4j
echo "🚀 Installing Neo4j…"
kubectl create namespace metadata || true
helm upgrade --install neo4j bitnami/neo4j --namespace metadata \
  --set auth.username=demo \
  --set auth.password=Demo123 \
  --set resources.requests.cpu=500m \
  --set resources.requests.memory=512Mi \
  --set resources.limits.cpu=1 \
  --set resources.limits.memory=1Gi \
  --set service.type=ClusterIP \
  --set neo4j.advertisedHost=neo4j.metadata.svc.cluster.local

# 9. Install Apache Atlas
echo "🚀 Installing Apache Atlas…"
kubectl create namespace metadata || true
kubectl apply -n metadata -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: atlas
  namespace: metadata
spec:
  replicas: 1
  selector:
    matchLabels:
      app: atlas
  template:
    metadata:
      labels:
        app: atlas
    spec:
      containers:
      - name: atlas
        image: sburn/apache-atlas:2.3.0
        imagePullPolicy: IfNotPresent
        env:
        - name: ATLAS_STORAGE_HOSTNAME
          value: "neo4j.metadata.svc.cluster.local"
        - name: ATLAS_STORAGE_USERNAME
          value: "demo"
        - name: ATLAS_STORAGE_PASSWORD
          value: "Demo123"
        ports:
        - containerPort: 21000
EOF
kubectl apply -n metadata -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: atlas
  namespace: metadata
spec:
  selector:
    app: atlas
  ports:
  - protocol: TCP
    port: 21000
    targetPort: 21000
EOF

# 10. Install Strimzi & Kafka
echo "🚀 Installing Strimzi & Kafka…"
kubectl create namespace kafka || true
helm upgrade --install strimzi strimzi/strimzi-kafka-operator --namespace kafka
kubectl apply -n kafka -f - <<EOF
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: my-cluster
  namespace: kafka
spec:
  kafka:
    replicas: 1
    listeners:
    - name: plain
      port: 9092
      tls: false
      type: internal
    storage:
      type: ephemeral
  zookeeper:
    replicas: 1
    storage:
      type: ephemeral
EOF

# 11. Install Airbyte
echo "🚀 Installing Airbyte…"
kubectl create namespace airbyte || true
helm upgrade --install airbyte airbyte/airbyte --namespace airbyte --no-hooks

# 12. Install MinIO
# Skipping Helm post-install hooks to avoid readiness timeouts
kubectl create namespace storage || true
helm upgrade --install minio minio/minio --namespace storage \
  --set accessKey.password=minio \
  --set secretKey.password=minio123 \
  --set resources.requests.cpu=250m \
  --set resources.requests.memory=256Mi \
  --no-hooks

# Completion message
echo "✅ Bootstrap complete!"
echo "Verify pods and apps:"
echo "  kubectl get pods --all-namespaces"
echo "  kubectl get applications.argoproj.io -n argocd"

