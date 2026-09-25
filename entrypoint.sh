#!/bin/sh
set -e

PORT="${PORT:-8080}"
echo "=== 📚 Starting Czytella Web Server ==="
echo "Configuring Nginx for dynamic PORT=$PORT..."

# Replace CZYTELLA_PORT placeholder in default.conf
sed -i "s/CZYTELLA_PORT/$PORT/g" /etc/nginx/conf.d/default.conf

# Also ensure Nginx listens on port 80 if PORT is not 80
if [ "$PORT" != "80" ]; then
    sed -i "/listen $PORT;/a \    listen 80;" /etc/nginx/conf.d/default.conf
fi

# Also ensure Nginx listens on port 8080 if PORT is not 8080
if [ "$PORT" != "8080" ] && [ "$PORT" != "80" ]; then
    sed -i "/listen $PORT;/a \    listen 8080;" /etc/nginx/conf.d/default.conf
fi

echo "Verifying Nginx configuration syntax..."
nginx -t

echo "=== Starting Nginx daemon on port(s) ==="
exec nginx -g "daemon off;"
