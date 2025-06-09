#!/bin/bash

# Set default JVM memory options if not provided
export JAVA_OPTS=${JAVA_OPTS:-"-Xms512m -Xmx2g"}

# Find the jar file in workspace (assumes single jar or use S3_OBJECT name)
if [[ -n "$S3_OBJECT" && -f "/workspace/$S3_OBJECT" ]]; then
    JAR_FILE="/workspace/$S3_OBJECT"
elif [[ -f "/workspace/app.jar" ]]; then
    JAR_FILE="/workspace/app.jar"
else
    # Find first jar file in workspace
    JAR_FILE=$(find /workspace -name "*.jar" -type f | head -n 1)
fi

if [[ -z "$JAR_FILE" || ! -f "$JAR_FILE" ]]; then
    echo "Error: No jar file found in /workspace"
    echo "Available files:"
    ls -la /workspace/
    exit 1
fi

echo "Starting application: $JAR_FILE"
echo "Java options: $JAVA_OPTS"

# Add properties file if mounted
PROPS_ARG=""
if [[ -f "/workspace/application.properties" ]]; then
    PROPS_ARG="--spring.config.location=file:/workspace/application.properties"
    echo "Using properties file: /workspace/application.properties"
fi

# Run the Java application
exec java $JAVA_OPTS -jar "$JAR_FILE" $PROPS_ARG "$@"
