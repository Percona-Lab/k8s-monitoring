#!/bin/bash

# This script needs kubectl and helm to be installed and set in path.
# Install kubectl https://kubernetes.io/docs/tasks/tools/
# Install helm https://helm.sh/docs/intro/install/
# Install appropriate versions of kubectl and helm based on your kubernetes control plane version.

# Initialize variables with default values
NODE_EXPORTER_ENABLED=false
HELM_CHART_VERSION="0.17.5"


# Create Kubernetes namespace if it doesn't exist
create_namespace_if_not_exists() {
    local namespace="$1"
    if ! kubectl get namespace "$namespace" &>/dev/null; then
        echo "Namespace '$namespace' not found. Creating..."
        kubectl create namespace "$namespace"
    fi
}

# Create Configmap for Kube-state-metrics to capture custom resource metrics and create k8s secret from API key
setup_prerequisites() {
    local api_key="$1"
    echo "Creating configmap for kube-state-metrics configuration"
    kubectl apply -f https://raw.githubusercontent.com/Percona-Lab/k8s-monitoring/main/vm-operator-k8s-stack/ksm-configmap.yaml -n $NAMESPACE
    echo "Creating secret with PMM API Key"
    kubectl create secret generic pmm-token-vmoperator --from-literal=api_key="$api_key" -n $NAMESPACE
}

install_helm_chart() {
    local url="$1"
    # Add Helm Repos
    echo "Adding Helm Repos"
    helm repo add grafana https://grafana.github.io/helm-charts; \
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts; \
        helm repo add vm https://victoriametrics.github.io/helm-charts/; \
        helm repo update

    # Install Helm Chart
    echo "Installing victoria metrics k8s stack chart, version: $HELM_CHART_VERSION"
    helm install vm-k8s-stack vm/victoria-metrics-k8s-stack \
        -f https://raw.githubusercontent.com/Percona-Lab/k8s-monitoring/main/vm-operator-k8s-stack/values.yaml \
        --set externalVM.write.url=${url}/victoriametrics/api/v1/write \
        --set prometheus-node-exporter.enabled=$NODE_EXPORTER_ENABLED \
        --set vmagent.spec.externalLabels.k8s_cluster_id=$K8S_CLUSTER_ID \
        -n $NAMESPACE --version $HELM_CHART_VERSION
  

}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --api-key)
            API_KEY="$2"
            shift 2
            ;;
        --pmm-server-url)
            PMM_SERVER_URL="$2"
            shift 2
            ;;
        --k8s-cluster-id)
            K8S_CLUSTER_ID="$2"
            shift 2
            ;;
        --node-exporter-enabled)
            NODE_EXPORTER_ENABLED=true
            shift
            ;;
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --chart-version)
            HELM_CHART_VERSION="$2"
            shift 2
            ;;            
        *)
            echo "Unknown argument: $1"
			echo "Usage: $0 --api-key <API_KEY> --pmm-server-url <PMM_SERVER_URL> --k8s-cluster-id <K8S_CLUSTER_ID> --namespace <NAMESPACE> [--node-exporter-enabled] [--chart-version <chart-version>]"
            exit 1
            ;;
    esac
done

# Check for mandatory arguments
if [[ -z $API_KEY || -z $PMM_SERVER_URL || -z $K8S_CLUSTER_ID || -z $NAMESPACE ]]; then
    echo "Usage: $0 --api-key <API_KEY> --pmm-server-url <PMM_SERVER_URL> --k8s-cluster-id <K8S_CLUSTER_ID> --namespace <NAMESPACE> [--node-exporter-enabled] "
    exit 1
fi
 
# Create Kubernetes namespace if needed
create_namespace_if_not_exists "$NAMESPACE"

# Setup Prerequisites
setup_prerequisites "$API_KEY"

# Install Helm Chart ""
install_helm_chart "$PMM_SERVER_URL" 

echo "Complete"
