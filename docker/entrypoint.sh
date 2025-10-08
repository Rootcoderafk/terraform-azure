#!/bin/sh

# NGINX Docker Entrypoint Script
# Generates SSL certificates and starts NGINX

set -e

echo "🔐 Generating SSL certificates..."

# Check if certificates already exist
if [ -f "/etc/nginx/certs/cert.pem" ] && [ -f "/etc/nginx/certs/key.pem" ]; then
    echo "✅ SSL certificates already exist"
else
    # Generate self-signed SSL certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/certs/key.pem \
        -out /etc/nginx/certs/cert.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=*.example.com" \
        -addext "subjectAltName=DNS:*.example.com,DNS:localhost,IP:127.0.0.1"
    
    echo "✅ SSL certificates generated successfully"
fi

# Set proper permissions
chmod 600 /etc/nginx/certs/key.pem
chmod 644 /etc/nginx/certs/cert.pem

# Display certificate information
echo "📋 Certificate Information:"
openssl x509 -in /etc/nginx/certs/cert.pem -noout -subject -dates

# Test NGINX configuration
echo "🔍 Testing NGINX configuration..."
nginx -t

echo "🚀 Starting NGINX..."

# Execute the main command
exec "$@"
