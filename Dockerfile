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

# Create startup script using echo method (avoid heredoc issues)
RUN echo '#!/bin/bash' > /docker-entrypoint-custom.sh && \
    echo 'set -e' >> /docker-entrypoint-custom.sh && \
    echo 'echo "🚀 Custom n8n Startup"' >> /docker-entrypoint-custom.sh && \
    echo 'echo "📊 Environment Check:"' >> /docker-entrypoint-custom.sh && \
    echo 'echo "   - User: $(whoami)"' >> /docker-entrypoint-custom.sh && \
    echo 'echo "   - N8N_USER_FOLDER: ${N8N_USER_FOLDER}"' >> /docker-entrypoint-custom.sh && \
    echo 'echo "🔍 Looking for workflows to import..."' >> /docker-entrypoint-custom.sh && \
    echo 'if [ ! -d "/tmp/workflows-source" ]; then' >> /docker-entrypoint-custom.sh && \
    echo '    echo "❌ No source workflows directory found"' >> /docker-entrypoint-custom.sh && \
    echo '    echo "🐛 Debug: Checking what exists in /tmp/"' >> /docker-entrypoint-custom.sh && \
    echo '    ls -la /tmp/ || echo "Cannot list /tmp/"' >> /docker-entrypoint-custom.sh && \
    echo 'else' >> /docker-entrypoint-custom.sh && \
    echo '    echo "📁 Source directory contents:"' >> /docker-entrypoint-custom.sh && \
    echo '    ls -la /tmp/workflows-source/ || echo "Cannot list source"' >> /docker-entrypoint-custom.sh && \
    echo '    mkdir -p /opt/n8n/.n8n/workflows' >> /docker-entrypoint-custom.sh && \
    echo '    chown -R node:node /opt/n8n/.n8n' >> /docker-entrypoint-custom.sh && \
    echo '    JSON_COUNT=$(find /tmp/workflows-source -name "*.json" -type f 2>/dev/null | wc -l)' >> /docker-entrypoint-custom.sh && \
    echo '    echo "📦 Found $JSON_COUNT JSON files"' >> /docker-entrypoint-custom.sh && \
    echo '    if [ "$JSON_COUNT" -gt 0 ]; then' >> /docker-entrypoint-custom.sh && \
    echo '        echo "📥 Copying workflow files..."' >> /docker-entrypoint-custom.sh && \
    echo '        find /tmp/workflows-source -name "*.json" -type f | while read workflow; do' >> /docker-entrypoint-custom.sh && \
    echo '            filename=$(basename "$workflow")' >> /docker-entrypoint-custom.sh && \
    echo '            echo "   - Copying: $filename"' >> /docker-entrypoint-custom.sh && \
    echo '            cp "$workflow" "/opt/n8n/.n8n/workflows/" && echo "     ✅ Copied: $filename" || echo "     ❌ Failed: $filename"' >> /docker-entrypoint-custom.sh && \
    echo '        done' >> /docker-entrypoint-custom.sh && \
    echo '        chown -R node:node /opt/n8n/.n8n/workflows/' >> /docker-entrypoint-custom.sh && \
    echo '        echo "📋 Final workflow directory:"' >> /docker-entrypoint-custom.sh && \
    echo '        ls -la /opt/n8n/.n8n/workflows/ || echo "Cannot list target"' >> /docker-entrypoint-custom.sh && \
    echo '        echo "🎉 Workflow copy completed!"' >> /docker-entrypoint-custom.sh && \
    echo '    else' >> /docker-entrypoint-custom.sh && \
    echo '        echo "📝 No JSON workflow files found"' >> /docker-entrypoint-custom.sh && \
    echo '    fi' >> /docker-entrypoint-custom.sh && \
    echo 'fi' >> /docker-entrypoint-custom.sh && \
    echo 'echo "🎯 Starting n8n..."' >> /docker-entrypoint-custom.sh && \
    echo 'echo "=================================================="' >> /docker-entrypoint-custom.sh && \
    echo 'exec gosu node n8n start "$@"' >> /docker-entrypoint-custom.sh

# Make script executable
RUN chmod +x /docker-entrypoint-custom.sh

# Switch back to node user as default
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
