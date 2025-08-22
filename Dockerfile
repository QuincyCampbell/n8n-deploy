FROM n8nio/n8n:latest

# Switch to root to create directories
USER root

# Create directories with correct permissions
RUN mkdir -p /opt/n8n/.n8n/workflows && \
    mkdir -p /tmp/workflows && \
    chown -R node:node /opt/n8n/.n8n && \
    chown -R node:node /tmp

# Copy workflow files to temporary location
COPY workflows/ /tmp/workflows/

# Create a debug startup script to find n8n
RUN echo '#!/bin/sh' > /usr/local/bin/startup.sh && \
    echo 'set -e' >> /usr/local/bin/startup.sh && \
    echo 'echo "🚀 Starting n8n debug..."' >> /usr/local/bin/startup.sh && \
    echo 'echo "User: $(whoami)"' >> /usr/local/bin/startup.sh && \
    echo 'echo "Working dir: $(pwd)"' >> /usr/local/bin/startup.sh && \
    echo 'echo "PATH: $PATH"' >> /usr/local/bin/startup.sh && \
    echo '' >> /usr/local/bin/startup.sh && \
    echo '# Find n8n binary' >> /usr/local/bin/startup.sh && \
    echo 'echo "🔍 Searching for n8n binary..."' >> /usr/local/bin/startup.sh && \
    echo 'find / -name "n8n" -type f 2>/dev/null || echo "No n8n binary found"' >> /usr/local/bin/startup.sh && \
    echo 'echo "🔍 Checking common locations..."' >> /usr/local/bin/startup.sh && \
    echo 'ls -la /usr/local/bin/ | grep n8n || echo "Not in /usr/local/bin"' >> /usr/local/bin/startup.sh && \
    echo 'ls -la /usr/bin/ | grep n8n || echo "Not in /usr/bin"' >> /usr/local/bin/startup.sh && \
    echo 'ls -la /opt/n8n/ 2>/dev/null || echo "No /opt/n8n directory"' >> /usr/local/bin/startup.sh && \
    echo 'which n8n || echo "n8n not in PATH"' >> /usr/local/bin/startup.sh && \
    echo '' >> /usr/local/bin/startup.sh && \
    echo '# Try different ways to start n8n' >> /usr/local/bin/startup.sh && \
    echo 'if command -v n8n > /dev/null 2>&1; then' >> /usr/local/bin/startup.sh && \
    echo '    echo "✅ Found n8n with command -v"' >> /usr/local/bin/startup.sh && \
    echo '    N8N_CMD="n8n"' >> /usr/local/bin/startup.sh && \
    echo 'elif [ -f "/usr/local/bin/n8n" ]; then' >> /usr/local/bin/startup.sh && \
    echo '    echo "✅ Found n8n at /usr/local/bin/n8n"' >> /usr/local/bin/startup.sh && \
    echo '    N8N_CMD="/usr/local/bin/n8n"' >> /usr/local/bin/startup.sh && \
    echo 'elif [ -f "/usr/bin/n8n" ]; then' >> /usr/local/bin/startup.sh && \
    echo '    echo "✅ Found n8n at /usr/bin/n8n"' >> /usr/local/bin/startup.sh && \
    echo '    N8N_CMD="/usr/bin/n8n"' >> /usr/local/bin/startup.sh && \
    echo 'else' >> /usr/local/bin/startup.sh && \
    echo '    echo "❌ Cannot find n8n binary"' >> /usr/local/bin/startup.sh && \
    echo '    echo "Available binaries in PATH:"' >> /usr/local/bin/startup.sh && \
    echo '    echo $PATH | tr ":" "\n" | while read dir; do [ -d "$dir" ] && ls "$dir" 2>/dev/null; done' >> /usr/local/bin/startup.sh && \
    echo '    exit 1' >> /usr/local/bin/startup.sh && \
    echo 'fi' >> /usr/local/bin/startup.sh && \
    echo '' >> /usr/local/bin/startup.sh && \
    echo '# Create directories' >> /usr/local/bin/startup.sh && \
    echo 'mkdir -p /opt/n8n/.n8n/workflows' >> /usr/local/bin/startup.sh && \
    echo '' >> /usr/local/bin/startup.sh && \
    echo '# Copy workflows if they exist' >> /usr/local/bin/startup.sh && \
    echo 'if [ -d "/tmp/workflows" ] && [ "$(ls -A /tmp/workflows 2>/dev/null || true)" ]; then' >> /usr/local/bin/startup.sh && \
    echo '    echo "📦 Copying workflow files..."' >> /usr/local/bin/startup.sh && \
    echo '    cp /tmp/workflows/*.json /opt/n8n/.n8n/workflows/ 2>/dev/null || echo "No JSON files to copy"' >> /usr/local/bin/startup.sh && \
    echo 'else' >> /usr/local/bin/startup.sh && \
    echo '    echo "📝 No workflows found"' >> /usr/local/bin/startup.sh && \
    echo 'fi' >> /usr/local/bin/startup.sh && \
    echo '' >> /usr/local/bin/startup.sh && \
    echo '# Start n8n' >> /usr/local/bin/startup.sh && \
    echo 'echo "🎯 Starting n8n with: $N8N_CMD"' >> /usr/local/bin/startup.sh && \
    echo 'exec $N8N_CMD start' >> /usr/local/bin/startup.sh && \
    chmod +x /usr/local/bin/startup.sh

# Switch back to node user
USER node

# Set environment variables
ENV N8N_USER_FOLDER=/opt/n8n/.n8n
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678

# Expose port
EXPOSE 5678

# Use /bin/sh to run the startup script
CMD ["/bin/sh", "/usr/local/bin/startup.sh"]
