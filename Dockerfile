# ── Stage 1: Build Flutter Web ─────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Cache dependency resolution separately
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy full source and build
COPY . .
RUN flutter build web --release --no-tree-shake-icons

# ── Stage 2: Serve with Nginx ───────────────────────────────────────────────────
FROM nginx:1.27-alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy our template config (nginx will substitute $PORT at runtime)
COPY nginx.conf /etc/nginx/templates/default.conf.template

# Copy compiled Flutter Web output
COPY --from=build /app/build/web /usr/share/nginx/html

# Railway injects $PORT at runtime; nginx:alpine image auto-processes templates/ dir
ENV PORT=8080

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
