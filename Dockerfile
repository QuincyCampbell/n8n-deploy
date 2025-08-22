FROM n8nio/n8n:latest

# Switch to root for setup
USER root

# Install debugging tools
RUN apk add --no-cache bash curl jq

# Create all necessary directories
RUN mkdir -p /opt/n8n/.n8n/workflows && \
    mkdir -p /tmp/workflows-source && \
    chown -R node:node /opt/n8n/.n8n

# Copy ALL files from workflows directory (not just JSON)
COPY workflows/ /tmp/workflows-source/

# Create a comprehensive startup script that handles multiple scenarios
RUN cat > /docker-entrypoint-custom.sh << 'SCRIPT_END'
#!/bin/bash
set -e

echo "🚀 Custom n8n Startup"
echo "📊 Environment Check:"
echo "   - User: $(whoami)"
echo "   - N8N_USER_FOLDER: ${N8N_USER_FOLDER}"
echo "   - Current directory: $(pwd)"

# Function to safely copy workflows
copy_workflows() {
    echo "🔍 Looking for workflows to import..."
    
    # Check source directory
    if [ ! -d "/tmp/workflows-source" ]; then
        echo "❌ No source workflows directory found"
        return 0
    fi
    
    echo "📁 Source directory contents:"
    ls -la /tmp/workflows-source/ || echo "Cannot list source directory"
    
    # Create target directory
    mkdir -p /opt/n8n/.n8n/workflows
    chown -R node:node /opt/n8n/.n8n
    
    # Count JSON files
    JSON_COUNT=$(find /tmp/workflows-source -name "*.json" -type f 2>/dev/null | wc -l)
    echo "📦 Found $JSON_COUNT JSON files"
    
    if [ "$JSON_COUNT" -gt 0 ]; then
        echo "📥 Copying workflow files..."
        
        # Copy each JSON file
        find /tmp/workflows-source -name "*.json" -type f | while read -r workflow; do
            filename=$(basename "$workflow")
            echo "   - Copying: $filename"
            
            # Validate JSON before copying
            if jq empty "$workflow" 2>/dev/null; then
                cp "$workflow" "/opt/n8n/.n8n/workflows/" && \
                echo "     ✅ Successfully copied: $filename" || \
                echo "     ❌ Failed to copy: $filename"
            else
                echo "     ⚠️  Invalid JSON, skipping: $filename"
            fi
        done
        
        # Fix ownership
        chown -R node:node /opt/n8n/.n8n/workflows/
        
        echo "📋 Final workflow directory contents:"
        ls -la /opt/n8n/.n8n/workflows/ || echo "Cannot list target directory"
        
        echo "🎉 Workflow copy completed!"
    else
        echo "📝 No JSON workflow files found to import"
    fi
}

# Copy workflows before starting n8n
copy_workflows

echo "🎯 Starting n8n..."
echo "=================================================="

# Switch to node user and start n8n
exec gosu node n8n start "$@"
SCRIPT_END

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
