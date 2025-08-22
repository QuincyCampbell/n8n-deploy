#!/bin/bash

echo "🚀 N8N Workflow Import Script"

# Function to import workflows by copying files (simpler approach)
import_workflows() {
    echo "🔍 Checking for workflows to import..."
    
    if [ -d "/tmp/workflows" ]; then
        echo "📁 Found /tmp/workflows directory"
        
        # Check if there are any JSON files
        json_files=$(ls /tmp/workflows/*.json 2>/dev/null | wc -l)
        
        if [ "$json_files" -gt 0 ]; then
            echo "📦 Found $json_files workflow(s) to import..."
            
            # Copy workflow files to n8n's workflow directory
            for workflow_file in /tmp/workflows/*.json; do
                if [ -f "$workflow_file" ]; then
                    workflow_name=$(basename "$workflow_file")
                    echo "📥 Copying: $workflow_name"
                    
                    # Check if file is valid JSON
                    if ! jq empty "$workflow_file" 2>/dev/null; then
                        echo "❌ Invalid JSON format in: $workflow_name"
                        continue
                    fi
                    
                    # Copy to n8n workflows directory
                    cp "$workflow_file" "/opt/n8n/.n8n/workflows/" 2>/dev/null && \
                        echo "✅ Successfully copied: $workflow_name" || \
                        echo "❌ Failed to copy: $workflow_name"
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

# Main execution
echo "🏁 Import script starting..."
echo "📊 Environment info:"
echo "   - User: $(whoami)"
echo "   - Working dir: $(pwd)"
echo "   - N8N_USER_FOLDER: $N8N_USER_FOLDER"

# Debug information
echo "🐛 Debug: Checking workflow files..."
echo "Contents of /tmp/workflows/:"
ls -la /tmp/workflows/ 2>/dev/null || echo "Directory doesn't exist"

echo "Contents of n8n workflows directory:"
ls -la /opt/n8n/.n8n/workflows/ 2>/dev/null || echo "Directory doesn't exist"

# Import workflows
import_workflows

echo "✨ Import script completed - n8n will start next"
