FROM n8nio/n8n:latest

# Switch to root for setup
USER root

# Install debugging tools
RUN apk add --no-cache bash curl jq

# Create necessary directories and set permissions
RUN mkdir -p /home/node/.n8n/workflows && \
    mkdir -p /tmp/workflows-source && \
    chown -R node:node /home/node/.n8n

# Copy workflow files if they exist
COPY workflows/*.json /tmp/workflows-source/ 2>/dev/null || echo "No workflow files found"
RUN chown -R node:node /tmp/workflows-source/ || true

# Create optimized entrypoint script
RUN cat > /docker-entrypoint-custom.sh << 'EOF'
#!/bin/bash
set -e

echo "Starting n8n deployment..."

# Import workflows if they exist
if [ -d "/tmp/workflows-source" ] && [ "$(ls -A /tmp/workflows-source 2>/dev/null)" ]; then
    echo "Importing workflows..."
    gosu node n8n import:workflow --input=/tmp/workflows-source --overwrite || echo "Import failed, continuing..."
else
    echo "No workflows to import"
fi

echo "Starting n8n server..."
exec gosu node n8n start
EOF

# Make script executable
RUN chmod +x /docker-entrypoint-custom.sh

# Switch back to node user for runtime
USER node

# Set working directory
WORKDIR /home/node

# Use custom entrypoint
ENTRYPOINT ["/docker-entrypoint-custom.sh"]
