FROM n8nio/n8n:latest

# Switch to root to create directories and install dependencies
USER root

# Install curl for health checks (if needed later)
RUN apk add --no-cache curl

# Create necessary directories for persistence
RUN mkdir -p /home/node/.n8n/workflows
RUN mkdir -p /tmp/workflows
RUN chown -R node:node /home/node/.n8n
RUN chown -R node:node /tmp

# Copy workflow files directly to n8n's workflow directory
COPY --chown=node:node workflows/ /home/node/.n8n/workflows/

# Switch back to node user for security
USER node

# Set environment variables for persistence
ENV N8N_USER_FOLDER=/home/node/.n8n
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678

# Expose port
EXPOSE 5678

# Use the default entrypoint with "start" parameter
CMD ["start"]
