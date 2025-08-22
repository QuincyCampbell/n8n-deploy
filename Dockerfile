FROM n8nio/n8n:latest

# Switch to root to install utilities
USER root

# Install jq and bash (curl is already included in n8n image)
RUN apk add --no-cache jq bash

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

# Create a unified startup script that handles both import and n8n startup
RUN echo '#!/bin/bash' > /usr/local/bin/startup.sh && \
    echo 'set -e' >> /usr/local/bin/startup.sh && \
    echo '' >> /usr/local/bin/startup.sh && \
    echo 'echo "🚀 Starting n8n with workflow import..."' >> /usr/local/bin/startup.sh && \
    echo '' >> /usr/local/bin/startup.sh && \
    echo '# Run the import script first' >> /usr/local/bin/startup.sh && \
    echo 'echo "📦 Running workflow import script..."' >> /usr/local/bin/startup.sh && \
    echo 'if [ -f "/usr/local/bin/import-workflows.sh" ]; then' >> /usr/local/bin/startup.sh && \
    echo '    /usr/local/bin/import-workflows.sh || echo "⚠️ Import script completed with warnings"' >> /usr/local/bin/startup.sh && \
    echo 'else' >> /usr/local/bin/startup.sh && \
    echo '    echo "📝 No import script found"' >> /usr/local/bin/startup.sh && \
    echo 'fi' >> /usr/local/bin/startup.sh && \
    echo '' >> /usr/local/bin/startup.sh && \
    echo '# Start n8n' >> /usr/local/bin/startup.sh && \
    echo 'echo "🎯 Starting n8n server..."' >> /usr/local/bin/startup.sh && \
    echo 'exec /usr/local/bin/n8n start' >> /usr/local/bin/startup.sh && \
    chmod +x /usr/local/bin/startup.sh && \
    chown node:node /usr/local/bin/startup.sh

# Switch back to node user
USER node

# Set environment variables
ENV N8N_USER_FOLDER=/opt/n8n/.n8n
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV PATH="/usr/local/bin:$PATH"

# Expose port
EXPOSE 5678

# Use single command to avoid conflicts
CMD ["/usr/local/bin/startup.sh"]
