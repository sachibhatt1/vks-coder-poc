#!/bin/bash

echo "Starting VCFA CloudShell Bootstrap..."

# Validate required environment variables
if [ -z "$VCFA_FQDN" ] || [ -z "$VCFA_TENANT" ] || [ -z "$VCFA_API_TOKEN" ]; then
    echo "WARNING: Missing required VCFA environment variables. Shell will start but might not be authenticated."
else
    # 1. Automatically configure the VCF CLI context using injected environment variables
    echo "Configuring VCF CLI context..."
    vcf context create my-tenant \
      --endpoint $VCFA_FQDN \
      --tenant-name $VCFA_TENANT \
      --api-token $VCFA_API_TOKEN \
      --type cci \
      --insecure-skip-tls-verify

    # 2. Set the default context so kubectl works instantly
    echo "Setting default context..."
    vcf context use my-tenant
fi

echo "Environment configured. Developer is ready to go!"
echo "Starting ttyd web terminal on port 8080..."

# 3. Launch ttyd to expose the bash shell on port 8080
# The -W flag makes ttyd writable.
exec ttyd -p 8080 -W bash
