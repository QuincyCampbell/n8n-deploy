FROM n8nio/n8n:latest

# Switch to root to create directories and install dependencies
USER root

# Install curl for health checks and bash utilities
RUN apk add --no-cache curl bash jq

# Create necessary directories for persistence (Render expects /opt/n8n/.n8n)
RUN mkdir -p /opt/n8n/.n8n/workflows \
    && mkdir -p /tmp/workflows \
    && chown -R node:node /opt/n8n/.n8n \
    && chown -R node:node /tmp

# Copy workflow files to temporary location for import
COPY --chown=node:node workflows/ /tmp/workflows/

# Copy the import script
COPY --chown=node:node scripts/import-workflows.sh /usr/local/bin/import-workflows.sh
RUN chmod +x /usr/local/bin/import-workflows.sh

# Create startup script as root, then fix ownership
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'set -e' >> /start.sh && \
    echo 'echo "🚀 Starting n8n deployment..."' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Ensure n8n directory exists' >> /start.sh && \
    echo 'mkdir -p /opt/n8n/.n8n/workflows' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start n8n in background' >> /start.sh && \
    echo 'echo "📡 Starting n8n server..."' >> /start.sh && \
    echo 'n8n start &' >> /start.sh && \
    echo 'N8N_PID=$!' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Wait a moment for n8n to initialize' >> /start.sh && \
    echo 'sleep 15' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Import workflows if script exists' >> /start.sh && \
    echo 'if [ -f "/usr/local/bin/import-workflows.sh" ]; then' >> /start.sh && \
    echo '    echo "📦 Running workflow import..."' >> /start.sh && \
    echo '    /usr/local/bin/import-workflows.sh || echo "⚠️ Workflow import had issues, continuing..."' >> /start.sh && \
    echo 'else' >> /start.sh && \
    echo '    echo "📝 No import script found, skipping workflow import"' >> /start.sh && \
    echo 'fi' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Wait for n8n process' >> /start.sh && \
    echo 'echo "✅ n8n startup complete, waiting for process..."' >> /start.sh && \
    echo 'wait $N8N_PID' >> /start.sh && \
    chmod +x /start.sh && \
    chown node:node /start.sh

# Switch back to node user for security
USER node

# Set environment variables
ENV N8N_USER_FOLDER=/opt/n8n/.n8n
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV PATH="/usr/local/bin:$PATH"

# Expose port
EXPOSE 5678

# Use the startup script with bash
CMD ["/bin/bash", "-c", "/usr/local/bin/import-workflows.sh && exec n8n start"]

