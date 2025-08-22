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
RUN cat > /usr/local/bin/copy-workflows.sh << 'EOF'
#!/bin/sh
set -e

echo "🚀 n8n Custom Entrypoint"
echo "📊 Debug info:"
echo "   - Current user: $(whoami)"
echo "   - N8N_USER_FOLDER: ${N8N_USER_FOLDER}"
echo "   - Workflows temp dir: /tmp/workflows"
echo "   - Target workflows dir: /opt/n8n/.n8n/workflows"

# List contents of temp directory for debugging
echo "   - Contents of /tmp/workflows:"
ls -la /tmp/workflows/ 2>/dev/null || echo "   - /tmp/workflows directory not accessible"

# Ensure target directory exists and has correct permissions
mkdir -p /opt/n8n/.n8n/workflows
chown -R node:node /opt/n8n/.n8n/workflows

echo "📦 Copying workflows..."

# Check if source directory exists and has files
if [ -d "/tmp/workflows" ]; then
    WORKFLOW_COUNT=$(find /tmp/workflows -name "*.json" -type f 2>/dev/null | wc -l || echo "0")
    echo "   - Found ${WORKFLOW_COUNT} JSON files in /tmp/workflows"
    
    if [ "$WORKFLOW_COUNT" -gt 0 ]; then
        echo "   - Copying workflow files..."
        for workflow in /tmp/workflows/*.json; do
            if [ -f "$workflow" ]; then
                echo "   - Copying: $(basename "$workflow")"
                cp "$workflow" /opt/n8n/.n8n/workflows/ && echo "     ✅ Copied successfully" || echo "     ❌ Failed to copy"
            fi
        done
        
        # List what was copied
        echo "   - Files in target directory:"
        ls -la /opt/n8n/.n8n/workflows/ 2>/dev/null && echo "✅ Workflows copied successfully" || echo "❌ Failed to list target directory"
    else
        echo "📝 No JSON workflow files found to copy"
    fi
else
    echo "📝 No workflows directory found at /tmp/workflows"
fi

echo "🎯 Starting n8n..."
EOF

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
