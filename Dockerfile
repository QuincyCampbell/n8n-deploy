FROM n8nio/n8n:latest

# Switch to root to handle file operations
USER root

# Install required tools
RUN apk add --no-cache jq bash

# Create directories with correct permissions
RUN mkdir -p /opt/n8n/.n8n/workflows && \
    mkdir -p /tmp/workflows && \
    chown -R node:node /opt/n8n/.n8n && \
    chown -R node:node /tmp

# Copy workflow files and import script
COPY --chown=node:node workflows/ /tmp/workflows/
COPY --chown=root:root import-workflows.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/import-workflows.sh

# Switch back to node user
USER node

# Set environment variables
ENV N8N_USER_FOLDER=/opt/n8n/.n8n
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV N8N_RUNNERS_ENABLED=true

# Expose port
EXPOSE 5678

# Use the import script then start n8n
CMD ["/bin/bash", "-c", "/usr/local/bin/import-workflows.sh && exec n8n start"]
