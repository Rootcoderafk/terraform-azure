#!/bin/bash

# Generate self-signed SSL certificate for Application Gateway
# This creates a PFX file that Azure App Gateway can use

CERT_NAME="appgw-ssl"
PASSWORD="P@ssw0rd123"

# Generate private key
openssl genrsa -out ${CERT_NAME}.key 2048

# Generate certificate signing request
openssl req -new -key ${CERT_NAME}.key -out ${CERT_NAME}.csr \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=*.example.com"

# Generate self-signed certificate
openssl x509 -req -days 365 -in ${CERT_NAME}.csr \
  -signkey ${CERT_NAME}.key -out ${CERT_NAME}.crt

# Convert to PFX format (required by Azure App Gateway)
openssl pkcs12 -export -out cert.pfx \
  -inkey ${CERT_NAME}.key -in ${CERT_NAME}.crt \
  -password pass:${PASSWORD}

# Clean up intermediate files
rm ${CERT_NAME}.key ${CERT_NAME}.csr ${CERT_NAME}.crt

echo "✅ Certificate generated: cert.pfx"
echo "   Password: ${PASSWORD}"
