FROM n8nio/n8n:latest

# Switch to root to install utilities
USER root

# Install jq and bash
RUN apk add --no-cache jq bash

# Create workflow directories and fix ownership
RUN mkdir -p /opt/n8n/.n8n/workflows \
    && mkdir -p /tmp/workflows \
    && chown -R node:node /opt/n8n/.n8n \
    && chown -R node:node /tmp

# Copy workflow files to temporary location (if they exist)
COPY --chown=node:node workflows/ /tmp/workflows/ 2>/dev/null || echo "No workflows directory found"

# Create a simple startup script with better error handling
RUN echo '#!/bin/bash' > /usr/local/bin/startup.sh && \
    echo 'set -e' >> /usr/local/bin/startup.sh && \
    echo 'echo "🚀 Starting n8n startup script..."' >> /usr/local/bin/startup.sh && \
    echo 'echo "📊 Debug info:"' >> /usr/local/bin/startup.sh && \
    echo 'echo "   - User: $(whoami)"' >> /usr/local/bin/startup.sh && \
    echo 'echo "   - Working dir: $(pwd)"' >> /usr/local/bin/startup.sh && \
    echo 'echo "   - N8N_USER_FOLDER: $N8N_USER_FOLDER"' >> /usr/local/bin/startup.sh && \
    echo 'echo "   - PATH: $PATH"' >> /usr/local/bin/startup.sh && \
    echo '' >> /usr/local/bin/startup.sh && \
    echo '# Check if n8n binary exists' >> /usr/local/bin/startup.sh && \
    echo 'if [ -f "/usr/local/bin/n8n" ]; then' >> /usr/local/bin/startup.sh && \
    echo '    echo "✅ n8n binary found at /usr/local/bin/n8n"' >> /usr/local/bin/startup.sh && \
    echo 'else' >> /usr/local/bin/startup.sh && \
    echo '    echo "❌ n8n binary not found at /usr/local/bin/n8n"' >> /usr/local/bin/startup.sh && \
    echo '    echo "🔍 Searching for n8n binary..."' >> /usr/local/bin/startup.sh && \
    echo '    find / -name "n8n" -type f 2>/dev/null || echo "No n8n binary found"' >> /usr/local/bin/startup.sh && \
    echo 'fi' >> /usr/local/bin/startup.sh && \
    echo '' >> /usr/local/bin/startup.sh && \
    echo '# Create directories' >> /usr/local/bin/startup.sh && \
    echo 'echo "📁 Creating directories..."' >> /usr/local/bin/startup.sh && \
    echo 'mkdir -p /opt/n8n/.n8n/workflows || echo "Failed to create workflows dir"' >> /usr/local/bin/startup.sh && \
    echo '' >> /usr/local/bin/startup.sh && \
    echo '# Copy workflows if they exist' >> /usr/local/bin/startup.sh && \
    echo 'if [ -d "/tmp/workflows" ] && [ "$(ls -A /tmp/workflows 2>/dev/null)" ]; then' >> /usr/local/bin/startup.sh && \
    echo '    echo "📦 Copying workflow files..."' >> /usr/local/bin/startup.sh && \
    echo '    cp /tmp/workflows/*.json /opt/n8n/.n8n/workflows/ 2>/dev/null && echo "✅ Workflows copied" || echo "⚠️ Failed to copy workflows"' >> /usr/local/bin/startup.sh && \
    echo 'else' >> /usr/local/bin/startup.sh && \
    echo '    echo "📝 No workflows found to copy"' >> /usr/local/bin/startup.sh && \
    echo 'fi' >> /usr/local/bin/startup.sh && \
    echo '' >> /usr/local/bin/startup.sh && \
    echo '# Start n8n with error handling' >> /usr/local/bin/startup.sh && \
    echo 'echo "🎯 Starting n8n server..."' >> /usr/local/bin/startup.sh && \
    echo 'if [ -f "/usr/local/bin/n8n" ]; then' >> /usr/local/bin/startup.sh && \
    echo '    echo "🚀 Executing n8n start..."' >> /usr/local/bin/startup.sh && \
    echo '    exec /usr/local/bin/n8n start' >> /usr/local/bin/startup.sh && \
    echo 'else' >> /usr/local/bin/startup.sh && \
    echo '    echo "❌ Cannot start n8n - binary not found"' >> /usr/local/bin/startup.sh && \
    echo '    exit 1' >> /usr/local/bin/startup.sh && \
    echo 'fi' >> /usr/local/bin/startup.sh && \
    chmod +x /usr/local/bin/startup.sh

# Switch back to node user
USER node

# Set environment variables
ENV N8N_USER_FOLDER=/opt/n8n/.n8n
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678

# Expose port
EXPOSE 5678

# Use bash to run startup script with verbose output
CMD ["/bin/bash", "-x", "/usr/local/bin/startup.sh"]
