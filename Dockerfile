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

# ── Stage 2: Serve API & Web with Node.js & PostgreSQL ────────────────────────
FROM node:20-alpine

WORKDIR /app

# Copy backend package files and install dependencies
COPY server/package*.json ./
RUN npm ci --omit=dev

# Copy server code
COPY server/ ./

# Copy compiled Flutter Web assets into public/ folder
COPY --from=build /app/build/web ./public

# Railway sets $PORT dynamically at runtime
ENV PORT=8080
EXPOSE 8080

CMD ["node", "index.js"]
