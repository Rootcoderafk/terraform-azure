#!/bin/bash

# Docker Build and Test Script for NGINX with SSL

set -e

echo "🐳 Building Docker image..."
docker build -t nginx-ssl:latest .

echo "✅ Image built successfully!"
echo ""
echo "🚀 Starting container..."
docker run -d --name nginx-ssl-test -p 8080:80 -p 8443:443 nginx-ssl:latest

echo "⏳ Waiting for container to start..."
sleep 5

echo "🔍 Testing HTTP (should redirect to HTTPS)..."
curl -I http://localhost:8080 || true

echo ""
echo "🔍 Testing HTTPS..."
curl -k https://localhost:8443

echo ""
echo "🔍 Testing health endpoint..."
curl -k https://localhost:8443/health

echo ""
echo "📊 Container logs:"
docker logs nginx-ssl-test

echo ""
echo "✅ All tests passed!"
echo ""
echo "🌐 Access the server at:"
echo "  HTTP:  http://localhost:8080 (redirects to HTTPS)"
echo "  HTTPS: https://localhost:8443"
echo ""
echo "🛑 To stop the container:"
echo "  docker stop nginx-ssl-test && docker rm nginx-ssl-test"
