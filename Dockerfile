FROM n8nio/n8n:latest

# Switch to root for setup
USER root

# Install required packages
RUN apk add --no-cache bash curl jq gosu

# Create necessary directories with proper ownership
RUN mkdir -p /home/node/.n8n/workflows && \
    mkdir -p /tmp/workflows-source && \
    chown -R node:node /home/node/.n8n

# Copy workflow files if they exist (safer approach)
RUN mkdir -p /tmp/workflows-source
COPY workflows/ /tmp/workflows-source/ 2>/dev/null || echo "No workflows directory found"
RUN chown -R node:node /tmp/workflows-source/ 2>/dev/null || true

# Create enhanced entrypoint script with secret file support
RUN echo '#!/bin/bash' > /docker-entrypoint-custom.sh && \
    echo 'set -e' >> /docker-entrypoint-custom.sh && \
    echo '' >> /docker-entrypoint-custom.sh && \
    echo 'echo "Starting n8n deployment with secret file support..."' >> /docker-entrypoint-custom.sh && \
    echo '' >> /docker-entrypoint-custom.sh && \
    echo '# Load secrets from Render secret file if it exists' >> /docker-entrypoint-custom.sh && \
    echo 'if [ -f "/etc/secrets/n8n-secrets.env" ]; then' >> /docker-entrypoint-custom.sh && \
    echo '    echo "Loading secrets from secret file..."' >> /docker-entrypoint-custom.sh && \
    echo '    set -a  # automatically export all variables' >> /docker-entrypoint-custom.sh && \
    echo '    source /etc/secrets/n8n-secrets.env' >> /docker-entrypoint-custom.sh && \
    echo '    set +a  # stop automatically exporting' >> /docker-entrypoint-custom.sh && \
    echo '    echo "Secrets loaded successfully"' >> /docker-entrypoint-custom.sh && \
    echo 'else' >> /docker-entrypoint-custom.sh && \
    echo '    echo "No secret file found, using environment variables only"' >> /docker-entrypoint-custom.sh && \
    echo 'fi' >> /docker-entrypoint-custom.sh && \
    echo '' >> /docker-entrypoint-custom.sh && \
    echo '# Display environment info (without sensitive data)' >> /docker-entrypoint-custom.sh && \
    echo 'echo "Environment configuration:"' >> /docker-entrypoint-custom.sh && \
    echo 'echo "  - N8N_HOST: ${N8N_HOST}"' >> /docker-entrypoint-custom.sh && \
    echo 'echo "  - N8N_PORT: ${N8N_PORT}"' >> /docker-entrypoint-custom.sh && \
    echo 'echo "  - N8N_PROTOCOL: ${N8N_PROTOCOL}"' >> /docker-entrypoint-custom.sh && \
    echo 'echo "  - N8N_LOG_LEVEL: ${N8N_LOG_LEVEL}"' >> /docker-entrypoint-custom.sh && \
    echo 'echo "  - Basic Auth Active: ${N8N_BASIC_AUTH_ACTIVE}"' >> /docker-entrypoint-custom.sh && \
    echo 'echo "  - Trust Proxy: ${N8N_TRUST_PROXY}"' >> /docker-entrypoint-custom.sh && \
    echo '' >> /docker-entrypoint-custom.sh && \
    echo '# Import workflows if they exist' >> /docker-entrypoint-custom.sh && \
    echo 'if [ -d "/tmp/workflows-source" ] && [ "$(find /tmp/workflows-source -name '"'"'*.json'"'"' 2>/dev/null)" ]; then' >> /docker-entrypoint-custom.sh && \
    echo '    echo "Found workflows to import..."' >> /docker-entrypoint-custom.sh && \
    echo '    ls -la /tmp/workflows-source/' >> /docker-entrypoint-custom.sh && \
    echo '    echo "Importing workflows..."' >> /docker-entrypoint-custom.sh && \
    echo '    gosu node n8n import:workflow --input=/tmp/workflows-source --overwrite || echo "Import failed, continuing..."' >> /docker-entrypoint-custom.sh && \
    echo 'else' >> /docker-entrypoint-custom.sh && \
    echo '    echo "No workflows to import"' >> /docker-entrypoint-custom.sh && \
    echo 'fi' >> /docker-entrypoint-custom.sh && \
    echo '' >> /docker-entrypoint-custom.sh && \
    echo 'echo "Starting n8n server..."' >> /docker-entrypoint-custom.sh && \
    echo 'exec gosu node n8n start "$@"' >> /docker-entrypoint-custom.sh

# Make script executable
RUN chmod +x /docker-entrypoint-custom.sh

# Switch back to node user
USER node

# Set working directory
WORKDIR /home/node

# Use custom entrypoint
ENTRYPOINT ["/docker-entrypoint-custom.sh"]
