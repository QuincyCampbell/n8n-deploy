FROM n8nio/n8n:latest

# Switch to root to create directories and install dependencies
USER root

# Install curl and jq for the import script
RUN apk add --no-cache curl jq

# Create necessary directories for persistence
RUN mkdir -p /home/node/.n8n/workflows
RUN mkdir -p /home/node/.n8n/backups
RUN mkdir -p /tmp/workflows
RUN chown -R node:node /home/node/.n8n
RUN chown -R node:node /tmp

# Copy workflows to temporary location (if they exist)
COPY --chown=node:node workflows/ /tmp/workflows/

# Copy and setup the import script
COPY --chown=node:node scripts/import-workflows.sh /home/node/import-workflows.sh
RUN chmod +x /home/node/import-workflows.sh

# Switch back to node user for security
USER node

# Set environment variables for persistence
ENV N8N_USER_FOLDER=/home/node/.n8n
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678

# Expose port
EXPOSE 5678

# Fixed startup command - use bash instead of sh, and proper syntax
CMD ["/bin/bash", "-c", "/home/node/import-workflows.sh & n8n start"]
