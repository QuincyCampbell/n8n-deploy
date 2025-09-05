FROM n8nio/n8n:latest

# Switch to root for setup
USER root

# Install debugging tools and gosu
RUN apk add --no-cache bash curl jq gosu

# Create necessary directories
RUN mkdir -p /opt/n8n/.n8n/workflows && \
    mkdir -p /tmp/workflows-source && \
    chown -R node:node /opt/n8n/.n8n

# Copy workflow files into container
COPY --chown=node:node workflows/ /tmp/workflows-source/
RUN ls -la /tmp/workflows-source/ && echo "Files copied successfully"
RUN chmod -R 755 /tmp/workflows-source/

# Create custom entrypoint script
RUN echo '#!/bin/bash' > /docker-entrypoint-custom.sh && \
    echo 'set -e' >> /docker-entrypoint-custom.sh && \
    echo 'echo "🚀 Starting custom n8n entrypoint..."' >> /docker-entrypoint-custom.sh && \
    echo 'echo "📊 Environment:"' >> /docker-entrypoint-custom.sh && \
    echo 'echo "   - User: $(whoami)"' >> /docker-entrypoint-custom.sh && \
    echo 'echo "   - N8N_USER_FOLDER: ${N8N_USER_FOLDER}"' >> /docker-entrypoint-custom.sh && \
    echo 'echo "🔍 Checking for workflows to import..."' >> /docker-entrypoint-custom.sh && \
    echo 'if [ -d "/tmp/workflows-source" ]; then' >> /docker-entrypoint-custom.sh && \
    echo '    echo "📁 Source directory contents:"' >> /docker-entrypoint-custom.sh && \
    echo '    ls -la /tmp/workflows-source/' >> /docker-entrypoint-custom.sh && \
    echo '    JSON_COUNT=$(find /tmp/workflows-source -name "*.json" -type f | wc -l)' >> /docker-entrypoint-custom.sh && \
    echo '    echo "📦 Found $JSON_COUNT JSON workflow files"' >> /docker-entrypoint-custom.sh && \
    echo '    if [ "$JSON_COUNT" -gt 0 ]; then' >> /docker-entrypoint-custom.sh && \
    echo '        echo "📥 Importing workflows..."' >> /docker-entrypoint-custom.sh && \
    echo '        n8n import:workflow --input=/tmp/workflows-source --overwrite || echo "❌ Workflow import failed"' >> /docker-entrypoint-custom.sh && \
    echo '    else' >> /docker-entrypoint-custom.sh && \
    echo '        echo "📝 No workflows found to import"' >> /docker-entrypoint-custom.sh && \
    echo '    fi' >> /docker-entrypoint-custom.sh && \
    echo 'else' >> /docker-entrypoint-custom.sh && \
    echo '    echo "❌ Source workflows directory not found!"' >> /docker-entrypoint-custom.sh && \
    echo 'fi' >> /docker-entrypoint-custom.sh && \
    echo 'echo "🎯 Starting n8n..."' >> /docker-entrypoint-custom.sh && \
    echo 'exec n8n start "$@"' >> /docker-entrypoint-custom.sh

# Make script executable
RUN chmod +x /docker-entrypoint-custom.sh

# Switch back to node user
USER node

# Environment variables
ENV N8N_USER_FOLDER=/opt/n8n/.n8n
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV N8N_RUNNERS_ENABLED=true

# Expose port
EXPOSE 5678

# Use custom entrypoint
ENTRYPOINT ["/docker-entrypoint-custom.sh"]
