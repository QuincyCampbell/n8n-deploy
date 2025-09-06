FROM n8nio/n8n:latest

# Switch to root for setup
USER root

# Install required packages
RUN apk add --no-cache bash gosu

# Create necessary directories with proper ownership
RUN mkdir -p /home/node/.n8n && \
    chown -R node:node /home/node/.n8n

# Simple entrypoint that loads secrets and starts n8n
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'echo "Starting n8n with secret file support..."' >> /start.sh && \
    echo 'if [ -f "/etc/secrets/n8n-secrets.env" ]; then' >> /start.sh && \
    echo '    echo "Loading secrets..."' >> /start.sh && \
    echo '    source /etc/secrets/n8n-secrets.env' >> /start.sh && \
    echo '    echo "Secrets loaded successfully"' >> /start.sh && \
    echo 'fi' >> /start.sh && \
    echo 'echo "Starting n8n server..."' >> /start.sh && \
    echo 'exec gosu node n8n start' >> /start.sh && \
    chmod +x /start.sh

# Switch back to node user  
USER node

WORKDIR /home/node

ENTRYPOINT ["/start.sh"]
