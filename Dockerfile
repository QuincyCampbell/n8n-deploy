FROM n8nio/n8n:latest

# Switch to root to handle file operations
USER root

# Install bash for better shell support
RUN apk add --no-cache bash

# Create directories with correct permissions
RUN mkdir -p /opt/n8n/.n8n/workflows && \
    chown -R node:node /opt/n8n/.n8n

# Copy workflow files directly to where n8n expects them
COPY --chown=node:node workflows/*.json /opt/n8n/.n8n/workflows/

# Create a simple startup script that shows what workflows are available
RUN echo '#!/bin/bash' > /usr/local/bin/startup.sh && \
    echo 'echo "🚀 Starting n8n with workflows..."' >> /usr/local/bin/startup.sh && \
    echo 'echo "📦 Available workflows:"' >> /usr/local/bin/startup.sh && \
    echo 'ls -la /opt/n8n/.n8n/workflows/ || echo "No workflows directory found"' >> /usr/local/bin/startup.sh && \
    echo 'echo "🎯 Starting n8n..."' >> /usr/local/bin/startup.sh && \
    echo 'exec n8n start "$@"' >> /usr/local/bin/startup.sh && \
    chmod +x /usr/local/bin/startup.sh

# Switch back to node user
USER node

# Set environment variables
ENV N8N_USER_FOLDER=/opt/n8n/.n8n
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV N8N_RUNNERS_ENABLED=true

# Expose port
EXPOSE 5678

# Use the startup script
CMD ["/usr/local/bin/startup.sh"]
