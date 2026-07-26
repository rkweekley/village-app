# ── Stage 1: Build Flutter web app ──
FROM ghcr.io/cirruslabs/flutter:3.27 AS build
ARG API_BASE_URL=http://localhost:8080/api
WORKDIR /app
COPY . .
RUN flutter build web --no-tree-shake-icons --dart-define=API_BASE_URL=$API_BASE_URL

# ── Stage 2: Nginx serving image ──
FROM nginx:alpine AS runtime
COPY --from=build /app/build/web /usr/share/nginx/html
COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
