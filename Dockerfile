FROM n8nio/n8n:latest

# Switch to root to create directories
USER root

# Install bash for debugging
RUN apk add --no-cache bash

# Create directories with correct permissions
RUN mkdir -p /opt/n8n/.n8n/workflows && \
    chown -R node:node /opt/n8n/.n8n

# Create a simple startup script for debugging
RUN echo '#!/bin/bash' > /usr/local/bin/startup.sh && \
    echo 'set -e' >> /usr/local/bin/startup.sh && \
    echo 'echo "🚀 Starting n8n..."' >> /usr/local/bin/startup.sh && \
    echo 'echo "📊 Debug info:"' >> /usr/local/bin/startup.sh && \
    echo 'echo "   - User: $(whoami)"' >> /usr/local/bin/startup.sh && \
    echo 'echo "   - N8N_USER_FOLDER: $N8N_USER_FOLDER"' >> /usr/local/bin/startup.sh && \
    echo 'echo "   - Node version: $(node --version)"' >> /usr/local/bin/startup.sh && \
    echo 'echo "🎯 Starting n8n server..."' >> /usr/local/bin/startup.sh && \
    echo 'exec n8n start' >> /usr/local/bin/startup.sh && \
    chmod +x /usr/local/bin/startup.sh

# Switch back to node user
USER node

# Set environment variables
ENV N8N_USER_FOLDER=/opt/n8n/.n8n
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678

# Expose port
EXPOSE 5678

# Start with debug output
CMD ["/bin/bash", "-x", "/usr/local/bin/startup.sh"]
