FROM n8nio/n8n:latest

# Switch to root to create directories and setup workflow copying
USER root

# Install jq for potential JSON processing
RUN apk add --no-cache jq bash

# Create directories with correct permissions
RUN mkdir -p /opt/n8n/.n8n/workflows && \
    mkdir -p /tmp/workflows && \
    chown -R node:node /opt/n8n/.n8n && \
    chown -R node:node /tmp

# Copy workflow files to temporary location (only if workflows directory exists)
COPY --chown=node:node workflows/ /tmp/workflows/ 

# Create a robust workflow copy script with better error handling
RUN echo '#!/bin/sh' > /usr/local/bin/copy-workflows.sh && \
    echo 'set -e' >> /usr/local/bin/copy-workflows.sh && \
    echo '' >> /usr/local/bin/copy-workflows.sh && \
    echo 'echo "🚀 n8n Custom Entrypoint"' >> /usr/local/bin/copy-workflows.sh && \
    echo 'echo "📊 Debug info:"' >> /usr/local/bin/copy-workflows.sh && \
    echo 'echo "   - Current user: $(whoami)"' >> /usr/local/bin/copy-workflows.sh && \
    echo 'echo "   - N8N_USER_FOLDER: $N8N_USER_FOLDER"' >> /usr/local/bin/copy-workflows.sh && \
    echo 'echo "   - Workflows temp dir: /tmp/workflows"' >> /usr/local/bin/copy-workflows.sh && \
    echo 'echo "   - Target workflows dir: /opt/n8n/.n8n/workflows"' >> /usr/local/bin/copy-workflows.sh && \
    echo '' >> /usr/local/bin/copy-workflows.sh && \
    echo '# List contents of temp directory for debugging' >> /usr/local/bin/copy-workflows.sh && \
    echo 'echo "   - Contents of /tmp/workflows:"' >> /usr/local/bin/copy-workflows.sh && \
    echo 'ls -la /tmp/workflows/ 2>/dev/null || echo "   - /tmp/workflows directory not accessible"' >> /usr/local/bin/copy-workflows.sh && \
    echo '' >> /usr/local/bin/copy-workflows.sh && \
    echo '# Ensure target directory exists and has correct permissions' >> /usr/local/bin/copy-workflows.sh && \
    echo 'mkdir -p /opt/n8n/.n8n/workflows' >> /usr/local/bin/copy-workflows.sh && \
    echo 'chown -R node:node /opt/n8n/.n8n/workflows' >> /usr/local/bin/copy-workflows.sh && \
    echo '' >> /usr/local/bin/copy-workflows.sh && \
    echo 'echo "📦 Copying workflows..."' >> /usr/local/bin/copy-workflows.sh && \
    echo '' >> /usr/local/bin/copy-workflows.sh && \
    echo '# Check if source directory exists and has files' >> /usr/local/bin/copy-workflows.sh && \
    echo 'if [ -d "/tmp/workflows" ]; then' >> /usr/local/bin/copy-workflows.sh && \
    echo '    WORKFLOW_COUNT=$(find /tmp/workflows -name "*.json" -type f 2>/dev/null | wc -l || echo "0")' >> /usr/local/bin/copy-workflows.sh && \
    echo '    echo "   - Found $WORKFLOW_COUNT JSON files in /tmp/workflows"' >> /usr/local/bin/copy-workflows.sh && \
    echo '    if [ "$WORKFLOW_COUNT" -gt 0 ]; then' >> /usr/local/bin/copy-workflows.sh && \
    echo '        echo "   - Copying workflow files..."' >> /usr/local/bin/copy-workflows.sh && \
    echo '        for workflow in /tmp/workflows/*.json; do' >> /usr/local/bin/copy-workflows.sh && \
    echo '            if [ -f "$workflow" ]; then' >> /usr/local/bin/copy-workflows.sh && \
    echo '                echo "   - Copying: $(basename "$workflow")"' >> /usr/local/bin/copy-workflows.sh && \
    echo '                cp "$workflow" /opt/n8n/.n8n/workflows/ && echo "     ✅ Copied successfully" || echo "     ❌ Failed to copy"' >> /usr/local/bin/copy-workflows.sh && \
    echo '            fi' >> /usr/local/bin/copy-workflows.sh && \
    echo '        done' >> /usr/local/bin/copy-workflows.sh && \
    echo '        echo "   - Files in target directory:"' >> /usr/local/bin/copy-workflows.sh && \
    echo '        ls -la /opt/n8n/.n8n/workflows/ 2>/dev/null && echo "✅ Workflows copied successfully" || echo "❌ Failed to list target directory"' >> /usr/local/bin/copy-workflows.sh && \
    echo '    else' >> /usr/local/bin/copy-workflows.sh && \
    echo '        echo "📝 No JSON workflow files found to copy"' >> /usr/local/bin/copy-workflows.sh && \
    echo '    fi' >> /usr/local/bin/copy-workflows.sh && \
    echo 'else' >> /usr/local/bin/copy-workflows.sh && \
    echo '    echo "📝 No workflows directory found at /tmp/workflows"' >> /usr/local/bin/copy-workflows.sh && \
    echo 'fi' >> /usr/local/bin/copy-workflows.sh && \
    echo '' >> /usr/local/bin/copy-workflows.sh && \
    echo 'echo "🎯 Starting n8n..."' >> /usr/local/bin/copy-workflows.sh

# Make the script executable
RUN chmod +x /usr/local/bin/copy-workflows.sh

# Switch back to node user for n8n execution
USER node

# Set environment variables
ENV N8N_USER_FOLDER=/opt/n8n/.n8n
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV N8N_RUNNERS_ENABLED=true

# Expose port
EXPOSE 5678

# Use our custom script to copy workflows then start n8n
CMD ["/bin/sh", "-c", "/usr/local/bin/copy-workflows.sh && exec n8n start"]
