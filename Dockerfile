FROM n8nio/n8n:latest

# Switch to root to create directories and setup workflow copying
USER root

# Create directories with correct permissions
RUN mkdir -p /opt/n8n/.n8n/workflows && \
    mkdir -p /tmp/workflows && \
    chown -R node:node /opt/n8n/.n8n && \
    chown -R node:node /tmp

# Copy workflow files to temporary location
COPY workflows/ /tmp/workflows/

# Create a simple workflow copy script that runs BEFORE n8n starts
RUN echo '#!/bin/sh' > /usr/local/bin/copy-workflows.sh && \
    echo 'echo "📦 Copying workflows..."' >> /usr/local/bin/copy-workflows.sh && \
    echo 'mkdir -p /opt/n8n/.n8n/workflows' >> /usr/local/bin/copy-workflows.sh && \
    echo 'if [ -d "/tmp/workflows" ] && [ "$(ls -A /tmp/workflows 2>/dev/null || true)" ]; then' >> /usr/local/bin/copy-workflows.sh && \
    echo '    cp /tmp/workflows/*.json /opt/n8n/.n8n/workflows/ 2>/dev/null || echo "No JSON files to copy"' >> /usr/local/bin/copy-workflows.sh && \
    echo '    echo "✅ Workflows copied"' >> /usr/local/bin/copy-workflows.sh && \
    echo 'else' >> /usr/local/bin/copy-workflows.sh && \
    echo '    echo "📝 No workflows found to copy"' >> /usr/local/bin/copy-workflows.sh && \
    echo 'fi' >> /usr/local/bin/copy-workflows.sh && \
    chmod +x /usr/local/bin/copy-workflows.sh

# Create a custom docker-entrypoint.sh that copies workflows then calls the original
RUN echo '#!/bin/sh' > /docker-entrypoint-custom.sh && \
    echo 'set -e' >> /docker-entrypoint-custom.sh && \
    echo 'echo "🚀 n8n Custom Entrypoint"' >> /docker-entrypoint-custom.sh && \
    echo '' >> /docker-entrypoint-custom.sh && \
    echo '# Copy workflows first' >> /docker-entrypoint-custom.sh && \
    echo '/usr/local/bin/copy-workflows.sh' >> /docker-entrypoint-custom.sh && \
    echo '' >> /docker-entrypoint-custom.sh && \
    echo '# Start n8n normally' >> /docker-entrypoint-custom.sh && \
    echo 'echo "🎯 Starting n8n..."' >> /docker-entrypoint-custom.sh && \
    echo 'exec n8n start "$@"' >> /docker-entrypoint-custom.sh && \
    chmod +x /docker-entrypoint-custom.sh

# Switch back to node user
USER node

# Set environment variables
ENV N8N_USER_FOLDER=/opt/n8n/.n8n
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678

# Expose port
EXPOSE 5678

# Use our custom entrypoint
ENTRYPOINT ["/docker-entrypoint-custom.sh"]
