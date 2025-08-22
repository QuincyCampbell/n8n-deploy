FROM n8nio/n8n:latest

# Switch to root for setup
USER root

# Install debugging tools and gosu
RUN apk add --no-cache bash curl jq gosu

# Create all necessary directories
RUN mkdir -p /opt/n8n/.n8n/workflows && \
    mkdir -p /tmp/workflows-source && \
    chown -R node:node /opt/n8n/.n8n

# Copy ALL files from workflows directory (with better permissions)
COPY --chown=node:node workflows/ /tmp/workflows-source/
RUN chmod -R 755 /tmp/workflows-source/

# Create startup script using echo method
RUN echo '#!/bin/bash' > /docker-entrypoint-custom.sh && \
    echo 'set -e' >> /docker-entrypoint-custom.sh && \
    echo 'echo "🚀 Custom n8n Startup"' >> /docker-entrypoint-custom.sh && \
    echo 'echo "📊 Environment Check:"' >> /docker-entrypoint-custom.sh && \
    echo 'echo "   - User: $(whoami)"' >> /docker-entrypoint-custom.sh && \
    echo 'echo "   - N8N_USER_FOLDER: ${N8N_USER_FOLDER}"' >> /docker-entrypoint-custom.sh && \
    echo 'echo "🔍 Looking for workflows to import..."' >> /docker-entrypoint-custom.sh && \
    echo 'if [ -d "/tmp/workflows-source" ]; then' >> /docker-entrypoint-custom.sh && \
    echo '    JSON_COUNT=$(find /tmp/workflows-source -name "*.json" -type f 2>/dev/null | wc -l)' >> /docker-entrypoint-custom.sh && \
    echo '    echo "📦 Found $JSON_COUNT JSON files"' >> /docker-entrypoint-custom.sh && \
    echo '    if [ "$JSON_COUNT" -gt 0 ]; then' >> /docker-entrypoint-custom.sh && \
    echo '        echo "📥 Importing workflows into n8n..."' >> /docker-entrypoint-custom.sh && \
    echo '        n8n import:workflow --input=/tmp/workflows-source --overwrite || echo "❌ Workflow import failed"' >> /docker-entrypoint-custom.sh && \
    echo '    else' >> /docker-entrypoint-custom.sh && \
    echo '        echo "📝 No workflow JSON files found"' >> /docker-entrypoint-custom.sh && \
    echo '    fi' >> /docker-entrypoint-custom.sh && \
    echo 'else' >> /docker-entrypoint-custom.sh && \
    echo '    echo "❌ No source workflows directory found"' >> /docker-entrypoint-custom.sh && \
    echo 'fi' >> /docker-entrypoint-custom.sh && \
    echo 'echo "🎯 Starting n8n..."' >> /docker-entrypoint-custom.sh && \
    echo 'exec n8n start "$@"' >> /docker-entrypoint-custom.sh

# Make script executable
RUN chmod +x /docker-entrypoint-custom.sh

# Switch back to node user as default
USER node

# Environment variables
ENV N8N_USER_FOLDER=/opt/n8n/.n8n
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV N8N_RUNNERS_ENABLED=true
ENV N8N_TRUST_PROXY=true

# Expose port
EXPOSE 5678

# Use custom entrypoint
ENTRYPOINT ["/docker-entrypoint-custom.sh"]
