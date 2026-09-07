# Stage 1: Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy dependency definition files to leverage Docker layer caching
COPY package.json package-lock.json ./

# Install dependencies strictly using package-lock.json
RUN npm ci

# Copy application source code
COPY . .

# Build static production bundle
RUN npm run build

# Stage 2: Production serve stage
FROM nginx:1.27-alpine AS production

# Set production environment
ENV NODE_ENV=production

# Copy custom nginx configuration for SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy production build assets from builder stage
COPY --from=builder /app/build /usr/share/nginx/html

# Expose standard HTTP port
EXPOSE 80

# Health check to ensure web server is responding
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Run Nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
