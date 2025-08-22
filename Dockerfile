FROM n8nio/n8n:latest

# Switch to root to install utilities
USER root

# Install jq (curl is already included in n8n image)
RUN apk add --no-cache jq

# Create workflow directories and fix ownership
RUN mkdir -p /opt/n8n/.n8n/workflows \
    && mkdir -p /tmp/workflows \
    && chown -R node:node /opt/n8n/.n8n \
    && chown -R node:node /tmp

# Copy workflow files to temporary location
COPY --chown=node:node workflows/ /tmp/workflows/

# Copy import script and make it executable
COPY --chown=node:node scripts/import-workflows.sh /usr/local/bin/import-workflows.sh
RUN chmod +x /usr/local/bin/import-workflows.sh

# Switch back to node user
USER node

# Set environment variables
ENV N8N_USER_FOLDER=/opt/n8n/.n8n
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV PATH="/usr/local/bin:$PATH"

# Expose port
EXPOSE 5678

# Run import script first, then start n8n
ENTRYPOINT ["/usr/local/bin/import-workflows.sh"]
CMD ["n8n", "start"]
