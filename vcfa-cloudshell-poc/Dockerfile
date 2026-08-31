FROM ubuntu:24.04

# Install base tools and ttyd (Terminal over HTTP)
RUN apt-get update && apt-get install -y curl wget jq git ttyd

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl && mv kubectl /usr/local/bin/

# Install VCF CLI
# For this POC, we are copying a mock vcf binary/script. 
# In a real environment, replace this with the actual vcf binary download or copy.
COPY vcf /usr/local/bin/vcf
RUN chmod +x /usr/local/bin/vcf

# Add the bootstrap script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
