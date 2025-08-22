#!/bin/bash

echo "🚀 Starting N8N with workflow auto-import..."

# Function to wait for n8n to be ready
wait_for_n8n() {
    echo "⏳ Waiting for n8n to be ready..."
    local max_attempts=60
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        # Check if n8n is responding
        if curl -s --max-time 5 http://localhost:5678/healthz > /dev/null 2>&1; then
            echo "✅ n8n is ready after $attempt attempts!"
            return 0
        fi
        
        # Also try the main endpoint as backup
        if curl -s --max-time 5 http://localhost:5678/ > /dev/null 2>&1; then
            echo "✅ n8n is ready (main endpoint) after $attempt attempts!"
            return 0
        fi
        
        echo "⏳ Waiting for n8n... ($attempt/$max_attempts)"
        sleep 3
        attempt=$((attempt + 1))
    done
    
    echo "❌ n8n failed to start within $((max_attempts * 3)) seconds"
    return 1
}

# Function to import workflows via API
import_workflows() {
    echo "🔍 Checking for workflows to import..."
    
    if [ -d "/tmp/workflows" ]; then
        echo "📁 Found /tmp/workflows directory"
        
        # Check if there are any JSON files
        json_files=$(ls /tmp/workflows/*.json 2>/dev/null | wc -l)
        
        if [ "$json_files" -gt 0 ]; then
            echo "📦 Found $json_files workflow(s) to import..."
            
            for workflow_file in /tmp/workflows/*.json; do
                if [ -f "$workflow_file" ]; then
                    workflow_name=$(basename "$workflow_file" .json)
                    echo "📥 Attempting to import: $workflow_name"
                    
                    # Check if file is valid JSON
                    if ! jq empty "$workflow_file" 2>/dev/null; then
                        echo "❌ Invalid JSON format in: $workflow_name"
                        continue
                    fi
                    
                    # Import via n8n API with proper error handling
                    response=$(curl -s -w "HTTP_CODE:%{http_code}" \
                        -X POST \
                        -H "Content-Type: application/json" \
                        --max-time 30 \
                        -d @"$workflow_file" \
                        "http://localhost:5678/rest/workflows" 2>/dev/null)
                    
                    http_code=$(echo "$response" | sed -n 's/.*HTTP_CODE:\([0-9]*\)$/\1/p')
                    
                    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
                        echo "✅ Successfully imported: $workflow_name"
                    else
                        echo "❌ Failed to import: $workflow_name (HTTP: $http_code)"
                        
                        # Try alternative import method
                        echo "🔄 Trying alternative import method..."
                        cp "$workflow_file" "/home/node/.n8n/" 2>/dev/null && \
                        echo "📋 Copied $workflow_name to n8n directory as fallback"
                    fi
                    
                    # Small delay between imports
                    sleep 1
                fi
            done
            
            echo "🎉 Workflow import process completed!"
        else
            echo "📝 No JSON workflow files found in /tmp/workflows/"
        fi
    else
        echo "📝 No /tmp/workflows directory found - no workflows to import"
    fi
}

# Function to list available workflows for debugging
debug_workflows() {
    echo "🐛 Debug: Checking workflow files..."
    echo "Contents of /tmp/workflows/:"
    ls -la /tmp/workflows/ 2>/dev/null || echo "Directory doesn't exist"
    
    echo "Contents of current directory:"
    ls -la . 2>/dev/null
}

# Main execution starts here
echo "🏁 Import script starting..."
echo "📊 Environment info:"
echo "   - User: $(whoami)"
echo "   - Working dir: $(pwd)"
echo "   - N8N_PORT: $N8N_PORT"
echo "   - N8N_HOST: $N8N_HOST"

# Debug information
debug_workflows

# Give n8n a moment to start (it's started by Docker CMD after this script)
echo "⏱️  Giving n8n time to initialize..."
sleep 10

# Wait for n8n to be ready
if wait_for_n8n; then
    echo "🎯 n8n is ready, starting workflow import..."
    sleep 2  # Give n8n a moment to fully initialize
    import_workflows
else
    echo "❌ Could not connect to n8n for workflow import"
    echo "🔍 Checking if n8n process is running..."
    ps aux | grep n8n || echo "No n8n process found"
fi

echo "✨ Import script completed"
