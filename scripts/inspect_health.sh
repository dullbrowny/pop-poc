# 1.1 Pods across all namespaces
kubectl get pods --all-namespaces

# 1.2 List all ArgoCD Applications
kubectl get applications.argoproj.io -n argocd

# 1.3 Look at the exact condition on the three problem apps
for APP in pop-root gatekeeper policy-app; do
  echo; echo "== $APP =="  
  kubectl describe application $APP -n argocd | grep -A3 "Conditions"
done

