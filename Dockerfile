FROM n8nio/n8n:latest

# Switch to root for setup
USER root

# Install required packages
RUN apk add --no-cache bash curl jq gosu

# Create necessary directories with proper ownership
RUN mkdir -p /home/node/.n8n/workflows && \
    mkdir -p /tmp/workflows-source && \
    chown -R node:node /home/node/.n8n

# Copy workflow files if they exist
COPY workflows/*.json /tmp/workflows-source/ 2>/dev/null || echo "No workflow files to copy"
RUN chown -R node:node /tmp/workflows-source/ 2>/dev/null || true

# Create enhanced entrypoint script with secret file support
RUN cat > /docker-entrypoint-custom.sh << 'EOF'
#!/bin/bash
set -e

echo "Starting n8n deployment with secret file support..."

# Load secrets from Render secret file if it exists
if [ -f "/etc/secrets/n8n-secrets.env" ]; then
    echo "Loading secrets from secret file..."
    set -a  # automatically export all variables
    source /etc/secrets/n8n-secrets.env
    set +a  # stop automatically exporting
    echo "Secrets loaded successfully"
else
    echo "No secret file found, using environment variables only"
fi

# Display environment info (without sensitive data)
echo "Environment configuration:"
echo "  - N8N_HOST: ${N8N_HOST}"
echo "  - N8N_PORT: ${N8N_PORT}"
echo "  - N8N_PROTOCOL: ${N8N_PROTOCOL}"
echo "  - N8N_LOG_LEVEL: ${N8N_LOG_LEVEL}"
echo "  - Basic Auth Active: ${N8N_BASIC_AUTH_ACTIVE}"
echo "  - Trust Proxy: ${N8N_TRUST_PROXY}"

# Import workflows if they exist
if [ -d "/tmp/workflows-source" ] && [ "$(ls -A /tmp/workflows-source 2>/dev/null)" ]; then
    echo "Found workflows to import..."
    ls -la /tmp/workflows-source/
    echo "Importing workflows..."
    gosu node n8n import:workflow --input=/tmp/workflows-source --overwrite || echo "Import failed, continuing..."
else
    echo "No workflows to import"
fi

echo "Starting n8n server..."
exec gosu node n8n start "$@"
EOF

# Make script executable
RUN chmod +x /docker-entrypoint-custom.sh

# Switch back to node user
USER node

# Set working directory
WORKDIR /home/node

# Use custom entrypoint
ENTRYPOINT ["/docker-entrypoint-custom.sh"]
