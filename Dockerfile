FROM n8nio/n8n:latest

# Switch to root briefly
USER root

# Create directories
RUN mkdir -p /opt/n8n/.n8n/workflows && \
    chown -R node:node /opt/n8n/.n8n

# Switch back to node user
USER node

# Set environment variables
ENV N8N_USER_FOLDER=/opt/n8n/.n8n
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678

# Expose port
EXPOSE 5678

# Start n8n directly (no custom script)
CMD ["n8n", "start"]
