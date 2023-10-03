#!/bin/bash

# This script needs kubectl and helm to be installed and set in path.
# Install kubectl https://kubernetes.io/docs/tasks/tools/
# Install helm https://helm.sh/docs/intro/install/
# Install appropriate versions of kubectl and helm based on your kubernetes control plane version.


# Default values
CLEAN_CRD=true
NAMESPACE=""
CHART_NAME="vm-k8s-stack"

# List of CRDs to delete
CRD_LIST="vmusers.operator.victoriametrics.com
vmrules.operator.victoriametrics.com
vmnodescrapes.operator.victoriametrics.com
vmauths.operator.victoriametrics.com
vmservicescrapes.operator.victoriametrics.com
vmpodscrapes.operator.victoriametrics.com
vmprobes.operator.victoriametrics.com
vmalertmanagers.operator.victoriametrics.com
vmalerts.operator.victoriametrics.com
vmsingles.operator.victoriametrics.com
vmalertmanagerconfigs.operator.victoriametrics.com
vmstaticscrapes.operator.victoriametrics.com
vmclusters.operator.victoriametrics.com
vmagents.operator.victoriametrics.com"

# Delete ConfigMap created for kube-state-metrics and secret created for PMM API key
cleanup_k8s_objects() {   
    echo "Deleting configmap \"customresource-config-ksm\""
    kubectl delete configmap customresource-config-ksm -n $NAMESPACE
    echo "Deleting secret \"pmm-token-vmoperator\""
    kubectl delete secret pmm-token-vmoperator -n $NAMESPACE
}

# Uninstall helm chart installed for victoria metrics k8s stack
uninstall_helm_chart() {
    echo "Uninstalling Helm chart: $CHART_NAME in Namespace: $NAMESPACE"   
    # Prompt the user for confirmation
    read -p "Do you want to continue (y/n)? " -n 1 -r
    echo    # Move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation canceled."
        exit 0
    fi 
    helm uninstall $CHART_NAME   
}

# Clean up Victoria metrics operator CRD
cleanup_crd() {

    # Delete CRDs if the --clean-crd flag is set
    if [ "$CLEAN_CRD" = true ]; then
    # Display the list of CRDs to be deleted
    echo "The following CRDs will be deleted:"
    for CRD in $CRD_LIST; do
        echo "- $CRD"
    done
    # Prompt the user for confirmation
    read -p "Do you want to continue (y/n)? " -n 1 -r
    echo    # Move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation canceled."
        exit 0
    fi     
    echo "Cleaning CRDs"
    for CRD in $CRD_LIST; do
        kubectl delete crd "$CRD"
    done
    else
    echo "Not cleaning CRDs"
    fi    

}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    --keep-crd)
      CLEAN_CRD=false
      shift
      ;;
    --chart-name)
      CHART_NAME="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

# Check if the --namespace argument is provided
if [ -z "$NAMESPACE" ]; then
  echo "Usage: $0 --namespace <NAMESPACE> [--clean-crd] [--chart-name <HELM-CHART-NAME>]"
  exit 1
fi

# Cleanup Configmap and Secret
cleanup_k8s_objects

# Uninstall Helm Chart
uninstall_helm_chart

# Clean up CRD 
cleanup_crd


