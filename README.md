# Coder on VKS (vSphere Kubernetes Service) POC

Welcome to the Coder POC repository! This project scaffolds a complete Cloud Development Environment platform using [Coder](https://coder.com/) on a VKS cluster. It is designed specifically to provision a browser-based VS Code workspace for developers, saving their work securely on Persistent Volumes.

---

## Architecture Overview

- **Control Plane**: Deployed via Helm into the `coder` namespace. Exposed via a Kubernetes `LoadBalancer` Service.
- **Workspace Template**: Terraform-based template (`templates/k8s-vscode`) that defines:
  - A Kubernetes Pod running Ubuntu (`codercom/enterprise-base:ubuntu`).
  - A Persistent Volume Claim (PVC) mounted to `/home/coder`.
  - A Coder Agent that automatically installs and starts `code-server` (Browser-based VS Code).

---

## Step-by-Step Execution Guide

Follow these steps to deploy the Coder control plane and push the workspace template to your cluster.

### 1. Verify VKS Cluster Connection

Ensure your local environment is authenticated to your VKS cluster. You should be able to see the cluster nodes.

```bash
kubectl get nodes
```
*(You should see a list of your VKS worker nodes in a `Ready` state.)*

### 2. Install the Coder Control Plane

We have provided a bash script that automates the Helm installation. It sets up the required repositories, creates the `coder` namespace, and deploys the control plane.

Make the script executable and run it:

```bash
chmod +x deploy/install.sh
./deploy/install.sh
```

### 3. Access the Coder Dashboard

Because we configured the service type as `LoadBalancer` in `deploy/coder-values.yaml`, VKS will provision an external IP for the Coder UI.

Retrieve the LoadBalancer IP address:

```bash
kubectl get svc coder -n coder
```

Look for the `EXTERNAL-IP` column.
- Open your web browser and navigate to: `http://<EXTERNAL-IP>`
- Create your initial admin user and password.
- When prompted for the "Access URL", confirm it is set to `http://<EXTERNAL-IP>`.

### 4. Install the CLI, Log in, and Create the Template

To make the VS Code workspace available to developers, we need to push our Terraform template (`templates/k8s-vscode`) to the Coder control plane.

**A. Install the Coder CLI**
```bash
curl -L https://coder.com/install.sh | sh
```

**B. Log in to your Coder deployment**
*(Replace `<EXTERNAL-IP>` with the IP you retrieved in Step 3)*
```bash
coder login http://<EXTERNAL-IP>
```
*(A browser window will open. Follow the prompts to authenticate and copy your session token.)*

**C. Push the Workspace Template**
Navigate to the repository root and create the template:

```bash
coder templates create k8s-vscode --directory ./templates/k8s-vscode
```

Follow the CLI prompts:
- It will ask to confirm the template name.
- It will read the `variables.tf` and may prompt you to set default values for CPU, Memory, and PVC size (you can accept the defaults).
- Once complete, developers can log into the Coder Dashboard, click **Create Workspace**, select the `k8s-vscode` template, and start coding in a browser-based VS Code environment!

---

## Customizing the Template

If you need to adjust resource limits (CPU, RAM) or the storage size for future workspaces, edit the `templates/k8s-vscode/variables.tf` file and then run:

```bash
coder templates push k8s-vscode --directory ./templates/k8s-vscode
```
