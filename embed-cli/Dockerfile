FROM alpine:latest

WORKDIR /app

# Install required dependencies
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    coreutils

# Create cache directory
RUN mkdir -p /app/cache && chmod 777 /app/cache

# Copy application files maintaining structure
COPY bin/ /app/bin/
COPY lib/ /app/lib/

# Set permissions
RUN chmod +x /app/bin/embed-cli

# Set path to include our binary
ENV PATH="/app/bin:${PATH}"

# Default command
ENTRYPOINT ["embed-cli"]