# Dockerfile for NGINX with SSL Support
# Creates a containerized NGINX server with self-signed certificates

FROM nginx:alpine

# Install OpenSSL for certificate generation
RUN apk add --no-cache openssl

# Create directories for SSL certificates and configs
RUN mkdir -p /etc/nginx/certs /etc/nginx/conf.d /var/www/html

# Copy NGINX configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy web content (optional, can be overridden)
COPY index.html /var/www/html/index.html

# Expose HTTP and HTTPS ports
EXPOSE 80 443

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1

# Use custom entrypoint to generate certificates
ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
