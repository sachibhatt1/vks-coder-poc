# VCFA CloudShell Proof of Concept

This Proof of Concept demonstrates a **Time-to-First-Command** solution for VCF Automation by providing developers with an instant, pre-authenticated, in-browser terminal using vSphere Pods (Supervisor Pods).

## Architecture

1. **Docker Image**: Based on Ubuntu, loaded with `kubectl`, the `vcf` CLI (mocked for this POC), and `ttyd` (terminal over HTTP).
2. **Bootstrap Script (`entrypoint.sh`)**: Intercepts the user's API token via environment variables and executes `vcf context create` to pre-authenticate the shell session.
3. **vSphere Pod (`pod.yaml`)**: Deploys the CloudShell image, injects the developer's VCFA token securely using a Kubernetes Secret, and exposes it via a Service.

## Testing Locally with Docker

You can test the container image and `ttyd` locally before deploying to a cluster.

1. **Build the image**:
   ```bash
   cd vcfa-cloudshell-poc
   docker build -t vcfa-cloudshell:latest .
   ```

2. **Run the container**:
   ```bash
   docker run -p 8080:8080 \
     -e VCFA_FQDN=vcfa.corp.local \
     -e VCFA_TENANT=developer-org \
     -e VCFA_API_TOKEN=mock-token-123 \
     vcfa-cloudshell:latest
   ```

3. **Access the terminal**:
   Open a browser and navigate to `http://localhost:8080`.
   You will have a bash shell. Try running `kubectl get pods` (which will fail because it's a dummy context, but demonstrates the tool is installed) and look at the output from the mock `vcf` CLI in the bootstrap logs.

## Deploying to Kubernetes / vSphere Supervisor

1. **Load the image to your registry**:
   Push the `vcfa-cloudshell:latest` image to a registry accessible by your Supervisor cluster (e.g., Harbor). Update the `image` field in `pod.yaml` accordingly.

2. **Deploy the resources**:
   Ensure you have a namespace `my-vcfa-project-namespace` created. Since `pod.yaml` now uses template variables (`${USER_ID}`, `${VCFA_FQDN}`, `${VCFA_TENANT}`, `${VCFA_API_TOKEN}`) to support dynamic provisioning and multiple concurrent users, you can deploy it using `envsubst`:
   ```bash
   kubectl create namespace my-vcfa-project-namespace
   export USER_ID="jdoe"
   export VCFA_FQDN="vcfa.corp.local"
   export VCFA_TENANT="developer-org"
   export VCFA_API_TOKEN="mock-token-123"
   envsubst < pod.yaml | kubectl apply -f -
   ```

3. **Access the shell**:
   Get the external IP of the load balancer service for your specific user:
   ```bash
   kubectl get svc vcfa-cloudshell-jdoe-service -n my-vcfa-project-namespace
   ```
   Open `http://<EXTERNAL_IP>` in your browser.

## Next Steps for Production

- Replace the mock `vcf` CLI script with the actual binary during the Docker build.
- Integrate with vRealize Orchestrator (vRO) or VCFA extensibility to dynamically provision the token and `pod.yaml`.
- Secure the `ttyd` endpoint (e.g., adding an authentication proxy or relying on VCFA routing integration).
