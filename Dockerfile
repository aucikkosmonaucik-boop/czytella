# ── Stage 1: Build Flutter Web ─────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release --no-tree-shake-icons

# ── Stage 2: Serve with Nginx ───────────────────────────────────────────────────
FROM nginx:1.27-alpine

# Remove default config
RUN rm /etc/nginx/conf.d/default.conf

# Copy nginx config with CZYTELLA_PORT placeholder
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy Flutter Web assets
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy entrypoint that substitutes $PORT at runtime
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Railway sets $PORT at runtime (typically 3000 or random)
ENV PORT=8080

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
