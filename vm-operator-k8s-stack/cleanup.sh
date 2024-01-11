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

    while true; do
        read -p "Do you wish to continue? (y/n) " inp
        case $inp in
            [Yy] ) break;;
            [Nn] ) echo "Operation Cancelled";exit;;
	    * ) echo "Please provide input (y/n)";;
        esac
    done

    helm uninstall $CHART_NAME -n $NAMESPACE
    echo "Uninstalled Helm chart: $CHART_NAME in Namespace: $NAMESPACE"
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
    fi    
    while true; do
        read -p "Do you wish to continue? (y/n) " inp
        case $inp in
            [Yy] ) echo "Cleaning CRD" ; break;;
            [Nn] ) echo "Not Cleaning CRD";exit 0;;
	    * ) echo "Please provide input (y/n)";;
        esac
    done
    for CRD in $CRD_LIST; do
        kubectl delete crd "$CRD"
    done    
    echo "Deleted the CRD"

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
  echo "Usage: $0 --namespace <NAMESPACE> [--keep-crd] [--chart-name <HELM-CHART-NAME>]"
  exit 1
fi

# Cleanup Configmap and Secret
cleanup_k8s_objects

# Uninstall Helm Chart
uninstall_helm_chart

# Clean up CRD 
cleanup_crd


