# ── Stage 1: Build Flutter Web ─────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS build

USER root
ENV HOME=/root
RUN git config --global --add safe.directory '*'

WORKDIR /app

# Copy pubspec and resolve dependencies for the current Dart environment
COPY pubspec.yaml ./
RUN flutter pub get

# Copy source code and compile for Web
COPY . .
RUN flutter build web --release --no-tree-shake-icons

# ── Stage 2: Serve with Nginx ───────────────────────────────────────────────────
FROM nginx:1.27-alpine

# Remove default configs
RUN rm -rf /etc/nginx/conf.d/*

# Copy nginx config with port placeholder
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy compiled Flutter Web assets
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy entrypoint that handles dynamic $PORT and ports 80/8080
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Railway sets $PORT at runtime, exposing standard HTTP ports
ENV PORT=8080
EXPOSE 80 8080

ENTRYPOINT ["/entrypoint.sh"]
