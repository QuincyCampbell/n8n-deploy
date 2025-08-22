FROM n8nio/n8n:latest

# Switch to root to create directories and install dependencies
USER root

# Install curl for health checks and bash
RUN apk add --no-cache curl bash jq

# Create necessary directories for persistence (using Render's expected paths)
RUN mkdir -p /opt/n8n/.n8n/workflows
RUN mkdir -p /tmp/workflows
RUN chown -R node:node /opt/n8n/.n8n
RUN chown -R node:node /tmp

# Copy workflow files to temporary location for import
COPY --chown=node:node workflows/ /tmp/workflows/

# Copy the import script
COPY --chown=node:node scripts/import-workflows.sh /usr/local/bin/import-workflows.sh
RUN chmod +x /usr/local/bin/import-workflows.sh

# Switch back to node user for security
USER node

# Set environment variables for persistence (matching Render's paths)
ENV N8N_USER_FOLDER=/opt/n8n/.n8n
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV PATH="/usr/local/bin:$PATH"

# Expose port
EXPOSE 5678

# Create a startup script that imports workflows and starts n8n
RUN echo '#!/bin/bash' > /home/node/start.sh && \
    echo 'set -e' >> /home/node/start.sh && \
    echo 'echo "🚀 Starting n8n deployment..."' >> /home/node/start.sh && \
    echo '' >> /home/node/start.sh && \
    echo '# Ensure n8n directory exists' >> /home/node/start.sh && \
    echo 'mkdir -p /opt/n8n/.n8n/workflows' >> /home/node/start.sh && \
    echo '' >> /home/node/start.sh && \
    echo '# Start n8n in background' >> /home/node/start.sh && \
    echo 'echo "📡 Starting n8n server..."' >> /home/node/start.sh && \
    echo '/usr/local/bin/n8n start &' >> /home/node/start.sh && \
    echo 'N8N_PID=$!' >> /home/node/start.sh && \
    echo '' >> /home/node/start.sh && \
    echo '# Wait a moment for n8n to initialize' >> /home/node/start.sh && \
    echo 'sleep 15' >> /home/node/start.sh && \
    echo '' >> /home/node/start.sh && \
    echo '# Import workflows if script exists' >> /home/node/start.sh && \
    echo 'if [ -f "/usr/local/bin/import-workflows.sh" ]; then' >> /home/node/start.sh && \
    echo '    echo "📦 Running workflow import..."' >> /home/node/start.sh && \
    echo '    /usr/local/bin/import-workflows.sh || echo "⚠️ Workflow import had issues, continuing..."' >> /home/node/start.sh && \
    echo 'else' >> /home/node/start.sh && \
    echo '    echo "📝 No import script found, skipping workflow import"' >> /home/node/start.sh && \
    echo 'fi' >> /home/node/start.sh && \
    echo '' >> /home/node/start.sh && \
    echo '# Wait for n8n process' >> /home/node/start.sh && \
    echo 'echo "✅ n8n startup complete, waiting for process..."' >> /home/node/start.sh && \
    echo 'wait $N8N_PID' >> /home/node/start.sh && \
    chmod +x /home/node/start.sh

# Use the startup script
CMD ["/home/node/start.sh"]
