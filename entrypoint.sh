#!/bin/sh
# Railway injects $PORT at runtime. We substitute it into the nginx config.
PORT="${PORT:-8080}"
echo "Starting Nginx on port $PORT..."
sed -i "s/CZYTELLA_PORT/$PORT/g" /etc/nginx/conf.d/default.conf
exec nginx -g "daemon off;"
