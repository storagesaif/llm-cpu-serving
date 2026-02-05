#!/bin/bash
set -e

# Configuration
PROJECT_NAME="hr-assistant"
NAMESPACE=${PROJECT_NAME}
REPO_URL="https://github.com/storagesaif/llm-cpu-serving.git"

echo "🚀 Starting GitOps Bootstrap for ${PROJECT_NAME}..."

# 1. Install OpenShift GitOps Operator
echo "📦 Installing Red Hat OpenShift GitOps Operator..."
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-gitops-operator
  namespace: openshift-operators
spec:
  channel: latest
  installPlanApproval: Automatic
  name: openshift-gitops-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

echo "⏳ Waiting for Operator to be ready (this may take a minute)..."
sleep 30

# 2. Create the project namespace
echo "🏗️ Creating project namespace: ${NAMESPACE}..."
oc new-project ${NAMESPACE} || echo "Namespace already exists"

# 3. Label namespace for ArgoCD management
echo "🏷️ Labeling namespace for ArgoCD..."
oc label namespace ${NAMESPACE} argocd.argoproj.io/managed-by=openshift-gitops --overwrite

# 4. Install Application with GitOps enabled
echo "☸️ Installing Application via Helm with GitOps enabled..."
helm upgrade --install ${PROJECT_NAME} helm/ \
  --namespace ${NAMESPACE} \
  --set gitops.enabled=true \
  --set gitops.repoURL=${REPO_URL}

echo "✅ GitOps Bootstrap Complete!"
echo "------------------------------------------------"
echo "ArgoCD URL: https://$(oc get route cluster -n openshift-gitops -o jsonpath='{.spec.host}')"
echo "Admin Password: $(oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-)"
echo "------------------------------------------------"
