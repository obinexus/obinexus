#!/bin/bash
# Test script for GDPR processor

# Set the current directory to the script's directory
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCRIPT_DIR"

# Create logs directory if it doesn't exist
mkdir -p logs

# Generate timestamp for log file
LOG_FILE="logs/gdpr-processor-test-$(date +%Y%m%d-%H%M%S).log"

echo "Running GDPR processor test..."
echo "Log will be written to: $LOG_FILE"

# Run the processor in test mode
php "gdpr-processor.php" test > "$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    echo "Test completed successfully"
    echo "Last 10 lines of log:"
    tail -n 10 "$LOG_FILE"
else
    echo "Test failed with error code $?"
    echo "Full log:"
    cat "$LOG_FILE"
fi

# Ensure proper permissions
chmod 644 "$LOG_FILE"
