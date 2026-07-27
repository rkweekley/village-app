# ── Build stage: Flutter web ──
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

# Copy dependency files first for layer caching
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy source and build
COPY . .
RUN flutter build web --no-tree-shake-icons --release

# ── Runtime stage: nginx ──
FROM nginx:alpine AS runtime
WORKDIR /usr/share/nginx/html

# Copy nginx config
COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf

# Copy built Flutter web files
COPY --from=build /app/build/web/ .

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
