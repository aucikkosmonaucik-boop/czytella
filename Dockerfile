# Multi-stage Dockerfile for Czytella Flutter Web on Railway.com / Docker

# Stage 1: Build Flutter Web application
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy pubspec and resolve dependencies
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy all project source files
COPY . .

# Build Flutter Web for production
RUN flutter build web --release

# Stage 2: Serve with lightweight Nginx
FROM nginx:alpine

# Copy custom Nginx configuration template for dynamic $PORT on Railway
COPY nginx.conf /etc/nginx/templates/default.conf.template

# Copy compiled Flutter Web assets
COPY --from=build /app/build/web /usr/share/nginx/html

# Default port (Railway automatically injects $PORT)
ENV PORT=80

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
