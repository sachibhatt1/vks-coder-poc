# main.tf
# Core Terraform template to provision a Coder workspace on Kubernetes.

terraform {
  required_providers {
    # The coder provider allows us to interact with the Coder control plane.
    coder = {
      source  = "coder/coder"
      version = "~> 0.17.0" # Make sure to use a recent version
    }
    # The kubernetes provider is used to provision the actual workspace pod and PVC.
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "coder" {}

# Configure the Kubernetes provider.
# If use_kubeconfig is true, it uses your local ~/.kube/config.
# Otherwise, it attempts to use the in-cluster service account (default when run by Coder itself).
provider "kubernetes" {
  config_path = var.use_kubeconfig ? "~/.kube/config" : null
}

# Fetch information about the current workspace and the user who is provisioning it.
data "coder_workspace" "me" {}

# ====================================================================
# Workspace Agent
# ====================================================================
# The coder_agent runs inside the workspace pod and connects back to the Coder control plane.
resource "coder_agent" "main" {
  os   = "linux"
  arch = "amd64"

  # The startup script runs when the workspace starts.
  # Here we install and start code-server (VS Code in the browser) on port 13337.
  startup_script = <<EOT
    #!/bin/sh
    echo "Installing code-server..."
    curl -fsSL https://code-server.dev/install.sh | sh
    echo "Starting code-server..."
    code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &
  EOT

  # Define the applications that will appear as buttons in the Coder UI.
  display_apps {
    vscode          = false # Disable local desktop VS Code to focus on browser-based IDE for this POC
    vscode_insiders = false
    web_terminal    = true
    ssh_helper      = false
  }

  # Inject the user's Git configuration into the workspace environment.
  env = {
    GIT_AUTHOR_NAME     = data.coder_workspace.me.owner
    GIT_COMMITTER_NAME  = data.coder_workspace.me.owner
    GIT_AUTHOR_EMAIL    = data.coder_workspace.me.owner_email
    GIT_COMMITTER_EMAIL = data.coder_workspace.me.owner_email
  }
}

# Register the code-server application so developers can click a button to open their IDE.
resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "VS Code (Browser)"
  url          = "http://localhost:13337/?folder=/home/coder"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"
}

# ====================================================================
# Persistent Volume Claim (PVC)
# ====================================================================
# This PVC ensures that the developer's work (in /home/coder) persists across workspace restarts.
resource "kubernetes_persistent_volume_claim" "home" {
  metadata {
    name      = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}-home"
    namespace = var.workspace_namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-workspace"
      "app.kubernetes.io/instance" = "coder-workspace-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
      "app.kubernetes.io/part-of"  = "coder"
    }
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.pvc_size
      }
    }
  }
}

# ====================================================================
# Kubernetes Pod
# ====================================================================
# The actual workspace pod that runs the developer's environment.
resource "kubernetes_pod" "main" {
  # start_count is 1 when the workspace is running, and 0 when it's stopped.
  count = data.coder_workspace.me.start_count

  metadata {
    name      = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
    namespace = var.workspace_namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-workspace"
      "app.kubernetes.io/instance" = "coder-workspace-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
      "app.kubernetes.io/part-of"  = "coder"
    }
  }

  spec {
    # Run the pod as the 'coder' user (UID 1000)
    security_context {
      run_as_user = 1000
      fs_group    = 1000
    }

    container {
      name              = "dev"
      # Using an enterprise-base ubuntu image that works well out-of-the-box
      image             = "codercom/enterprise-base:ubuntu"
      image_pull_policy = "Always"
      
      # Execute the initialization script provided by the coder_agent resource
      command = ["sh", "-c", coder_agent.main.init_script]
      
      env {
        name  = "CODER_AGENT_TOKEN"
        value = coder_agent.main.token
      }

      resources {
        requests = {
          cpu    = "250m"
          memory = "512Mi"
        }
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
      }

      # Mount the PVC to /home/coder so all files are saved
      volume_mount {
        mount_path = "/home/coder"
        name       = "home"
        read_only  = false
      }
    }

    volume {
      name = "home"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.home.metadata[0].name
        read_only  = false
      }
    }
  }
}
